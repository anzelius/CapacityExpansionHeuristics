include("constants.jl")
include("bottlenecks.jl")
include("add_turbines.jl")
include("bottleneck_selection.jl")

include("output.jl")
include("input.jl")
include("opt_model.jl")
include("Q.jl")
include("env_con_functions.jl")
include("helpfunctions.jl")
include("analyze.jl")


function read_input(river, start_datetime, end_datetime, objective, model, scenario,  recalc::NamedTuple=(;), silent=true)
    type=modelversions[model].main.type
    power=modelversions[model].main.power
    e=modelversions[model].main.e
    start=modelversions[model].start

    start = isempty(start) ? start : (; power, e, start...) # use main power & e arguments as defaults (so no need to repeat them if identical)
    run2args = (; type, power, e)
    run1args = isempty(start) ? run2args : (type=start.type, power=start.power, e=start.e)
    recalcargs = (type=:NLP, power="bilinear HeadE", e="ncv poly rampseg", recalc...)

    @time params = read_inputdata(river, start_datetime, end_datetime, objective, model, scenario; silent)
    
    return params, run1args, run2args, recalcargs, start
end

function volatile_price_profile(params, scaling_factor=1.1)
    @unpack spot_price = params
    mean_val = mean(values(spot_price))
    for k in keys(spot_price)
        spot_price[k] = mean_val + scaling_factor*(spot_price[k]-mean_val)
    end 
    return params 
end 

function set_price_peak(params, high_demand_datetime)
    @unpack spot_price = params
    spot_price[DateTime(high_demand_datetime)] = 100000
    return params
end

function high_price_week(params)
    @unpack spot_price = params
    high_price = maximum(values(spot_price))
    start_date = DateTime(high_demand_datetime)
    end_date = start_date + Week(1) 
    for k in keys(spot_price)
        if start_date <= k < end_date
            spot_price[k] = high_price
        end
    end
    return params 
end 

function run_model_river(params, run1args, run2args, recalcargs, start, river::Symbol, start_datetime::String, end_datetime::String, 
    objective::String, model::String, scenario::String; recalc::NamedTuple=(;), 
    save_variables=true, silent=true, high_demand_trig=false, high_demand_datetime="2016-01-15T08", 
    end_start_constraints=true, reduce_bottlenecks=false,
    bottleneck_values, file_name="test") 

    type=modelversions[model].main.type
    power=modelversions[model].main.power
    e=modelversions[model].main.e
    start=modelversions[model].start

    start = isempty(start) ? start : (; power, e, start...) # use main power & e arguments as defaults (so no need to repeat them if identical)
    run2args = (; type, power, e)
    run1args = isempty(start) ? run2args : (type=start.type, power=start.power, e=start.e)
    recalcargs = (type=:NLP, power="bilinear HeadE", e="ncv poly rampseg", recalc...)

    num_new_turbines, num_turbine_upgrades, num_upgraded_plants, increased_discharge_upgrades, increased_discharge_new_turbines = increase_discharge_and_new_turbines(river, bottleneck_values) 
   
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


