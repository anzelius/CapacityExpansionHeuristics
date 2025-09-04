using XLSX, DataFrames

function get_flow_values(river::Symbol, method::String, scale) 
    flow_values = Dict{Symbol, Int32}() # plant : flow value 
    file_path = "$DATAFOLDER/$river/Qmetrics.xlsx"
    sheet_name = "Sheet1"  
   
    df = DataFrame(XLSX.readtable(file_path, sheet_name))

    plant_values = df[:, "Plant"]  
    read_flow_values = df[:, method] 
    for (plant, hhq) in zip(plant_values, read_flow_values)
        flow_values[Symbol(plant)] = round(hhq * scale)  
    end 
    return flow_values
end 

function match_flow(river::Symbol, connections::ConnectionsGraph, flow_match, flow_scale) 
    flow_values = get_flow_values(river, flow_match, flow_scale)
    expansions = Dict{Symbol, Int32}()

    visited = Set()

    function match_capacity_flow(current_plant::Node)
        if !current_plant.is_real_plant
            return 
        end

        if haskey(flow_values, current_plant.name)
            if flow_values[current_plant.name] > current_plant.discharge
                expansions[current_plant.name] = flow_values[current_plant.name] - current_plant.discharge
            end 
        end  
    end 

    function dfs(current_plant::Node)
        if isempty(current_plant.upstream) 
            return
        end 

        for upstream_plant in current_plant.upstream
            if upstream_plant ∉ visited
                dfs(connections.nodes[upstream_plant])
            end
        end 

        match_capacity_flow(current_plant)
        push!(visited, current_plant.name)
    end 

    dfs(connections.head)

    return expansions
end