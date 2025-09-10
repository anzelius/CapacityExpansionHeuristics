include("../model/constants.jl")
include("analyze.jl")


function get_totals(file_name)
    rundata = read_results_all_rivers(file_name)
    total_profit = 0 
    total_power_production = 0 
    total_top_power = 0 

    power_list = [] 
    date_TIME = rundata[:Dalälven].date_TIME
    for t in date_TIME 
        push!(power_list, sum(rundata[river].power_turbines[t, p, j] for river in rivers for p in rundata[river].PPLANT for j in rundata[river].TURBINE[p]))         
    end
    total_top_power = maximum(power_list)
    total_power_production = sum(power_list)
    total_profit = sum(rundata[river].profit for river in rivers)

    println("Total top power: ", total_top_power)
    println("Total power production: ", total_power_production)
    println("Total profit: ", total_profit)
    return total_top_power, total_power_production, total_profit
end 


percentile_top_power = [] 
percentile_power_production = []
percentile_profit = [] 
for p in 10:10:100
    file_name = "Bottlenecks 2016 percentile no peak ($p) 2016-01-01T08 to 2016-12-31T08 Profit Linear Dagens miljövillkor.jld2"
    top_power, power_production, profit = get_totals(file_name)
    push!(percentile_top_power, top_power)
    push!(percentile_power_production, power_production)
    push!(percentile_profit, profit)
end 

println("Power: ", percentile_top_power)
println("Power production: ", percentile_power_production)
println("Profit: ", percentile_profit)