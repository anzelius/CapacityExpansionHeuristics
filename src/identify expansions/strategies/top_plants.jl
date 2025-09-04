
function increase_top_plants(connections, factor)
    expansions = Dict{Symbol, Int64}()

    visited = Set()
    function dfs(current_plant::Node)
        if isempty(current_plant.upstream) 
            expansions[current_plant.name] = Int64((current_plant.discharge * factor) - current_plant.discharge)
            current_plant.discharge += expansions[current_plant.name] 
            push!(visited, current_plant.name)
            return
        end 

        for upstream_plant in current_plant.upstream
            if upstream_plant ∉ visited
                dfs(connections.nodes[upstream_plant])
            end
        end 
    end 

    dfs(connections.head)

    return expansions
end 