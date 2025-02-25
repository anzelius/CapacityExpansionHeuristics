include("constants.jl")
using StatsBase


function get_upgrades_iteration(all_plants)
    meanheads = collect(values(all_plants))
    sorted_values = sort(meanheads)
    sorted_values = filter(!isnan, sorted_values)
    percentile_levels = 10:10:100
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


function head_based(river_bottlenecks_all)
    all_plants = Dict{Symbol, Float64}()
    for river in rivers 
        for plant in PLANTINFO[river]
            if haskey(river_bottlenecks_all[river], plant.name)
                all_plants[plant.name] = plant.meanhead
            end 
        end 
    end 

    plant_upgrades_each_iteration = get_upgrades_iteration(all_plants)

    return plant_upgrades_each_iteration 
end 


function discharge_increase_based(river_bottlenecks_all)
    all_plants = Dict{Symbol, Float64}()
    for river in rivers 
        for (plant, discharge) in river_bottlenecks_all[river]
            all_plants[plant] = discharge 
        end 
    end 

    plant_upgrades_each_iteration = get_upgrades_iteration(all_plants)

    return plant_upgrades_each_iteration 
end 