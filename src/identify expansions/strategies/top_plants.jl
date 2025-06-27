
#TODO 

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