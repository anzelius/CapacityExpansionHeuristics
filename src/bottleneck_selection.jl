#include("constants.jl")
using StatsBase
using DataStructures  


function get_upgrades_iteration(all_plants, percentiles)
    meanheads = collect(values(all_plants))
    sorted_values = sort(meanheads)
    sorted_values = filter(!isnan, sorted_values)
    percentile_levels = percentiles
    top_percentile_groups = Dict()

    for p in percentile_levels
        threshold = percentile(sorted_values, 100 - p)  
        top_names = [name for (name, value) in all_plants if value >= threshold]  
        top_percentile_groups[p] = top_names  
    end

    plant_upgrades_each_iteration = Dict() 
    plant_temp = []
    for p in percentile_levels
        for name in top_percentile_groups[p] 
            if name ∉ plant_temp
                push!(get!(plant_upgrades_each_iteration, p, []), name)
                push!(plant_temp, name) 
            end 
        end 
        #println("Top $p%: ", length(top_percentile_groups[p]))
    end

    #for (p, names) in plant_upgrades_each_iteration
    #    println("$p: $(length(names))") 
    #end 
    return plant_upgrades_each_iteration
end


function head_based(river_bottlenecks_all, percentiles)
    all_plants = Dict{Symbol, Float64}()
    for river in rivers 
        for plant in PLANTINFO[river]
            if haskey(river_bottlenecks_all[river], plant.name)
                all_plants[plant.name] = plant.meanhead
            end 
        end 
    end 

    plant_upgrades_each_iteration = get_upgrades_iteration(all_plants, percentiles)

    return plant_upgrades_each_iteration 
end 


function discharge_increase_based(river_bottlenecks_all, percentiles)
    all_plants = Dict{Symbol, Float64}()
    for river in rivers 
        for (plant, discharge) in river_bottlenecks_all[river]
            all_plants[plant] = discharge 
        end 
    end 

    plant_upgrades_each_iteration = get_upgrades_iteration(all_plants, percentiles)

    return plant_upgrades_each_iteration 
end 

function head_x_discharge_based(river_bottlenecks_all, percentiles)
    all_plants = Dict{Symbol, Float64}()
    for river in rivers 
        for plant in PLANTINFO[river]
            if haskey(river_bottlenecks_all[river], plant.name)
                discharge = river_bottlenecks_all[river][plant.name]
                all_plants[plant.name] = plant.meanhead * discharge 
            end 
        end 
    end 
    plant_upgrades_each_iteration = get_upgrades_iteration(all_plants, percentiles)
    return plant_upgrades_each_iteration 

end 


function head_x_discharge_river(river, river_bottlenecks, percentiles)
    all_plants = Dict{Symbol, Float64}()
    for plant in PLANTINFO[river]
        if haskey(river_bottlenecks, plant.name)
            discharge = river_bottlenecks[plant.name]
            all_plants[plant.name] = plant.meanhead * discharge 
        end 
    end  
    plant_upgrades_each_iteration = get_upgrades_iteration(all_plants, percentiles)
    return plant_upgrades_each_iteration 

end 


function sort_by_head_x_discharge(river, plant_list)
    # Compute sort weights using meanhead * discharge
    weights = Dict{Symbol, Float64}()
    for plant in PLANTINFO[river]
        if haskey(plant_list, plant.name)
            weights[plant.name] = plant.meanhead * plant_list[plant.name]
        end
    end

    # Sort the keys in plant_list by computed weight
    sorted_keys = sort(collect(keys(plant_list)), by = k -> weights[k], rev = true)
    return OrderedDict(k => plant_list[k] for k in sorted_keys)
end
