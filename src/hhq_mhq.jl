
#include("FORSA.jl")
using XLSX, DataFrames

function get_flow_values(river, method="HHQ")
    flow_values = Dict{Symbol, Int64}() 
    file_path = "$DATAFOLDER/$river/Qmetrics.xlsx"
    sheet_name = "Sheet1"  
   
    df = DataFrame(XLSX.readtable(file_path, sheet_name))

    plant_values = df[:, "Plant"]  
    hhq_values = df[:, method] 
    for (plant, hhq) in zip(plant_values, hhq_values)
        flow_values[Symbol(plant)] = round(hhq) 
    end 
    return flow_values
end 