function run_all_rivers(file_name_save="No expansion yearly 2019 no price peak")
    connections, river_bottlenecks_all = create_connection_graph(true, "LHQ")  
    # to run with flow values HHQ/MHQ, remove below func. Use args in create_connection_graph. 
    #river_bottlenecks_all = get_river_bottlenecks(connections, river_bottlenecks_all)
    failed_rivers = [] 
    total_max_power_production = []
    tot_new_turbines, tot_turbine_upgrades, tot_upgraded_plants, tot_discharge_upgrades, 
    tot_discharge_new_turbines, tot_profit, tot_captured_price,
    tot_power_production = 0, 0, 0, 0, 0, 0, 0, 0
    #tot_new_turbines, tot_turbine_upgrades, tot_upgraded_plants, tot_increased_discharge = 0, 0, 0, 0

    for river in rivers
        for k in keys(river_bottlenecks_all[river])
            river_bottlenecks_all[river][k] = round(0.75*river_bottlenecks_all[river][k])
        end
        model_results = run_model_river(river, "2019-01-01T08", "2019-01-07T08", "Profit", "Linear", "Dagens miljövillkor", 
        save_variables=false, silent=true, high_demand_trig="price_peak", high_demand_datetime="2019-01-02T08", 
        end_start_constraints=false, reduce_bottlenecks=true,
        bottleneck_values=river_bottlenecks_all, file_name=file_name_save)  

        if isnothing(model_results) 
            push!(failed_rivers, river) 
        else 
            results, params, num_new_turbines, num_turbine_upgrades, num_upgraded_plants, increased_discharge_upgrades, increased_discharge_new_turbines = model_results
            @unpack Power_production, rivermodel = results
            @unpack date_TIME = params 
            pp = value.(Power_production) 
            sum_result = [sum(pp[t, :, :]) for t in date_TIME]
            
            max_achieved_power_production = maximum(sum_result)
            push!(total_max_power_production, max_achieved_power_production) 
            profit = round(objective_value(rivermodel), digits=6)
            captured_price = round(objective_value(rivermodel)*1e6/sum(value.(Power_production)), digits=6)
            power_production = round(sum(value.(Power_production))/1e6, digits=6)
            tot_new_turbines += num_new_turbines
            tot_turbine_upgrades += num_turbine_upgrades
            tot_upgraded_plants += num_upgraded_plants
            tot_discharge_upgrades += increased_discharge_upgrades
            tot_discharge_new_turbines += increased_discharge_new_turbines
            tot_profit += profit
            tot_captured_price += captured_price
            tot_power_production += power_production
            
        end  
    end 
    println("============================================= Aggregated results =============================================")
    println("failed for $(length(failed_rivers)) river: $failed_rivers")
    println("Total top power: $(sum(total_max_power_production))")
    tot_increased_discharge = tot_discharge_upgrades + tot_discharge_new_turbines
    println("#New turbines: $tot_new_turbines")
    println("#Turbine upgrades: $tot_turbine_upgrades")
    println("#Plant upgrades: $tot_upgraded_plants") 
    println("Total increased discharge: $tot_increased_discharge")
    println("Profit: $tot_profit")
    println("Captured price: $tot_captured_price")
    println("Power production: $tot_power_production")
    
    #print_bottleneck_stats(river_bottlenecks_all) 
end 
#run_all_rivers()

