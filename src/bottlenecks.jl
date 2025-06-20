#include("constants.jl")
include("hhq_mhq.jl")

mutable struct Node 
    name::Symbol
    discharge::Int64 
    upstream::Vector{Symbol} 
    downstream::Vector{Symbol} 
    is_real_plant::Bool 
end 

struct ConnectionsGraph
    head::Node 
    nodes::Dict{Symbol, Node}
end 

function create_new_node(plant_name, turbineinfo, TURBINE, flow_values, plant_bottleneck_value, plantinfo, use_flow_values)
    real_plant = plantinfo[plant_name].nr_turbines != 0
    max_discharge = 0 
    if real_plant
        tot_turbine_discharge = sum(turbineinfo[plant_name,j].maxdischarge for j in TURBINE[plant_name])
        if use_flow_values && !isnothing(flow_values)
            max_discharge = flow_values[plant_name] 
            if max_discharge > tot_turbine_discharge
                plant_bottleneck_value[plant_name] = get!(plant_bottleneck_value, plant_name, 0) + (max_discharge - tot_turbine_discharge)
            else 
                max_discharge = tot_turbine_discharge
            end 
        else
            max_discharge = tot_turbine_discharge
        end  
    end 
    return Node(plant_name, max_discharge, [], [], real_plant)
end 

#num_real_plants = 0
# Create graph structure of network for easier handling 
# sum all maxdischarge in all turbines for each plant to get plant max discharge 
function create_connection_graph(use_flow_values=false, method = "MHQ")
river_bottlenecks = Dict{Symbol, Dict{Symbol, Int64}}()
connections = Dict{Symbol, ConnectionsGraph}()  # river, head node (hav) 
#use_flow_values = true   
#method = "MHQ"
for river in rivers 
    plant_bottleneck_value = Dict{Symbol, Float64}() 
    plants = PLANTINFO[river] 
    turbines = TURBINEINFO[river]
    connections_temp = NETWORK[river]
    plantinfo = Dict(p.name => p for p in plants)
    turbineinfo = Dict(t.name_nr => t for t in turbines)
    PLANT = [p.name for p in plants[1:end-1]]
    realplants = [plantinfo[p].nr_turbines != 0 for p in PLANT]
    PPLANT = PLANT[realplants]
    TURBINE = Dict(plantinfo[p].nr_turbines > 0 ? p => collect(1:plantinfo[p].nr_turbines) : p => Int[] for p in PLANT)
    #global num_real_plants += length(PPLANT)

    flow_values = use_flow_values ? get_flow_values(river, method) : nothing 

    temp_dict_nodes = Dict{Symbol, Node}() # plant name, node 
    for connection in connections_temp
        plant_name = connection.name 
        node1 = get!(temp_dict_nodes, plant_name) do
            create_new_node(plant_name, turbineinfo, TURBINE, flow_values, plant_bottleneck_value, plantinfo, use_flow_values)
        end

        for upstream in connection.upstream 
            upstream_name = upstream.name 
            node2 = get!(temp_dict_nodes, upstream_name) do
                create_new_node(upstream_name, turbineinfo, TURBINE, flow_values, plant_bottleneck_value, plantinfo, use_flow_values)
            end
            push!(node1.upstream, node2.name) # if node1 has node2 as upstream, node2 has node1 as downstream
            push!(node2.downstream, node1.name) 
        end  
    end 
    river_bottlenecks[river] = plant_bottleneck_value
    connections[river] = ConnectionsGraph(temp_dict_nodes[:Hav], temp_dict_nodes) 
end 
return connections, river_bottlenecks
end 

