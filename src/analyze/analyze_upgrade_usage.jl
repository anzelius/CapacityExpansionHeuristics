include("../model/constants.jl")
include("analyze.jl")

# How often are the new/upgraded turbines being used? 
for p in 10:10:100 
    rundata = read_results_all_rivers("Bottlenecks 2020 percentile no peak ($p) 2020-01-01T08 to 2020-12-31T08 Profit Linear Dagens miljövillkor.jld2")
    total = 0 
    used = 0 
    for river in rivers
        run = rundata[river]
        for t in run.date_TIME
            for p in run.PPLANT
                for j in run.TURBINE[p]
                    if haskey(ORG_TURBINEINFO[river], (p, j)) 
                        turbine = ORG_TURBINEINFO[river][(p, j)]     
                        if run.discharge[t, p, j] > turbine.maxdischarge 
                            used += 1 
                        end 

                        if run.turbineinfo[(p, j)].maxdischarge > ORG_TURBINEINFO[river][(p, j)].maxdischarge 
                            total += 1 
                        end 
                    else 
                        total += 1 
                        if run.discharge[t, p, j] > 1 
                            used += 1 
                        end 
                    end 
                end
            end
        end 
    end 
    println("$p: $(used/total)") 
end 