import Pkg
Pkg.activate("C:/Users/tussa/.julia/environments/exjobb")

using JuMP, Gurobi, Ipopt, AxisArrays, UnPack, FileIO, Statistics,
      StatsPlots, Plots.PlotMeasures, Dates, FilePathsBase, CategoricalArrays
using Plots: plot, plot!

export runmodel

struct Plant
    name::Symbol
    nr_turbines::Int                        # nr
    ncap::Union{Int, Float64}               # nameplate capacity MW
    reservoir::Union{Int, Float64}          # Mm3
    reservoirhigh::Union{Int, Float64}      # m
    reservoirlow::Union{Int, Float64}       # m
    tailrace::Union{Int, Float64}           # m
    meanhead::Union{Int, Float64}           # m
end

struct Turbine
    name_nr::Tuple{Symbol, Int64}
    maxdischarge::Union{Int, Float64}
    meandischarge::Union{Int, Float64}
    meaneta::Float64
    etapoints::Vector{@NamedTuple{d::Float64, e::Float64}}
end

Turbine(name_nr::Tuple{Symbol, Int64}, maxdischarge::Union{Int, Float64}, meandischarge::Union{Int, Float64}, meaneta::Float64) =
    Turbine(name_nr, maxdischarge, meandischarge, meaneta, @NamedTuple{d::Float64, e::Float64}[])

mutable struct Upstream
    name::Symbol
    dischargedelay::Int         # hours
    utskovdelay::Int            # hours
    passagedelay::Int           # hours
    drybeddelay::Int            # hours
end

struct Connection
    name::Symbol
    upstream::Vector{Upstream}  # vector of upstream plants (more than one if two river branches converge upstream)
end

Connection(name, p::Upstream) =
        Connection(name, [p])

Connection(name, upstream::Upstream...) =
        Connection(name, [upstream...])


AxisArrays.AxisArray(f::Float64, axes...) = AxisArray(fill(f, length.(axes)), axes...)
macro aa(e)
    esc(:(AxisArray($e...)))
end

const DATAFOLDER = let
    env_path = get(ENV, "FORSA_DATA_PATH", nothing)
    if env_path !== nothing
        Path(env_path)
    else
        parent(Path(@__DIR__))
    end
end

## Global variables
PLANTINFO = Dict{Symbol, Vector{Plant}}()
TURBINEINFO = Dict{Symbol, Vector{Turbine}}()
NETWORK = Dict{Symbol, Vector{Connection}}()
ENVCON = Dict{Tuple{Symbol, String}, Function}()
INFLOW = Dict{Symbol, Function}()
Mm3toHE = 1/0.0036

include("opt_model.jl")
include("input.jl")
include("output.jl")
include("env_con_functions.jl")
include("helpfunctions.jl")
include("analyze.jl")
include("Q.jl")
#include("start_end_levels.jl")

rivers = []
scenarios = Dict{Symbol, Vector{String}}()

for dir_name in readdir(DATAFOLDER)
    dir_path = joinpath(DATAFOLDER, dir_name)
    scenario_path = joinpath(dir_path, "scenarios")
    if isdir(scenario_path)
        push!(rivers, Symbol(dir_name))
        valid_scenarios = []
        for scenario in readdir(scenario_path)
            env_con_file = joinpath(scenario_path, scenario, "env_con.jl")
            if isfile(env_con_file)
                push!(valid_scenarios, scenario)
            end
        end
        scenarios[Symbol(dir_name)] = valid_scenarios
    end
end

for r in rivers
    include("$DATAFOLDER/$r/plantinfo.jl")
    include("$DATAFOLDER/$r/turbineinfo.jl")
    include("$DATAFOLDER/$r/network.jl")
    for scenarios in scenarios[r]
        include("$DATAFOLDER/$r/scenarios/$scenarios/env_con.jl")
    end
end

modelversions = Dict(
    "Linear" => (main=(type=:LP, power="E taylor", e="cv segments origo"), start=(;)),
    "NonLinear" =>  (main=(type=:NLP, power="bilinear HeadE", e="ncv poly rampseg"), start=(type=:LP, power="E taylor", e="cv segments origo"))
)

