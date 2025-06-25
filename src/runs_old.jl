include("runs.jl")
include("bottlenecks.jl")
include("bottleneck_selection.jl") 

function run_scenario(log_to_file=true, file_name="Bottlenecks renewable 2016 percentile no peak", expansion_method="Bottlenecks", 
    percentile_method="Head times discharge", percentiles=10:10:100, start_date="2016-01-01T08", 
    end_date="2016-12-31T08", high_demand_method="renewable", high_demand_date="2016-02-07T08")

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
        for river in rivers
            for k in keys(river_bottlenecks_all[river])
                river_bottlenecks_all[river][k] = round(0.75*river_bottlenecks_all[river][k])
            end
        end
    end 

    if percentile_method == "Discharge"
        plant_upgrades = discharge_increase_based(river_bottlenecks_all, percentiles)
    elseif isnothing(percentile_method)
        plant_upgrades[percentiles] = river_bottlenecks_all
    elseif percentile_method == "Head" 
        plant_upgrades = head_based(river_bottlenecks_all, percentiles)
    else 
        plant_upgrades = head_x_discharge_based(river_bottlenecks_all, percentiles)
    end 
    
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

    temp1 = head_x_discharge_based(top_plant_increases, 10:10:100)
    temp2 = head_x_discharge_based(river_bottlenecks_all2, 10:10:100) 
    percentiles = collect(percentiles)
    i=1 
    plant_upgrades_all = Dict() 
    for p_upg in [plant_upgrades, temp1, temp2]
        for p in 10:10:100
            plant_upgrades_all[i] = p_upg[p] 
            i+=1
        end 
    end  
    i=1 
    plant_upgrades_all = Dict() 
    for p_upg in [plant_upgrades, temp1, temp2]
        for p in 10:10:100
            plant_upgrades_all[i] = p_upg[p] 
            i+=1
        end 
    end  

    num_new_turbines_percentile, num_turbine_upgrades_percentile, num_upgraded_plants_percentile, 
    discharge_upgrades_percentile, discharge_new_turbines_percentile, profit_percentile, 
    captured_price_percentile, top_power_percentile, power_production_percentile, 
    failed_rivers, top_power_dates = [], [], [], [], [], [], [], [], [], [], []   

    for percentile in 1:1:length(plant_upgrades_all)
        plants_to_upgrade = plant_upgrades_all[percentile]
    for percentile in 1:1:length(plant_upgrades_all)
        plants_to_upgrade = plant_upgrades_all[percentile]
        tot_new_turbines, tot_turbine_upgrades, tot_upgraded_plants, tot_discharge_upgrades, 
        tot_discharge_new_turbines, tot_profit, tot_captured_price, tot_top_power,
        tot_power_production = 0, 0, 0, 0, 0, 0, 0, 0, 0
        for river in rivers 
            println("==================== $river: $percentile / $(length(plant_upgrades_all)) ============================")
            river_bottlenecks = Dict(river => Dict(plant => value for (plant, value) in river_bottlenecks_all[river] if plant in plants_to_upgrade)) 
            
            model_results = run_model_river(river, start_date, end_date, "Profit", "Linear", "Dagens miljövillkor", 
            save_variables=false, silent=true, high_demand_trig=high_demand_method, high_demand_datetime=high_demand_date, 
            end_start_constraints=true, reduce_bottlenecks=reduce_bottlenecks_flag,
            bottleneck_values=river_bottlenecks, file_name="$file_name ($percentile)")  

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
            write(io, "$expansion_method, $percentile_method, $percentiles, $start_date, $end_date, $high_demand_method, $high_demand_date\n")
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


run_scenario(true, "CORR Test old percentiles x2", "Bottlenecks", 
    "Head times discharge", 10:10:100, "2016-01-01T08", 
    "2016-12-31T08", false, "2010-02-07T08")