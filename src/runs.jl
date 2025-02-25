include("FORSA.jl")
include("bottlenecks.jl")
include("add_turbines.jl")
include("bottleneck_selection.jl")

function run_model(river::Symbol, start_datetime::String, end_datetime::String, 
    objective::String, model::String, scenario::String; recalc::NamedTuple=(;), 
    save_variables=true, silent=true, high_demand_trig=false, high_demand_datetime="2016-01-15T08", 
    end_start_constraints=true, reduce_bottlenecks=false, reduce_bottlenecks_method="new_turbines",
    bottleneck_values) 

    type=modelversions[model].main.type
    power=modelversions[model].main.power
    e=modelversions[model].main.e
    start=modelversions[model].start

    start = isempty(start) ? start : (; power, e, start...) # use main power & e arguments as defaults (so no need to repeat them if identical)
    run2args = (; type, power, e)
    run1args = isempty(start) ? run2args : (type=start.type, power=start.power, e=start.e)
    recalcargs = (type=:NLP, power="bilinear HeadE", e="ncv poly rampseg", recalc...)
    
    if reduce_bottlenecks
        if reduce_bottlenecks_method == "new_turbines"
            add_bottleneck_turbines(river, river_bottlenecks)
        elseif reduce_bottlenecks_method == "new_turbines_and_increase_discharge" 
            num_new_turbines, num_turbine_upgrades, num_upgraded_plants = increase_discharge_and_new_turbines(river, bottleneck_values) 
        elseif reduce_bottlenecks_method == "increase_discharge"
            increase_discharge(river, river_bottlenecks) 
        end
    end 

    @time params = read_inputdata(river, start_datetime, end_datetime, objective, model, scenario; silent)
    
    if high_demand_trig
        @unpack spot_price = params
        spot_price[DateTime(high_demand_datetime)] = 100000
    end 

    @time results = buildmodel(params, start_datetime, end_datetime, end_start_constraints, objective; run1args...)

    rivermodel = results.rivermodel

    println("Solving model...")

    firsttype = isempty(start) ? type : start.type
    setsolver(rivermodel, objective, (firsttype == :NLP) ? :ipopt : :gurobi)
    optimize!(rivermodel)

    status = termination_status(rivermodel)
    status != MOI.OPTIMAL && @warn "The solver did not report an optimal solution." 
    if status != MOI.OPTIMAL
        return nothing 
    end 
    println("\nSolve status: $status")

    printbasicresults(params, results; recalcargs..., recalculate=true)
    save_variables && model == "Linear" && savevariables(river, params, start_datetime, end_datetime, objective, "Linear", scenario, results, solve_time(rivermodel))
    # funkar inte.. && (status == MOI.OPTIMAL || status == "LOCALLY_SOLVED")

    if type == :LP || isempty(start)
        return (results, params, num_new_turbines, num_turbine_upgrades, num_upgraded_plants) #status # rivermodel, params, results
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

 
connections, river_bottlenecks_all = create_connection_graph()
river_bottlenecks_all = get_river_bottlenecks(connections, river_bottlenecks_all)
plant_upgrades = discharge_increase_based(river_bottlenecks_all)
failed_rivers = [] 
power_production_percentile = []
num_new_turbines_percentile, num_turbine_upgrades_percentile, num_upgraded_plants_percentile = [], [], [] 
for percentile in 10:10:100 
    plants_to_upgrade = plant_upgrades[percentile]
    #river_bottlenecks = Dict(k => river_bottlenecks_all[k] for k in plants_to_upgrade if haskey(river_bottlenecks_all, k))
    total_max_power_production = []
    tot_new_turbines, tot_turbine_upgrades, tot_upgraded_plants = 0, 0, 0
    for river in rivers 
        river_bottlenecks = Dict(river => Dict(plant => value for (plant, value) in river_bottlenecks_all[river] if plant in plants_to_upgrade)) 
        model_results = run_model(river, "2019-01-01T08", "2019-01-31T08", "Profit", "Linear", "Dagens miljövillkor", 
        save_variables=false, silent=true, high_demand_trig=true, high_demand_datetime="2019-01-15T15", 
        end_start_constraints=true, reduce_bottlenecks=true, reduce_bottlenecks_method="new_turbines_and_increase_discharge",
        bottleneck_values=river_bottlenecks)

        if isnothing(model_results) 
            push!(failed_rivers, river) 
        else 
            results, params, num_new_turbines, num_turbine_upgrades, num_upgraded_plants = model_results
            @unpack Power_production = results
            @unpack date_TIME = params 
            pp = value.(Power_production) 
            sum_result = [sum(pp[t, :, :]) for t in date_TIME]
            max_achieved_power_production = maximum(sum_result)
            push!(total_max_power_production, max_achieved_power_production) 

            tot_new_turbines += num_new_turbines
            tot_turbine_upgrades += num_turbine_upgrades
            tot_upgraded_plants += num_upgraded_plants
        end 
    end 

    push!(num_new_turbines_percentile, tot_new_turbines)
    push!(num_turbine_upgrades_percentile, tot_turbine_upgrades) 
    push!(num_upgraded_plants_percentile, tot_upgraded_plants)

    println("failed for $(length(failed_rivers)) river: $failed_rivers")
    println("Total max power production: $(sum(total_max_power_production))")
    push!(power_production_percentile, sum(total_max_power_production))
end 
println("#New turbines: $num_new_turbines_percentile")
println("#Turbine upgrades: $num_turbine_upgrades_percentile")
println("#Plant upgrades: $num_upgraded_plants_percentile") 
println("Power production: $power_production_percentile")

gr() 
p = plot(10:10:100, power_production_percentile)
display(p) 
readline() 