# USAGE:
# river = :Luleälven, :Skellefteälven, :Umeälven, :Ångermanälven, :Indalsälven, :Ljungan, :Ljusnan, :Dalälven, :Götaälv
# start_datetime and end_datetime = "yyyy-mm-ddTHH", example: "2016-05-20T08"
# model = ["Linear", "NonLinear"]
# objective = ["Profit", "Load"]
# scenario = ["Inga miljövillkor", "Dagens miljövillkor", "X miljövillkor", "Y miljövillkor", "Z miljövillkor"]
function runmodel(river::Symbol, start_datetime::String, end_datetime::String, objective::String, model::String, scenario::String; recalc::NamedTuple=(;), save_variables=true, silent=true)

    type=modelversions[model].main.type
    power=modelversions[model].main.power
    e=modelversions[model].main.e
    start=modelversions[model].start

    start = isempty(start) ? start : (; power, e, start...) # use main power & e arguments as defaults (so no need to repeat them if identical)
    run2args = (; type, power, e)
    run1args = isempty(start) ? run2args : (type=start.type, power=start.power, e=start.e)
    recalcargs = (type=:NLP, power="bilinear HeadE", e="ncv poly rampseg", recalc...)

    @time params = read_inputdata(river, start_datetime, end_datetime, objective, model, scenario; silent)

    @time results = buildmodel(params, start_datetime, end_datetime, objective; run1args...)

    rivermodel = results.rivermodel

    println("Solving model...")

    firsttype = isempty(start) ? type : start.type
    setsolver(rivermodel, objective, (firsttype == :NLP) ? :ipopt : :gurobi)
    optimize!(rivermodel)

    status = termination_status(rivermodel)
    status != MOI.OPTIMAL && @warn "The solver did not report an optimal solution."
    println("\nSolve status: $status")

    printbasicresults(params, results; recalcargs..., recalculate=true)
    save_variables && model == "Linear" && savevariables(river, params, start_datetime, end_datetime, objective, "Linear", scenario, results, solve_time(rivermodel))
    # funkar inte.. && (status == MOI.OPTIMAL || status == "LOCALLY_SOLVED")

    if type == :LP || isempty(start)
        return status # rivermodel, params, results
    end

    println("\n\nBuilding second model (because modifying JuMP models is super slow)...")
    @time results2 = buildmodel(params, start_datetime, end_datetime, objective; run2args...)
    rivermodel2 = results2.rivermodel

    println("\nSetting variable start values to LP result...")
    vars = all_variables(rivermodel)
    vars2 = all_variables(rivermodel2)
    set_start_value.(vars2, value.(vars))
    set_start_values!(params, results, results2; run2args...)

    println("\nSolving model with start values...")
    setsolver(rivermodel2, objective, (type == :NLP) ? :ipopt : :gurobi)
    optimize!(rivermodel2)

    status = termination_status(rivermodel2)
    if type == :LP && status != MOI.OPTIMAL
        @warn "The solver did not report an optimal solution."
    end
    println("\nSolve status: $status")

    printbasicresults(params, results2; run2args..., recalculate=false)
    save_variables && savevariables(river, params, start_datetime, end_datetime, objective, "NonLinear", scenario, results2, solve_time(rivermodel2))

    return status #rivermodel2, params, results2
end


function setsolver(model, objective, solver)
    nthreads = max(4, Sys.CPU_THREADS - 2)
    if solver == :gurobi
        if objective == "Profit"
            optimizer = optimizer_with_attributes(Gurobi.Optimizer,
                "Threads" => nthreads,
                "Method" => 2,
                "Presolve" => 2,
                "PreSparsify" => 1,
                "Cuts" => 2,
                "nonconvex" => 0,
                "crossover" => 0,
                "MIPGap" => 5e-6,
                "DisplayInterval" => 1,
                "BarIterLimit" => 1e6)
            set_optimizer(model, optimizer)

        elseif objective == "Load"
            #= optimizer = optimizer_with_attributes(Gurobi.Optimizer,
                "Threads" => nthreads,
                "Method" => 2,
                "Presolve" => 2,
                "PreSparsify" => 1,
                "Cuts" => 2,
                "nonconvex" => 0,
                "crossover" => 0,
                "MIPGap" => 5e-6,
                "DisplayInterval" => 1,
                "BarIterLimit" => 1e6,
                "BarHomogeneous" => 1) =#

                optimizer = optimizer_with_attributes(Gurobi.Optimizer,
                "Threads" => nthreads,
                "FeasibilityTol" => 1e-8,           # 1e-6 if needed
                "OptimalityTol" => 1e-8,            # 1e-6 if needed
                "BarConvTol" => 1e-9,               # 1e-7 if needed
                "BarHomogeneous" => 1,     # 0 or 1         # 1: enabled
                "Crossover" => 0,                  # 0: disabled
                "Method" => 2,                     # -1: auto, 1: dual simplex, 2: barrier
                "Presolve" => 2,           # 1 or 2      # 2: aggressive
                "NumericFocus" => 1, # only increase to 2 or 3 if absolutely necessary
                "Aggregate" => 2,           # 1 or 2
                "ScaleFlag" => 3,           # 2 or 3
                )
            set_optimizer(model, optimizer)
        end

    elseif solver == :ipopt
        optimizer = optimizer_with_attributes(Ipopt.Optimizer, "max_iter" => 100000, "mu_strategy" => "adaptive")

        set_optimizer(model, optimizer)
        set_optimizer_attributes(model, "warm_start_init_point" => "yes", "warm_start_bound_push" => 1e-9, "warm_start_bound_frac" => 1e-9,
                "warm_start_slack_bound_frac" => 1e-9, "warm_start_slack_bound_push" => 1e-9, "warm_start_mult_bound_push" => 1e-9)
    else
        @error "No solver named $solver."
    end
end

#runmodel(:Skellefteälven, "2016-05-05T08", "2017-05-05T08", "Profit", "Linear", "Dagens miljövillkor", save_variables=false, silent=true)
