include("connection_graph.jl")
include("strategies/bottlenecks.jl")


function identify_expansions_one_river(river::Symbol, expansion_strategy::String)
    #all_expansions = Dict{Symbol, Vector{Dict{Symbol, Int32}}}() # river: [plant : missing discharge] 
    #connection_graphs = Dict{Symbol, ConnectionsGraph}()  # river : connection graph 

    connection_graph = get_connection_graph(river) 
    expansions = identify_expansions(connection_graph[river], expansion_strategy)

    return connection_graph, expansions 
end 


function identify_expansions_all_rivers(expansion_strategy::String)
    all_expansions = Dict{Symbol, Vector{Dict{Symbol, Int32}}}()
    connection_graphs = Dict{Symbol, ConnectionsGraph}()

    for river in rivers 
        connection_graph, expansions = identify_expansions_one_river(river, expansion_strategy)
        all_expansions[river] = expansions[river] 
        connection_graphs[river] = connection_graph[river] 
    end 

    return connection_graph, all_expansions
end 

# TODO: move to constant fiel 
const STRATEGY_COMBOS = Dict(
    "Bottlenecks" => ["Bottlenecks"],
    "Match flow" => ["Match flow"], 
    "New Bottlenecks" => ["Bottlenecks", "Top plants", "Bottlenecks"], 
    "Match flow Bottlenecks" => ["Match flow", "Bottlenecks"]
)

function identify_expansions(connection_graph::ConnectionsGraph, expansion_strategy::String)
    expansions = Vector{Dict{Symbol, Int32}}()

    expansion_methods = STRATEGY_COMBOS[expansion_strategy]

    for expansion_method in expansion_methods
        expansion = Dict{Symbol, Int32}()
        if expansion_method == "Bottlenecks"
            expansion = reduce_bottlenecks(connection_graph)
        elseif expansion_method == "Match flow" 
            expansion = match_flow(connection_graph, params)  
        elseif expansion_method == "Top plants"
            expansion = increase_top_plants(connection_graph, params)  
        else
            error("Invalid expansion strategy")
            return 
        end
        push!(expansions, expansion)
    end

    return expansions
end 

#TODO: rewrite 
function print_bottleneck_stats(river_bottlenecks)
    n_bottleneck_plants = sum(length(river_bottlenecks[river]) for river in rivers) 
    println("Total num plants: $NUM_REAL_PLANTS")
    println("Total num bottlenecks: $n_bottleneck_plants")
    println("Fraction of bottlenecks: $(n_bottleneck_plants/NUM_REAL_PLANTS)")
    #return river_bottlenecks
    #end 
end 
