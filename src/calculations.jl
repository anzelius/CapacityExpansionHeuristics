include("FORSA.jl")
include("bottlenecks.jl") 

############################
# theoretical power calculated P_new = k * Q_new 
############################
tot_max_discharge = 0 
tot_reported_capacity = 0
for river in rivers
    plants = PLANTINFO[river] 
    turbines = TURBINEINFO[river]
    plantinfo = Dict(p.name => p for p in plants)
    turbineinfo = Dict(t.name_nr => t for t in turbines)
    PLANT = [p.name for p in plants[1:end-1]]
    realplants = [plantinfo[p].nr_turbines != 0 for p in PLANT]
    PPLANT = PLANT[realplants]
    TURBINE = Dict(plantinfo[p].nr_turbines > 0 ? p => collect(1:plantinfo[p].nr_turbines) : p => Int[] for p in PLANT)

    for p in PPLANT
        max_d = sum(turbineinfo[p,j].maxdischarge for j in TURBINE[p])
        global tot_max_discharge += max_d
    end 

    for plant in plants
        global tot_reported_capacity += isfinite(plant.ncap) ? plant.ncap : 0 
    end 
end 

k = tot_reported_capacity / tot_max_discharge
println("reported capacity (MW): $tot_reported_capacity")

tot_missing_discharge = 0 
for river in rivers 
    for (plant, missing_discharge) in river_bottlenecks[river]
        global tot_missing_discharge += isfinite(missing_discharge) ? missing_discharge : 0 
    end 
end 

new_capacity = k * (tot_max_discharge + tot_missing_discharge)
println("new theoretical capacity (MW): $new_capacity") 
println("Diff in theoretical capacity and repoted capacity: $(new_capacity - tot_reported_capacity)")

############################
# calculate how 'different' turbines installed at each plant are 
############################
numerator = 0 
mean_percent = 0 
for river in rivers
    plants = PLANTINFO[river] 
    turbines = TURBINEINFO[river]
    plantinfo = Dict(p.name => p for p in plants)
    turbineinfo = Dict(t.name_nr => t for t in turbines)
    PLANT = [p.name for p in plants[1:end-1]]
    realplants = [plantinfo[p].nr_turbines != 0 for p in PLANT]
    PPLANT = PLANT[realplants]
    TURBINE = Dict(plantinfo[p].nr_turbines > 0 ? p => collect(1:plantinfo[p].nr_turbines) : p => Int[] for p in PLANT)
    for plant_name in PPLANT
        plant_turbines = [plant_turbine for plant_turbine in TURBINEINFO[river] if plant_turbine.name_nr[1] == plant_name]
        plant_turbines = sort(plant_turbines, by=t -> t.maxdischarge, rev=true)
        if length(plant_turbines) > 1
            global numerator += 1 
            percent = (plant_turbines[1].maxdischarge - plant_turbines[end].maxdischarge) / plant_turbines[end].maxdischarge
            global mean_percent += percent 
            if percent > 80
                println(river)
                println("$plant_name : $(plant_turbines[1].maxdischarge) : $(plant_turbines[end].maxdischarge)")
            end 
        end 
    end 
end 

println(mean_percent / numerator)