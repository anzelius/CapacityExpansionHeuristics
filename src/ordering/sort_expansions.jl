using StatsBase
using DataStructures  


function sort_based_on_head_x_discharge(river::Symbol, expansion_lists::Vector{Dict{Symbol, Int32}})
    sorted_list = Vector{OrderedDict{Symbol, Int32}}()
    raw_data = Vector{OrderedDict{Symbol, Float64}}()

    for expansion_dict in expansion_lists
        weights = Dict{Symbol, Float64}() 
        for (plant, discharge_increase) in expansion_dict
            weights[plant] = MEAN_HEADS[river == :All ? only(r for r in rivers if haskey(PLANT_DISCHARGES[r], plant)) : river][plant] * discharge_increase
        end

        sorted_plants = sort(collect(weights), by = x -> x[2])
        sorted_expansions = OrderedDict((k => expansion_dict[k]) for (k, _) in sorted_plants)
        raw = OrderedDict((k => weights[k]) for (k, _) in sorted_plants)
        push!(sorted_list, sorted_expansions)
        push!(raw_data, raw)
    end 

    return sorted_list, raw_data
end 
    
function sort_based_biggest_bottleneck_first(river::Symbol, expansion_lists::Vector{Dict{Symbol, Int32}})
    sorted_list = Vector{OrderedDict{Symbol, Int32}}()

    for expansion_dict in expansion_lists
        weights = Dict{Symbol, Float64}() 
        for (plant, discharge_increase) in expansion_dict
            weights[plant] = (MEAN_HEADS[river == :All ? only(r for r in rivers if haskey(PLANT_DISCHARGES[r], plant)) : river][plant] + discharge_increase)*discharge_increase
        end

        sorted_plants = sort(collect(weights), by = x -> x[2])
        sorted_expansions = OrderedDict((k => expansion_dict[k]) for (k, _) in sorted_plants)
        push!(sorted_list, sorted_expansions)
    end 

    return sorted_list

end 

function sort_based_top_plants_first(river::Symbol, expansion_lists::Vector{Dict{Symbol, Int32}})
end 

function sort_handler(plants_to_expand::Dict{Symbol, Vector{Dict{Symbol, Int32}}}, order_metric::Symbol)
    sorted_list = Dict{Symbol, Vector{OrderedDict{Symbol, Int32}}}() 
    sorted_raw = Dict{Symbol, Vector{OrderedDict{Symbol, Float64}}}() 
    for (river, expansion_lists) in plants_to_expand
        #for expansion_list in expansion_lists
            sorted_expansions = Vector{OrderedDict{Symbol, Int32}}()
            raw_data = Vector{OrderedDict{Symbol, Float64}}()
            if order_metric == :HxD
                sorted_expansions, raw_data = sort_based_on_head_x_discharge(river, expansion_lists)
            elseif order_metric == :dDxuD
                sorted_expansions = sort_based_biggest_bottleneck_first(river, expansion_lists)
            elseif order_metric == :TopFirst
                sorted_expansions = sort_based_top_plants_first(river, expansion_lists)
            else
                error("Invalid order metric")  
            end 
            sorted_list[river] = sorted_expansions 
            sorted_raw[river] = raw_data
        #end 
    end 
    
    # return a dict mapping river to vector with an ordered dict 
    return sorted_list, sorted_raw
end 