include("constants.jl")
include("analyze.jl")

rundata = read_results_all_rivers("No expansion yearly 2020 no price peak 2020-01-01T08 to 2020-12-31T08 Profit Linear Dagens miljövillkor.jld2")
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