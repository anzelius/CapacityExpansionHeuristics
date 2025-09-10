import Pkg
Pkg.activate("C:/Users/TussAnzelius/.julia/environments/exjobb")
using JuMP, Gurobi, Ipopt, AxisArrays, UnPack, FileIO, Statistics,
      StatsPlots, Plots.PlotMeasures, Dates, FilePathsBase, CategoricalArrays, DataFrames, XLSX, JLD2, OrderedCollections, StatsBase, CSV
using Plots: plot, plot!


mutable struct Plant
    name::Symbol
    nr_turbines::Int                        # nr
    ncap::Union{Int, Float64}               # nameplate capacity MW
    reservoir::Union{Int, Float64}          # Mm3
    reservoirhigh::Union{Int, Float64}      # m
    reservoirlow::Union{Int, Float64}       # m
    tailrace::Union{Int, Float64}           # m
    meanhead::Union{Int, Float64}           # m
end

mutable struct Turbine
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

DATAFOLDER = begin
    env_path = get(ENV, "FORSA_DATA_PATH", nothing)
    if env_path !== nothing
        Path(env_path)
    else
        parent(parent(Path(@__DIR__)))
    end
end

## Global variables
PLANTINFO = Dict{Symbol, Vector{Plant}}()
TURBINEINFO = Dict{Symbol, Vector{Turbine}}()
NETWORK = Dict{Symbol, Vector{Connection}}()
ENVCON = Dict{Tuple{Symbol, String}, Function}()
INFLOW = Dict{Symbol, Function}()
Mm3toHE = 1/0.0036

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

mutable struct Node 
    name::Symbol
    discharge::Int64 
    upstream::Vector{Symbol} 
    downstream::Vector{Symbol} 
    is_real_plant::Bool 
end 

struct ConnectionsGraph
    head::Node 
    nodes::Dict{Symbol, Node}
end 

global NUM_REAL_PLANTS = 0 
global MEAN_HEADS = Dict{}()
global PLANT_DISCHARGES = Dict{}()
ORG_TURBINE = Dict{}()
ORG_TURBINEINFO = Dict{}()
global ORG_MAX_DISCHARGE = Dict{}()
for river in rivers 
    plants = PLANTINFO[river] 
    turbines = TURBINEINFO[river]
    connections_temp = NETWORK[river]
    plantinfo = Dict(p.name => p for p in plants)
    turbineinfo = Dict(t.name_nr => t for t in turbines)
    PLANT = [p.name for p in plants[1:end-1]]
    realplants = [plantinfo[p].nr_turbines != 0 for p in PLANT]
    PPLANT = PLANT[realplants]
    global MEAN_HEADS[river] = Dict(plant.name => plant.meanhead for plant in plants)
    TURBINE = Dict(plantinfo[p].nr_turbines > 0 ? p => collect(1:plantinfo[p].nr_turbines) : p => Int[] for p in PLANT)
    ORG_TURBINE[river] = deepcopy(TURBINE)
    ORG_TURBINEINFO[river] = deepcopy(turbines)
    global NUM_REAL_PLANTS += length(PPLANT)
    river_max_discharge = Dict{}()
    PLANT_DISCHARGES[river] = Dict{}()
    for p in PPLANT
        max_d = sum(turbineinfo[p,j].maxdischarge for j in TURBINE[p])
        global PLANT_DISCHARGES[river][p] = max_d 
        river_max_discharge[p] = max_d 
    end
    global ORG_MAX_DISCHARGE[river] = river_max_discharge
end

