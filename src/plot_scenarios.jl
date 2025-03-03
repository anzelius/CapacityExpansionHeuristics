include("constants.jl")
include("bottleneck_selection.jl")
include("bottlenecks.jl")
 
###########################
# Percentiles based on head 
###########################

# #New turbines: Any[4, 4, 3, 3, 2, 1, 0, 4, 2, 3]
#Turbine upgrades: Any[11, 9, 11, 11, 12, 7, 5, 7, 8, 9]
#Plant upgrades: Any[11, 8, 9, 9, 10, 7, 8, 8, 10, 7]
# Power production: Any[15049.504042948338, 15296.74326602566, 15496.780551595279, 15642.569688446241, 15790.818531069413, 15856.709229268203, 15899.379802668089, 15946.087423837567, 15990.955811172964, 16050.575364296245]

function plot_all_head()
    new_turbines = [4, 4, 3, 3, 2, 1, 0, 4, 2, 3] 
    new_turbines = cumsum(new_turbines) 
    turbine_upgrades = [11, 9, 11, 11, 12, 7, 5, 7, 8, 9]
    turbine_upgrades = cumsum(turbine_upgrades)
    plant_upgrades = [11, 8, 9, 9, 10, 7, 8, 8, 10, 7]
    plant_upgrades = cumsum(plant_upgrades)
    power_production = [15049.504042948338, 15296.74326602566, 15496.780551595279, 15642.569688446241, 15790.818531069413, 15856.709229268203, 15899.379802668089, 15946.087423837567, 15990.955811172964, 16050.575364296245]

    p1 = plot(new_turbines, power_production, label="New turbines", marker=:circle, 
                markersize=6, linestyle=:solid, linewidth=1, xlabel="Amount", 
                ylabel="Max power", title="Percentiles based on head") 
    plot!(turbine_upgrades, power_production, label="Turbine upgrades",  marker=:circle, 
            markersize=6, linestyle=:solid, linewidth=1) 
    plot!(plant_upgrades, power_production, label="Plant upgrades",  marker=:circle, 
            markersize=6, linestyle=:solid, linewidth=1) 


    display(p1)
    readline() 
end 

function head_vs_discharge()
    plant_upgrades_head = [11, 8, 9, 9, 10, 7, 8, 8, 10, 7]
    plant_upgrades_head = cumsum(plant_upgrades_head)
    power_production_head = [15049.504042948338, 15296.74326602566, 15496.780551595279, 15642.569688446241, 15790.818531069413, 15856.709229268203, 15899.379802668089, 15946.087423837567, 15990.955811172964, 16050.575364296245]

    plant_upgrades_discharge = [10, 9, 8, 9, 8, 6, 9, 9, 8, 11]
    plant_upgrades_discharge = cumsum(plant_upgrades_discharge)
    power_production_discharge = [15369.801981821449, 15571.879189650856, 15641.181506215116, 15758.336413563791, 15823.13820943915, 15867.442723230743, 15908.381097916088, 15950.620890848548, 16000.304130937991, 16041.009902671445]
    p1 = plot(plant_upgrades_head, power_production_head, label="Head percentiles", marker=:circle, 
                    markersize=6, linestyle=:solid, linewidth=1, xlabel="Plants upgraded", 
                    ylabel="Max power", title="Percentiles based on head and discharge") 
    plot!(plant_upgrades_discharge, power_production_discharge, label="Discharge percentiles",  marker=:circle, 
                markersize=6, linestyle=:solid, linewidth=1) 

    display(p1)
    readline()
end 

###########################
# Percentiles based on discharge increase  
###########################
# #New turbines: Any[14, 7, 2, 1, 0, 0, 2, 0, 0, 0]
# Turbine upgrades: Any[13, 8, 2, 12, 12, 8, 8, 9, 7, 11]
# Plant upgrades: Any[10, 9, 8, 9, 8, 6, 9, 9, 8, 11]
# Power production: Any[15369.801981821449, 15571.879189650856, 15641.181506215116, 15758.336413563791, 15823.13820943915, 15867.442723230743, 15908.381097916088, 15950.620890848548, 16000.304130937991, 16041.009902671445]
function power_production_vs_delta_discharge()
    power_production = [15369.801981821449, 15571.879189650856, 15641.181506215116, 15758.336413563791, 15823.13820943915, 15867.442723230743, 15908.381097916088, 15950.620890848548, 16000.304130937991, 16041.009902671445]
    connections, river_bottlenecks_all = create_connection_graph()
    river_bottlenecks_all = get_river_bottlenecks(connections, river_bottlenecks_all)
    plant_upgrades = discharge_increase_based(river_bottlenecks_all)
    discharge_increase_percentile = [] 
    for percentile in 10:10:100 
        discharge_increase = [] 
        plants_to_upgrade = plant_upgrades[percentile]
        for river in rivers 
            river_bottlenecks = Dict(river => Dict(plant => value for (plant, value) in river_bottlenecks_all[river] if plant in plants_to_upgrade)) 
            delta_discharge = sum(collect(values(river_bottlenecks[river])))
            push!(discharge_increase, delta_discharge)
            println("$percentile: $river: $plant : $delta_discharge")
        end
        push!(discharge_increase_percentile, sum(discharge_increase))
    end 
    discharge_increase_percentile = cumsum(discharge_increase_percentile)
    p1 = plot(discharge_increase_percentile, power_production, marker=:circle, 
                markersize=6, linestyle=:solid, linewidth=1, xlabel="Discharge Incrase", 
                ylabel="Max power", title="")
    display(p1)
    readline()
end 

function plot_all_discharge()
    new_turbines = [14, 7, 2, 1, 0, 0, 2, 0, 0, 0]
    new_turbines = cumsum(new_turbines) 
    turbine_upgrades = [13, 8, 2, 12, 12, 8, 8, 9, 7, 11]
    turbine_upgrades = cumsum(turbine_upgrades)
    plant_upgrades = [10, 9, 8, 9, 8, 6, 9, 9, 8, 11]
    plant_upgrades = cumsum(plant_upgrades)
    power_production = [15369.801981821449, 15571.879189650856, 15641.181506215116, 15758.336413563791, 15823.13820943915, 15867.442723230743, 15908.381097916088, 15950.620890848548, 16000.304130937991, 16041.009902671445]

    p1 = plot(new_turbines, power_production, label="New turbines", marker=:circle, 
                markersize=6, linestyle=:solid, linewidth=1, xlabel="Amount", 
                ylabel="Max power", title="Percentiles based on discharge") 
    plot!(turbine_upgrades, power_production, label="Turbine upgrades",  marker=:circle, 
            markersize=6, linestyle=:solid, linewidth=1) 
    plot!(plant_upgrades, power_production, label="Plant upgrades",  marker=:circle, 
            markersize=6, linestyle=:solid, linewidth=1) 


    display(p1)
    readline() 
end 
plot_all_discharge()