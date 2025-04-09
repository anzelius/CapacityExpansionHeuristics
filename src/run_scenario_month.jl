include("runs.jl")


function run_scenario_month(log_to_file=true, file_name="Bottlenecks monthly 2019", expansion_method="Bottlenecks",
    year=2019)

    if expansion_method == "Bottlenecks"
        connections, river_bottlenecks_all = create_connection_graph(false)
        river_bottlenecks_all = get_river_bottlenecks(connections, river_bottlenecks_all)
        reduce_bottlenecks_flag = true 
    elseif isnothing(expansion_method) 
        river_bottlenecks_all = nothing 
        reduce_bottlenecks_flag = false 
    else
        connections, river_bottlenecks_all = create_connection_graph(true, expansion_method) 
        reduce_bottlenecks_flag = true 
    end 

    num_new_turbines_percentile, num_turbine_upgrades_percentile, num_upgraded_plants_percentile, 
    discharge_upgrades_percentile, discharge_new_turbines_percentile, profit_percentile, 
    captured_price_percentile, top_power_percentile, power_production_percentile, 
    failed_rivers, top_power_dates = [], [], [], [], [], [], [], [], [], [], []   

    for start_month in 1:12 
        end_month = start_month
        start_year, end_year = year, year+1   
        end_month = end_month >= 10 ? end_month : "0$end_month" 
        start_month = start_month >= 10 ? start_month : "0$start_month"
        reduce_bottlenecks_flag = (start_month == 1 && reduce_bottlenecks_flag) ? true : false 
        #plants_to_upgrade = plant_upgrades[percentile]
        tot_new_turbines, tot_turbine_upgrades, tot_upgraded_plants, tot_discharge_upgrades, 
        tot_discharge_new_turbines, tot_profit, tot_captured_price, tot_top_power,
        tot_power_production = 0, 0, 0, 0, 0, 0, 0, 0, 0
        high_demand_date = "$start_year-$start_month-07T08"
        for river in rivers 
            #river_bottlenecks = Dict(river => Dict(plant => value for (plant, value) in river_bottlenecks_all[river] if plant in plants_to_upgrade)) 
            model_results = run_model_river(river, "$start_year-$start_month-01T08", "$end_year-$end_month-01T08", "Profit", "Linear", "Dagens miljövillkor", 
            save_variables=false, silent=true, high_demand_trig="price_peak", high_demand_datetime=high_demand_date, 
            end_start_constraints=true, reduce_bottlenecks=reduce_bottlenecks_flag, reduce_bottlenecks_method="new_turbines_and_increase_discharge",
            bottleneck_values=river_bottlenecks_all, file_name="$file_name ($start_month)")  

            if isnothing(model_results) 
                push!(failed_rivers, river) 
            else 
                results, params, num_new_turbines, num_turbine_upgrades, num_upgraded_plants, increased_discharge_upgrades, increased_discharge_new_turbines = model_results
                @unpack Power_production, rivermodel, Discharge = results
                @unpack date_TIME, PPLANT = params 

                pp = value.(Power_production) 
                sum_result = [sum(pp[t, :, :]) for t in date_TIME]
                #max_achieved_power = maximum(sum_result)
                top_power_date = date_TIME[argmax(sum_result)] 
                push!(top_power_dates, top_power_date)
                max_achieved_power = sum(pp[DateTime(high_demand_date), :, :])

                profit = round(objective_value(rivermodel), digits=6)
                captured_price = round(objective_value(rivermodel)*1e6/sum(value.(Power_production)), digits=6)
                power_production = round(sum(value.(Power_production))/1e6, digits=6)
                
                tot_profit += profit 
                tot_captured_price += captured_price
                tot_power_production += power_production
                tot_top_power += max_achieved_power

                tot_discharge_upgrades += increased_discharge_upgrades
                tot_discharge_new_turbines += increased_discharge_new_turbines

                tot_new_turbines += num_new_turbines
                tot_turbine_upgrades += num_turbine_upgrades
                tot_upgraded_plants += num_upgraded_plants
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
            write(io, "$expansion_method, $year\n")
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
        print_bottleneck_stats(river_bottlenecks_all)
        println(top_power_dates)
    end 

end 
run_scenario_month()