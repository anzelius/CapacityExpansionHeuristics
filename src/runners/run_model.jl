include("../add capacity/add_turbines.jl")
include("../model/input.jl")
include("../model/opt_model.jl")
include("../output/output.jl") 


function run_model(river, order_of_expansion, start_datetime, end_datetime, objective, model, environmental_constraints_scenario, 
    price_profile_scenario, end_start_constraints, settings, save_file_name, recalc, save_variables, silent)
    
    perform_expansions = isempty(order_of_expansion) ? (push!(order_of_expansion, Dict()); false) : true
    chosen_rivers = river == :All ? rivers : [river] 
    # TODO: list of chosen rivers 

    results_all = Dict()  # expansion_step : aggregated_model_results
    for (step, plants_to_upgrade) in enumerate(order_of_expansion) # List av dicts for each expansion step, lists containing dict of plants to upgrade and by how much 
        println("========================== $step / $(length(order_of_expansion)) ==========================")
        results_expansion_step = Dict()  # data_label : model_results  
        for r in chosen_rivers
            expansions = Dict(r => Dict(plant => value for (plant, value) in plants_to_upgrade if haskey(PLANT_DISCHARGES[r], plant))) 

            model_results = run_model_river(r, start_datetime, end_datetime, objective, model, environmental_constraints_scenario, save_variables=save_variables, 
            end_start_constraints=end_start_constraints, price_profile_scenario=price_profile_scenario, silent=silent, perform_expansions=perform_expansions,
            expansions=expansions, file_name=save_file_name, recalc=recalc) 
            
            parse_result(r, model_results, results_expansion_step)
        end
        results_expansion_step["maximum_power"] = maximum(results_expansion_step["hourly_power"])
        results_all[string(step)] = results_expansion_step
    end
    
    return results_all 
end 


function parse_result(river, model_results, results_expansion_step::Dict)

    if isnothing(model_results) 
        results_expansion_step["failed_rivers"] = push!(get!(results_expansion_step, "failed_rivers", []), river)
    else 
        results, params, num_new_turbines, num_turbine_upgrades, num_upgraded_plants, increased_discharge_upgrades, increased_discharge_new_turbines = model_results
        @unpack Power_production, rivermodel = results
        @unpack date_TIME = params 

        power_production_turbines = value.(Power_production) 

        results_expansion_step["hourly_power"] = get!(results_expansion_step, "hourly_power", [0 for _ in date_TIME]) .+ [sum(power_production_turbines[t, :, :]) for t in date_TIME]
        results_expansion_step["profit"] = get!(results_expansion_step, "profit", 0.0) + round(objective_value(rivermodel), digits=6)
        results_expansion_step["increased_discharge"] = get!(results_expansion_step, "increased_discharge", 0) + increased_discharge_upgrades + increased_discharge_new_turbines
        results_expansion_step["new_turbines"] = get!(results_expansion_step, "new_turbines", 0) + num_new_turbines
        results_expansion_step["upgraded_turbines"] = get!(results_expansion_step, "upgraded_turbines", 0) + num_turbine_upgrades
        results_expansion_step["upgraded_plants"] = get!(results_expansion_step,"upgraded_plants", 0) + num_upgraded_plants
    end
end 


function run_model_river(river::Symbol, start_datetime::String, end_datetime::String, 
    objective::String, model::String, scenario::String; recalc::NamedTuple=(;), 
    save_variables=true, silent=true, price_profile_scenario=nothing, 
    end_start_constraints=true, perform_expansions=false,
    expansions, file_name) 

    type=modelversions[model].main.type
    power=modelversions[model].main.power
    e=modelversions[model].main.e
    start=modelversions[model].start

    start = isempty(start) ? start : (; power, e, start...) # use main power & e arguments as defaults (so no need to repeat them if identical)
    run2args = (; type, power, e)
    run1args = isempty(start) ? run2args : (type=start.type, power=start.power, e=start.e)
    recalcargs = (type=:NLP, power="bilinear HeadE", e="ncv poly rampseg", recalc...)

    num_new_turbines, num_turbine_upgrades, num_upgraded_plants, increased_discharge_upgrades, increased_discharge_new_turbines = 0, 0, 0, 0, 0
    if perform_expansions
        num_new_turbines, num_turbine_upgrades, num_upgraded_plants, increased_discharge_upgrades, increased_discharge_new_turbines = increase_discharge_and_new_turbines(river, expansions) 
    end 

    @time params = read_inputdata(river, start_datetime, end_datetime, objective, model, scenario; silent)
    
    if price_profile_scenario != :none 
        @unpack spot_price = params
        mean_val = mean(values(spot_price))
        if price_profile_scenario == :volatility 
            scaling_factor = settings.price_factor
            for k in keys(spot_price)
                spot_price[k] = mean_val + scaling_factor*(spot_price[k]-mean_val)
            end
        elseif price_profile_scenario == :peak
            spot_price[DateTime(settings.peak_date)] = 100000
        end
    end 
    
    @time results = buildmodel(params, start_datetime, end_datetime, end_start_constraints, objective; run1args...)

    rivermodel = results.rivermodel

    println("Solving model...")

    firsttype = isempty(start) ? type : start.type
    setsolver(rivermodel, objective, (firsttype == :NLP) ? :ipopt : :gurobi)

    optimize!(rivermodel)

    status = termination_status(rivermodel)
    status != MOI.OPTIMAL && @warn "The solver did not report an optimal solution." 
    println("\nSolve status: $status")
    if status != MOI.OPTIMAL
        return nothing 
    end 
    
    printbasicresults(params, results; recalcargs..., recalculate=true)
    save_variables && model == "Linear" && savevariables(river, params, start_datetime, end_datetime, objective, "Linear", scenario, results, solve_time(rivermodel), file_name)
    # funkar inte.. && (status == MOI.OPTIMAL || status == "LOCALLY_SOLVED")

    if type == :LP || isempty(start)
        return (results, params, num_new_turbines, num_turbine_upgrades, num_upgraded_plants, increased_discharge_upgrades, increased_discharge_new_turbines) #status # rivermodel, params, results
    end

    println("\n\nBuilding second model (because modifying JuMP models is super slow)...")
    @time results2 = buildmodel(params, start_datetime, end_datetime, end_start_constraints, objective; run2args...)
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
    save_variables && savevariables(river, params, start_datetime, end_datetime, objective, "NonLinear", scenario, results2, solve_time(rivermodel2), file_name)

    return (results2, params, num_new_turbines, num_turbine_upgrades, num_upgraded_plants, increased_discharge_upgrades, increased_discharge_new_turbines) #status #rivermodel2, params, results2
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