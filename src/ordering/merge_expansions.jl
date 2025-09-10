
        
function merge_expansion_strategy_Steps(plants_to_expand::Dict{Symbol, Vector{Dict{Symbol, Int32}}}) 
    # merge all dictionaries in the list for each river , note! Keep on org form 

    for (river, expansions) in plants_to_expand
        if length(expansions) < 2
            return 
        end 

        plants_to_expand[river] = [merge(+, plants_to_expand[river]...)]  
    end 
    return plants_to_expand
end

function merge_river_expansion_steps(plants_to_expand::Dict{Symbol, Vector{Dict{Symbol, Int32}}})
    # merge all rivers in the dictionary to one key called :All. note! Keep on org form 
    
    max_len = maximum(length.(values(plants_to_expand)))
    merged = [Dict{Symbol, Int32}() for _ in 1:max_len]

    for expansion_lists in values(plants_to_expand)
        for (i, expansions) in enumerate(expansion_lists)
            merge!(merged[i], expansions)  # Merge each dict at index i
        end
    end

    plants_to_expand = Dict(:All => merged) 
    return plants_to_expand
end 