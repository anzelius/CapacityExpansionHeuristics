include("../model/constants.jl")
include("analyze.jl")

# What is the monthly top power? 
for p in 10:10:100 
    rundata = read_results_all_rivers("Bottlenecks 2016 percentile no peak ($p) 2016-01-01T08 to 2016-12-31T08 Profit Linear Dagens miljövillkor.jld2")
    total = 0 
    used = 0 
    date_TIME = rundata[:Dalälven].date_TIME
    monthly_dict = Dict{Int, Float64}(1 => 0.0, 2 => 0.0, 3 => 0.0, 4 => 0.0, 
                                  5 => 0.0, 6 => 0.0, 7 => 0.0, 8 => 0.0, 
                                  9 => 0.0, 10 => 0.0, 11 => 0.0, 12 => 0.0)   
    for m in 1:12
        power_month = [] 
        for t in date_TIME 
            date_parts = split(t, "-")
            second_item = date_parts[2]  
            month_as_int = parse(Int, second_item)
            if month_as_int == m 
                push!(power_month, sum(rundata[river].power_turbines[t, p, j] for river in rivers for p in rundata[river].PPLANT for j in rundata[river].TURBINE[p]))        
            end 
        end 
        monthly_dict[m] = maximum(power_month)
    end 
    month_list = [] 
    for m in 1:12
        push!(month_list, monthly_dict[m]) 
    end 
    println("$p : $month_list")
end 