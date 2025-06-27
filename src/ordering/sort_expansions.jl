using StatsBase
using DataStructures  


function sort_based_on_head_x_discharge(expansion_lists::Vector{Dict{Symbol, Int32}})
    sorted_list = Vector{OrderedDict{Symbol, Int32}}()

    for expansion_dict in expansion_lists
        weights = Dict{Symbol, Float64}() 
        for (plant, discharge_increase) in expansion_dict
            weights[plant] = MEAN_HEADS[plant] * discharge_increase
        end

        sorted_plants = sort(collect(weights), by = x -> x[2])
        sorted_expansions = OrderedDict((k => expansion_dict[k]) for (k, _) in sorted_plants)
        push!(sorted_list, sorted_expansions)
    end 

    return sorted_list
end 
    
function sort_based_biggest_bottleneck_first(expansion_lists::Vector{Dict{Symbol, Int32}})
    sorted_list = Vector{OrderedDict{Symbol, Int32}}()

    for expansion_dict in expansion_lists
        weights = Dict{Symbol, Float64}() 
        for (plant, discharge_increase) in expansion_dict
            weights[plant] = (PLANT_DISCHARGES[plant] + discharge_increase)*discharge_increase
        end

        sorted_plants = sort(collect(weights), by = x -> x[2])
        sorted_expansions = OrderedDict((k => expansion_dict[k]) for (k, _) in sorted_plants)
        push!(sorted_list, sorted_expansions)
    end 

    return sorted_list

end 
    
function sort_based_top_plants_first(expansion_lists::Vector{Dict{Symbol, Int32}})
end 

function sort_handler(plants_to_expand::Dict{Symbol, Vector{Dict{Symbol, Int32}}}, order_metric::Symbol)
    sorted_list = Dict{Symbol, Vector{OrderedDict{Symbol, Int32}}}() 
    for (river, expansion_lists) in plants_to_expand
        for expansion_list in expansion_lists
            sorted = Vector{OrderedDict{Symbol, Int32}}()
            if order_metric == "HxD"
                sorted = sort_based_on_head_x_discharge(expansion_list)
            elseif order_metric == "dDxuD"
                sorted = sort_based_biggest_bottleneck_first(expansion_list)
            elseif order_metric == "TopFirst"
                sorted = sort_based_top_plants_first(expansion_list)
            else
                error("Invalid order metric")
            end 
            sorted_list[river] = sorted_expansions 
        end 
    end 
    
    # return a dict mapping river to vector with an ordered dict 
    return sorted_list 
end 