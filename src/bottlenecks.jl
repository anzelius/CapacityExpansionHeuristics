#import Pkg
#Pkg.activate("C:/Users/tussa/.julia/environments/exjobb")
include("FORSA.jl")
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

num_real_plants = 0
# Create graph structure of network for easier handling 
# sum all maxdischarge in all turbines for each plant to get plant max discharge 
connections = Dict{Symbol, ConnectionsGraph}()  # river, head node (hav) 
for river in rivers 
    plants = PLANTINFO[river] 
    turbines = TURBINEINFO[river]
    connections_temp = NETWORK[river]
    plantinfo = Dict(p.name => p for p in plants)
    turbineinfo = Dict(t.name_nr => t for t in turbines)
    PLANT = [p.name for p in plants[1:end-1]]
    realplants = [plantinfo[p].nr_turbines != 0 for p in PLANT]
    PPLANT = PLANT[realplants]
    TURBINE = Dict(plantinfo[p].nr_turbines > 0 ? p => collect(1:plantinfo[p].nr_turbines) : p => Int[] for p in PLANT)
    global num_real_plants += length(PPLANT)

    use_flow_values = true  
    method = "HHQ"
    flow_values = use_flow_values ? get_flow_values(river, method) : nothing 

    temp_dict_nodes = Dict{Symbol, Node}() # plant name, node 
    for connection in connections_temp
        p = connection.name 
        node1 = get!(temp_dict_nodes, p) do
            real_plant = plantinfo[p].nr_turbines != 0
            max_discharge = 0 
            if real_plant
                if use_flow_values && !isnothing(flow_values)
                    max_discharge = flow_values[p] 
                else
                    max_discharge = sum(turbineinfo[p,j].maxdischarge for j in TURBINE[p])
                end  
            end 
            #max_discharge = real_plant ? sum(turbineinfo[p,j].maxdischarge for j in TURBINE[p]) : 0 
            Node(p, max_discharge, [], [], real_plant) 
        end

        for upstream in connection.upstream 
            up = upstream.name 
            node2 = get!(temp_dict_nodes, up) do
                real_plant = plantinfo[up].nr_turbines != 0
                max_discharge = 0 
                if real_plant
                    if use_flow_values && !isnothing(flow_values)
                        max_discharge = flow_values[p] 
                    else
                        max_discharge = sum(turbineinfo[p,j].maxdischarge for j in TURBINE[p])
                    end  
                end 
            end
            push!(node1.upstream, node2.name) # if node1 has node2 as upstream, node2 has node1 as downstream
            push!(node2.downstream, node1.name) 
        end  
    end 
    connections[river] = ConnectionsGraph(temp_dict_nodes[:Hav], temp_dict_nodes) 
end 


river_bottlenecks = Dict{Symbol, Dict{Symbol, Int64}}()  # river : [Dict(bottleneck plant : missing_discharge), ]
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
    plant_bottleneck_value = Dict{Symbol, Float64}() 
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
                    plant_bottleneck_value[current_plant.name] = max_discharge_along_river - plant_discharge
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
    river_bottlenecks[river] = plant_bottleneck_value
    #println(river)
    #println("$(length(river_bottlenecks[river])) / $(length(dp_max_discharge))")
end 


n_bottleneck_plants = sum(length(river_bottlenecks[river]) for river in rivers) 
println("Total num plants: $num_real_plants")
println("Total num bottlenecks: $n_bottleneck_plants")
println("Fraction of bottlenecks: $(n_bottleneck_plants/num_real_plants)")
 



