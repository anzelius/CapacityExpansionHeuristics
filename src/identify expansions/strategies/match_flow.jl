using XLSX, DataFrames

function get_flow_values(river::Symbol, method::String, scale) 
    flow_values = Dict{Symbol, Int32}() # plant : flow value 
    file_path = "$DATAFOLDER/$river/Qmetrics.xlsx"
    sheet_name = "Sheet1"  
   
    df = DataFrame(XLSX.readtable(file_path, sheet_name))

    plant_values = df[:, "Plant"]  
    read_flow_values = df[:, method] 
    for (plant, hhq) in zip(plant_values, read_flow_values)
        flow_values[Symbol(plant)] = round(hhq)  
    end 
    return flow_values
end 

function match_flow(river::Symbol, connections::ConnectionsGraph, flow_match, flow_scale) 
    flow_values = get_flow_values(river, flow_match, flow_scale)
    expansions = Dict{Symbol, Int32}()

    for (p, v) in flow_values
        if haskey(PLANT_DISCHARGES[river], p)
            if v > PLANT_DISCHARGES[river][p]
                expansions[p] = round((flow_values[p] - PLANT_DISCHARGES[river][p]) * flow_scale)
            end 
        end
    end 

    return expansions
end
