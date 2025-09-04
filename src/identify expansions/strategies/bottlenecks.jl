


function reduce_bottlenecks(connections)
#(connections, river_bottlenecks) = create_connection_graph()
river_bottlenecks = Dict{Symbol, Int64}()  # river : [Dict(bottleneck plant : missing_discharge), ]
# dfs in all river networks, mark all bottleneck plants for each river and their diff in discharge 
# save to global variable? save to file? make function? 
    function check_detour(current_plant::Node, max_discharge_along_river::Int64)
        upstream_plant_names = current_plant.upstream
        detour_nodes = []
        for upstream_plant_name in upstream_plant_names
            upstream_plant = connections.nodes[upstream_plant_name] 
            for upstream_upstream_plant_name in upstream_plant.upstream
                if upstream_upstream_plant_name in upstream_plant_names
                    push!(detour_nodes, upstream_upstream_plant_name)
                    upstream_upstream_plant = connections.nodes[upstream_upstream_plant_name]  
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
            upstream_plant = connections.nodes[upstream_plant_name] 
            downstream_plants = upstream_plant.downstream  
            for downstream_plant_name in downstream_plants
                if downstream_plant_name != current_plant.name  
                    downstream_plant = connections.nodes[downstream_plant_name] 
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
            max_d = haskey(dp_max_discharge, upstream_plant) ? dp_max_discharge[upstream_plant] : dfs(connections.nodes[upstream_plant])  
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
                    river_bottlenecks[current_plant.name] = get!(river_bottlenecks, current_plant.name, 0) + (max_discharge_along_river - plant_discharge)
                    current_plant.discharge = river_bottlenecks[current_plant.name] # addition to keep connections with all performed expansions
                    # TODO: verify that connections is updated 
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

    dfs(connections.head)  
    #river_bottlenecks[river] = plant_bottleneck_value
    #println(river)
    #println("$(length(river_bottlenecks[river])) / $(length(dp_max_discharge))")
return river_bottlenecks 
end 



