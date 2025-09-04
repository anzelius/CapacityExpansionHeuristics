

function create_new_node(river::Symbol, plant_name::Symbol)
    real_plant = PLANTINFO[river][findfirst(p -> p.name == plant_name, PLANTINFO[river])].nr_turbines != 0
    max_discharge = 0 
    if real_plant
        turbines_indices = findall(p -> p.name_nr[1] == plant_name, TURBINEINFO[river])
        turbines = TURBINEINFO[river][turbines_indices]
        tot_turbine_discharge = sum([turbine.maxdischarge for turbine in turbines])
        max_discharge = tot_turbine_discharge      
    end 
    return Node(plant_name, max_discharge, [], [], real_plant)
end 


function get_connection_graph(river::Symbol)
    connections = Dict{Symbol, ConnectionsGraph}()  # river, head node (hav)  

    temp_dict_nodes = Dict{Symbol, Node}() # plant name, node 
    for connection in NETWORK[river]
        plant_name = connection.name 
        node1 = get!(temp_dict_nodes, plant_name) do
            create_new_node(river, plant_name)
        end

        for upstream in connection.upstream 
            upstream_name = upstream.name 
            node2 = get!(temp_dict_nodes, upstream_name) do
                create_new_node(river, upstream_name)
            end
            push!(node1.upstream, node2.name) # if node1 has node2 as upstream, node2 has node1 as downstream
            push!(node2.downstream, node1.name) 
        end  
    end 

    connections[river] = ConnectionsGraph(temp_dict_nodes[:Hav], temp_dict_nodes) 
    
    return connections 
end