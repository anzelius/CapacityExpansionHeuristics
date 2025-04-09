include("constants.jl")
include("analyze.jl")

# How often is the expanded power capacity utilized? 
for p in 10:10:100 
    rundata = read_results_all_rivers("Bottlenecks 2016 percentile no peak ($p) 2016-01-01T08 to 2016-12-31T08 Profit Linear Dagens miljövillkor.jld2")
    total = 0 
    used = 0 
    date_TIME = rundata[:Dalälven].date_TIME 
    agg_power_per_hour = [sum(rundata[river].power_turbines[t, p, j] for river in rivers for p in rundata[river].PPLANT for j in rundata[river].TURBINE[p]) for t in date_TIME]
    top_power = maximum(agg_power_per_hour)
    
    lower = top_power * 0.9 
    within_margin = filter(x -> lower <= x <= top_power, agg_power_per_hour)
    count_within_margin = length(within_margin)
    println("$p: $(count_within_margin/length(agg_power_per_hour))") 
end 