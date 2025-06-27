include("constants.jl")
include("analyze.jl")


# hur mycket flöde använder varje kraftverk i jämförelse med dess installerade flödeskapacitet 
function flow_usage_one_river(path_, filename_)
    river = Symbol(split(path_, "/")[1])
    run = read_results_one_river(path_, filename_)
    installed_max_discharge = sum(map(t -> t.maxdischarge, ORG_TURBINEINFO[river]))
    new_max_discharge = sum(map(t -> t.maxdischarge, values(run.turbineinfo)))
    println("Number of plants: ", length(run.PPLANT))

    sum(run.power_turbines[t] for t in keys(run.power_turbines)) 
    power_production = [sum(run.power_turbines[t, p, j] for p in run.PPLANT for j in run.TURBINE[p]) for t in run.date_TIME]
    max_index = argmax(power_production)
    max_date = run.date_TIME[max_index] 

    discharge = [sum(run.discharge[t, p, j] for p in run.PPLANT for j in run.TURBINE[p]) for t in run.date_TIME]
    println("Used max discharge: ", discharge[max_index])
    #println(power_production[max_index])
    println("Max date: ", max_date)
    println("Total installed capacity: ", installed_max_discharge)
    println("Total capacity after expansion: ", new_max_discharge)

    x_labels = [] 
    original_plant_discharge = []
    new_plant_discharge = [] 
    used_plant_discharge = [] 
    for p in run.PPLANT 
        push!(x_labels, p)
        org_plant_dis = sum(map(t -> t.maxdischarge, filter(t -> t.name_nr[1] == p, collect(values(ORG_TURBINEINFO[river])))))
        push!(original_plant_discharge, org_plant_dis)
        new_plant_dis = sum(map(t -> t.maxdischarge, filter(t -> t.name_nr[1] == p, collect(values(run.turbineinfo)))))
        push!(new_plant_discharge, new_plant_dis)
        used_plant_dis = sum(run.discharge[max_date, p, j] for j in run.TURBINE[p])
        push!(used_plant_discharge, used_plant_dis)
    end 
    bars = [original_plant_discharge new_plant_discharge used_plant_discharge]
    barplot = groupedbar(x_labels, bars, bar_width=0.6, 
                        label=["Original" "New" "Used 2016"], legend=:topleft, xrotation=90, tickfontsize=5)
    
    return barplot, bars
end 


# hur mycket flöde använder varje kraftverk olika år 
function add_year(path_, filename_, bars_)
    river = Symbol(split(path_, "/")[1])
    run = read_results_one_river(path_, filename_)

    sum(run.power_turbines[t] for t in keys(run.power_turbines)) 
    power_production = [sum(run.power_turbines[t, p, j] for p in run.PPLANT for j in run.TURBINE[p]) for t in run.date_TIME]
    max_index = argmax(power_production)
    max_date = run.date_TIME[max_index] 

    discharge = [sum(run.discharge[t, p, j] for p in run.PPLANT for j in run.TURBINE[p]) for t in run.date_TIME]
    println("Used max discharge: ", discharge[max_index])
    #println(power_production[max_index])
    println("Max date: ", max_date)

    x_labels = [] 
    used_plant_discharge = [] 
    for p in run.PPLANT 
        push!(x_labels, p)
        used_plant_dis = sum(run.discharge[max_date, p, j] for j in run.TURBINE[p])
        push!(used_plant_discharge, used_plant_dis)
    end 
    used_plant_discharge = Float64.(used_plant_discharge) 
    bars_ = hcat(bars_, used_plant_discharge)
    barplot = groupedbar(x_labels, bars_, bar_width=0.6, 
                        label=["Original" "New" "Used 2016" "Used 2020"], legend=:topleft, xrotation=90, tickfontsize=5)
    
    return barplot 
end 


function check_turbine_flow_usage(path, filename) 
    river = Symbol(split(path, "/")[1])
    run = read_results_one_river(path, filename)
    for p in run.PPLANT, j in run.TURBINE[p]
        discharge = [run.discharge[t, p, j] for t in run.date_TIME]
        sort!(discharge) 
        plt = plot(discharge, seriestype=:scatter, title="$river: ($p , $j)")
        display(plt)
        gui(plt) 
        # :Forshuvud, 2
        # :Borgärdet, 1
    end 
end 
plotlyjs()
path = "Dalälven/scenarios/Dagens miljövillkor/results"
filename = "Bottlenecks yearly 2016 no price peak 2016-01-01T08 to 2016-12-31T08 Profit Linear Dagens miljövillkor.jld2"
check_turbine_flow_usage(path, filename)
#plt, bars = flow_usage_one_river(path, filename)
readline()

#filename = "Bottlenecks yearly 2020 no price peak 2020-01-01T08 to 2020-12-31T08 Profit Linear Dagens miljövillkor.jld2"
#plt = add_year(path, filename, bars)