function get_river_bottlenecks(connections, river_bottlenecks)
#(connections, river_bottlenecks) = create_connection_graph()
#river_bottlenecks = Dict{Symbol, Dict{Symbol, Int64}}()  # river : [Dict(bottleneck plant : missing_discharge), ]
# dfs in all river networks, mark all bottleneck plants for each river and their diff in discharge 
# save to global variable? save to file? make function? 
for river in rivers # [:Skellefteälven] 

    function check_detour(current_plant::Node, max_discharge_along_river::Int64)
        upstream_plant_names = current_plant.upstream
        detour_nodes = []
        for upstream_plant_name in upstream_plant_names
            upstream_plant = connections[river].nodes[upstream_plant_name] 
            for upstream_upstream_plant_name in upstream_plant.upstream
                if upstream_upstream_plant_name in upstream_plant_names
                    push!(detour_nodes, upstream_upstream_plant_name)
                    upstream_upstream_plant = connections[river].nodes[upstream_upstream_plant_name]  
                    if upstream_upstream_plant.discharge < upstream_plant.discharge
                        max_discharge_along_river -= dp_max_discharge[upstream_upstream_plant_name]
                    else
                        max_discharge_along_river -= dp_max_discharge[upstream_plant_name]
                    end
                    if !current_plant.is_real_plant
                        current_plant.discharge += max_discharge_along_river
                    end 
                end
            end
        end
        return max_discharge_along_river, detour_nodes
    end
        
    
    function children_split(current_plant::Node, max_discharge_along_river::Int64, detour_nodes::Vector{Any}) 
        children_capacity = current_plant.discharge 
        for upstream_plant_name in current_plant.upstream
            if upstream_plant_name in detour_nodes
                continue
            end 
            upstream_plant = connections[river].nodes[upstream_plant_name] 
            downstream_plants = upstream_plant.downstream  
            for downstream_plant_name in downstream_plants
                if downstream_plant_name != current_plant.name  
                    downstream_plant = connections[river].nodes[downstream_plant_name] 
                    if !downstream_plant.is_real_plant  # TODO: this only works if reservoir is listed last in order... 
                        downstream_plant.discharge += upstream_plant.discharge - current_plant.discharge     
                    end 
                    children_capacity += downstream_plant.discharge
                end 
            end  
        end
        
        if max_discharge_along_river > children_capacity
            return max_discharge_along_river  
        else
            return current_plant.discharge   
        end 
    end 

    dp_max_discharge = Dict{Symbol, Int64}()
    #plant_bottleneck_value = Dict{Symbol, Float64}() 
    function dfs(current_plant::Node) 
        if isempty(current_plant.upstream) 
            dp_max_discharge[current_plant.name] = 0
            return current_plant.discharge
        end 

        max_discharge_along_river = 0 
        for upstream_plant in current_plant.upstream
            max_d = haskey(dp_max_discharge, upstream_plant) ? dp_max_discharge[upstream_plant] : dfs(connections[river].nodes[upstream_plant])  
            max_discharge_along_river += max_d 
        end 

        if current_plant.is_real_plant 
            plant_discharge = current_plant.discharge 
            if plant_discharge < max_discharge_along_river 
                max_discharge_along_river, detour_nodes = check_detour(current_plant, max_discharge_along_river)
                if plant_discharge < max_discharge_along_river 
                    max_discharge_along_river = children_split(current_plant, max_discharge_along_river, detour_nodes)
                end 
                if plant_discharge < max_discharge_along_river 
                    river_bottlenecks[river][current_plant.name] = get!(river_bottlenecks[river], current_plant.name, 0) + (max_discharge_along_river - plant_discharge)
                end 
            else 
                max_discharge_along_river = plant_discharge
            end  
        else
            if current_plant.discharge == 0
                current_plant.discharge = max_discharge_along_river  
            else 
                max_discharge_along_river = current_plant.discharge
            end           
        end 
        dp_max_discharge[current_plant.name] = max_discharge_along_river
        return max_discharge_along_river
    end 

    dfs(connections[river].head)  
    #river_bottlenecks[river] = plant_bottleneck_value
    #println(river)
    #println("$(length(river_bottlenecks[river])) / $(length(dp_max_discharge))")
end 
return river_bottlenecks 
end 

function increase_top_plants(connections, factor)
    dp_max_discharge = Dict{Symbol, Int64}()
    river_bottlenecks = Dict() 
    for river in rivers 
        function dfs(current_plant::Node) 
            if isempty(current_plant.upstream) 
                temp = Dict()
                if current_plant.is_real_plant
                    temp[current_plant.name] = current_plant.discharge*factor - current_plant.discharge
                    current_plant.discharge *= factor 
                    dp_max_discharge[current_plant.name] = current_plant.discharge
                else
                    for downstream_plant_name in current_plant.downstream
                        if !haskey(river_bottlenecks, river) || !haskey(river_bottlenecks[river], downstream_plant_name)
                            downstream_plant = connections[river].nodes[downstream_plant_name] 
                            temp[downstream_plant_name] = downstream_plant.discharge*factor - downstream_plant.discharge 
                            downstream_plant.discharge *= factor 
                            dp_max_discharge[downstream_plant_name] = downstream_plant.discharge
                        end 
                    end 
                end
                if !haskey(river_bottlenecks, river)
                    river_bottlenecks[river] = Dict()
                end
                merge!(river_bottlenecks[river], temp)
                return current_plant.discharge
            end 

            for upstream_plant in current_plant.upstream
                haskey(dp_max_discharge, upstream_plant) ? dp_max_discharge[upstream_plant] : dfs(connections[river].nodes[upstream_plant])  
            end 
        end

        dfs(connections[river].head)  
    end 
    return connections, river_bottlenecks
end 

function print_bottleneck_stats(river_bottlenecks)
n_bottleneck_plants = sum(length(river_bottlenecks[river]) for river in rivers) 
println("Total num plants: $NUM_REAL_PLANTS")
println("Total num bottlenecks: $n_bottleneck_plants")
println("Fraction of bottlenecks: $(n_bottleneck_plants/NUM_REAL_PLANTS)")
#return river_bottlenecks
#end 
end 