function run_percentiles(log_to_file=true, file_name="TestBatch5.txt", 
    expansion_method="LHQ", percentiles=10:10:100, start_date="2016-01-01T08", 
    end_date="2016-12-31T08", high_demand_method=false, high_demand_date="2016-02-07T08")

    #TODO: doublecheck markings 
    connections, river_bottlenecks_all = create_connection_graph(false)
    river_bottlenecks_all = get_river_bottlenecks(connections, river_bottlenecks_all)
    connections, top_plant_increases = increase_top_plants(connections, 2)
    river_bottlenecks_all2 = get_river_bottlenecks(connections, deepcopy(top_plant_increases))
    for river in rivers 
        for k in keys(river_bottlenecks_all2[river])
            if haskey(river_bottlenecks_all[river], k)
                river_bottlenecks_all2[river][k] -= river_bottlenecks_all[river][k]
                if river_bottlenecks_all2[river][k] == 0 
                    delete!(river_bottlenecks_all2[river], k)
                end 
            end 
            if haskey(top_plant_increases[river] , k)
                river_bottlenecks_all2[river][k] -= top_plant_increases[river][k]
                if river_bottlenecks_all2[river][k] == 0 
                    delete!(river_bottlenecks_all2[river], k)
                end 
            end 
        end 
    end 



    num_new_turbines_percentile, num_turbine_upgrades_percentile, num_upgraded_plants_percentile, 
    discharge_upgrades_percentile, discharge_new_turbines_percentile, profit_percentile, 
    captured_price_percentile, top_power_percentile, power_production_percentile, 
    failed_rivers, top_power_dates = [], [], [], [], [], [], [], [], [], [], []   

    for river in rivers
        tot_new_turbines, tot_turbine_upgrades, tot_upgraded_plants, tot_discharge_upgrades, 
        tot_discharge_new_turbines, tot_profit, tot_captured_price, tot_top_power,
        tot_power_production = [], [], [], [], [], [], [], [], []

        #TODO: better way of ordering and grouping
        plant_upgrades = sort_by_head_x_discharge(river, river_bottlenecks_all[river])
        temp1 = sort_by_head_x_discharge(river, top_plant_increases[river])
        temp2 = sort_by_head_x_discharge(river, river_bottlenecks_all2[river]) 

        merge!(plant_upgrades, temp1) 
        merge!(plant_upgrades, temp2)

        river_bottlenecks = Dict()

        params, run1args, run2args, recalcargs, start = read_input(river, start_date, end_date, "Profit", "Linear", "Dagens miljövillkor")
        
        n = length(plant_upgrades)
        batch_size = 5 
        entries = collect(plant_upgrades) 
        for i in 1:batch_size:n
            batch = entries[i:min(i + batch_size - 1, n)]
            plants_to_upgrade = Dict(batch)
            river_bottlenecks[river] = plants_to_upgrade
            
            model_results = run_model_river(params, run1args, run2args, recalcargs, start, river, start_date, end_date, "Profit", "Linear", "Dagens miljövillkor", 
            save_variables=false, silent=true, high_demand_trig=high_demand_method, high_demand_datetime=high_demand_date, 
            end_start_constraints=true, reduce_bottlenecks=true,
            bottleneck_values=river_bottlenecks, file_name="$river $file_name ($percentile)")  

            if isnothing(model_results) 
                push!(failed_rivers, river) 
            else 
                results, params, num_new_turbines, num_turbine_upgrades, num_upgraded_plants, increased_discharge_upgrades, increased_discharge_new_turbines = model_results
                @unpack Power_production, rivermodel = results
                @unpack date_TIME = params 

                pp = value.(Power_production) 
                sum_result = [sum(pp[t, :, :]) for t in date_TIME]
                max_achieved_power = maximum(sum_result)
                top_power_date = date_TIME[argmax(sum_result)] 
                push!(top_power_dates, top_power_date)

                profit = round(objective_value(rivermodel), digits=6)
                captured_price = round(objective_value(rivermodel)*1e6/sum(value.(Power_production)), digits=6)
                power_production = round(sum(value.(Power_production))/1e6, digits=6)
                

                push!(tot_profit, profit)
                push!(tot_captured_price, captured_price)
                push!(tot_power_production, power_production)
                push!(tot_top_power, max_achieved_power)
                push!(tot_discharge_upgrades, increased_discharge_upgrades)
                push!(tot_discharge_new_turbines, increased_discharge_new_turbines)
                push!(tot_new_turbines, num_new_turbines)
                push!(tot_turbine_upgrades, num_turbine_upgrades)
                push!(tot_upgraded_plants, num_upgraded_plants)
            end 
        end 

        push!(num_new_turbines_percentile, tot_new_turbines)
        push!(num_turbine_upgrades_percentile, tot_turbine_upgrades) 
        push!(num_upgraded_plants_percentile, tot_upgraded_plants)
        push!(discharge_upgrades_percentile, tot_discharge_upgrades)
        push!(discharge_new_turbines_percentile, tot_discharge_new_turbines)        
        push!(top_power_percentile, tot_top_power)
        push!(profit_percentile, tot_profit)
        push!(captured_price_percentile, tot_captured_price)
        push!(power_production_percentile, tot_power_production)
    end
                  
    if log_to_file
        open(file_name, "a") do io
            write(io, "$expansion_method, $start_date, $end_date\n")
            write(io, "Failed for $(length(failed_rivers)) river: $failed_rivers\n")
            write(io, "#New turbines: $num_new_turbines_percentile\n")
            write(io, "#Turbine upgrades: $num_turbine_upgrades_percentile\n")
            write(io, "#Plant upgrades: $num_upgraded_plants_percentile\n")
            write(io, "Discharge upgraded turbines: $discharge_upgrades_percentile\n")
            write(io, "Discharge new turbines: $discharge_new_turbines_percentile\n")
            write(io, "Top power: $top_power_percentile\n")
            write(io, "Profit: $profit_percentile\n")
            write(io, "Captured price: $captured_price_percentile\n")
            write(io, "Total power production: $power_production_percentile\n")
            write(io, "$top_power_dates\n")
        end
    else
        println("Failed for $(length(failed_rivers)) river: $failed_rivers")
        println("#New turbines: $num_new_turbines_percentile")
        println("#Turbine upgrades: $num_turbine_upgrades_percentile")
        println("#Plant upgrades: $num_upgraded_plants_percentile") 
        println("Discharge upgraded turbines: ", discharge_upgrades_percentile)
        println("Discharge new turbines: ", discharge_new_turbines_percentile)
        println("Top power: $top_power_percentile")
        println("Profit: $profit_percentile")
        println("Captured price: $captured_price_percentile")
        println("Total power production: $power_production_percentile")
        #print_bottleneck_stats(river_bottlenecks_all)
        println(top_power_dates)
    end 
end 

run_percentiles()
