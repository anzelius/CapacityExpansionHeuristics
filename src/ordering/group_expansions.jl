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

function get_percentiles(ordered_expansions::OrderedDict{Symbol, Int32}, percentile_levels)
    # get an ordered dict, shop it up to separate dicts 
    percentiles = [] 
    for p in percentile_levels
        threshold = percentile(values(ordered_expansions), 100 - p)  
        plants_in_percentile = Dict(plant => increase_discharge for (plant, increase_discharge) in ordered_expansions if increase_discharge >= threshold)
        push!(percentiles, plants_in_percentile)
    end
    return percentiles 
end 

function get_steps(ordered_expansions::OrderedDict{Symbol, Int32}, step_size)
    steps = [] 
    n = length(ordered_expansions)
    plant_list = collect(keys(ordered_expansions))
 
    for i in 1:step_size:n
        chunk = Dict()
        for j in i:min(i+step_size-1, n)
            plant = plant_list[j]
            chunk[plant] = ordered_expansions[plant]
        end
        push!(steps, chunk)
    end

    return steps
end 

function group_handler(ordered::Dict{Symbol, Vector{OrderedDict{Symbol, Int32}}}, order_grouping::Symbol, settings::NamedTuple)
    expansion_steps = Vector{Dict{Symbol, Int32}}()

    for (river, ordered_expansions) in ordered
        for ordered_expansion in ordered_expansions
            if order_grouping == :percentile
                percentiles = get_percentiles(ordered_expansion, settings.percentile) # percentiles need to be in the form of Dict(), Dict() ... 
                append!(expansion_steps, percentiles)
            elseif order_grouping == :step 
                steps = get_steps(ordered_expansion, settings.step_size)  # steps need to be in the form of Dict(), Dict() ... Dict containing all plants to upgrade for that step  
                append!(expansion_steps, steps) 
            else 
                @error("Invalid grouping setting")
            end  
        end 
    end 
    
    return expansion_steps 
end 