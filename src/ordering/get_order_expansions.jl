include("group_expansions.jl")
include("sort_expansions.jl")
include("merge_expansions.jl")


function get_order_of_expansion(plants_to_expand::Dict{Symbol, Vector{Dict{Symbol, Int32}}}, order_metric::Symbol,
    strict_order::Bool, order_grouping::Symbol, order_basis::Symbol, settings::NamedTuple) 

    if !strict_order
        # merge all dictionaries in the list for each river , note! Keep on org form 
        # only relevant if the same plant is upgraded in steps, then each river maps to several
        # Dicts, one for each step 
        plants_to_expand = merge_expansion_strategy_Steps(plants_to_expand) 
    end 

    
    if order_basis == :aggregated 
        # merge all rivers with their identified expansions to one common list  note! Keep on org form 
        # if each expansion step should expand mutliple rivers, or only one river gets expanded stepwise at a time
        plants_to_expand = merge_river_expansion_steps(plants_to_expand)
    elseif order_basis != :river 
        error("Invalid order basis")
    end 
    
    ordered_expansions, raw_data = sort_handler(plants_to_expand, order_metric)  # ordered_expansions = Dict{Symbol, Vector{OrderedDict{Symbol, Int32}}}() 
    expansion_steps = group_handler(ordered_expansions, raw_data, order_grouping, settings)  

    return expansion_steps  # List of dicts for each expansion step, lists containing dict of plants to upgrade and by how much 
end 