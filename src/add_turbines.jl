using Base: searchsortedfirst

#include("FORSA.jl")
#include("bottlenecks.jl") 

# list all turbines in order of max discharge for binary search 
sorted_turbines = []
for river in rivers
    for turbine in TURBINEINFO[river] 
        index = searchsortedfirst([t.maxdischarge for t in sorted_turbines], turbine.maxdischarge)
        insert!(sorted_turbines, index, turbine)
    end 
end 

function search_two_turbines(target)
    left = 1
    right = length(sorted_turbines)
    
    while left < right
        sum_discharge = sorted_turbines[left].maxdischarge + sorted_turbines[right].maxdischarge
        
        if sum_discharge == target
            return (sorted_turbines[left], sorted_turbines[right]) 
        elseif sum_discharge < target
            left += 1  
        else
            right -= 1  
        end
    end
    return nothing 
end 

function build_from_existing_turbines(target_turbine, plant_name, river)
    index = findfirst(t -> t.name == plant_name, PLANTINFO[river])
    turbine_nr = PLANTINFO[river][index].nr_turbines + 1
    PLANTINFO[river][index].nr_turbines = turbine_nr 
    new_turbine = Turbine((plant_name, turbine_nr), target_turbine.maxdischarge, target_turbine.meandischarge, target_turbine.meaneta, target_turbine.etapoints)
    return new_turbine 
end  

function build_artificial_effective_discharge_turbine(plant_name, river, missing_discharge)
    index = findfirst(t -> t.name == plant_name, PLANTINFO[river])
    turbine_nr = PLANTINFO[river][index].nr_turbines + 1
    PLANTINFO[river][index].nr_turbines = turbine_nr 
    # TODO: this function is not finished.. 
    return new_turbine 
end 


# input river_bottlenecks = Dict{Symbol, Dict{Symbol, Int64}}()  
# river : Dict(bottleneck plant : missing_discharge)
# river_bottlenecks::Dict{Symbol, Dict{Symbol, Int64}}
# reduce bottlenecks by adding any type of new turbine matching the required discharge 
function add_bottleneck_turbines(river)
    #for river in rivers 
        if haskey(river_bottlenecks, river)
            for (plant_name, missing_discharge) in river_bottlenecks[river]
                
                index = searchsortedfirst([t.maxdischarge for t in sorted_turbines], missing_discharge)
    
                if index <= length(sorted_turbines) && sorted_turbines[index].maxdischarge == missing_discharge
                    target_turbine = sorted_turbines[index]
                    new_turbine = build_from_existing_turbines(target_turbine, plant_name, river)
                    push!(TURBINEINFO[river], new_turbine)
                else 
                    result = search_two_turbines(missing_discharge)
                    if result !== nothing
                        target_turbine1, target_turbine2 = result 
                        new_turbine1 = build_from_existing_turbines(target_turbine1, plant_name, river)
                        new_turbine2 = build_from_existing_turbines(target_turbine2, plant_name, river)
                        push!(TURBINEINFO[river], new_turbine1)
                        push!(TURBINEINFO[river], new_turbine2) 
                    else 
                        nothing 
                        #println(missing_discharge) only the ones with -1 
                        #new_turbine = build_artificial_effective_discharge_turbine(plant_name, river, missing_discharge)
                        #push!(TURBINEINFO[river], new_turbine)
                    end 
                end 
            end  
        end  
    #end 
end 

function largest_smaller_than_or_equal(sorted_list, threshold)
    idx = searchsortedfirst([t.maxdischarge for t in sorted_turbines], threshold)  
    if idx <= length(sorted_list) && sorted_list[idx].maxdischarge == threshold
        return sorted_list[idx]  
    end
    return idx > 1 ? sorted_list[idx - 1] : nothing  
end

# reduce bottlenecks by increasing max_discharge and adding similar turbines  
function increase_discharge_and_new_turbines(river)
    threshold_discharge_increase = 0.1 
    threshold_plant_diff = 0.35

    #for river in rivers 
        if haskey(river_bottlenecks, river)
            for (plant_name, missing_discharge) in river_bottlenecks[river]
                plant_turbines = [plant_turbine for plant_turbine in TURBINEINFO[river] if plant_turbine.name_nr[1] == plant_name]
                plant_turbines = sort(plant_turbines, by=t -> t.maxdischarge, rev=true)
                missing_discharge_save, plant_turbines_save = nothing, nothing 
                TURBINEINFO_TEMP = []
                # try first adding turbines 
                while true 
                    @label start 
                    # try adding turbines of same models 
                    for plant_turbine in plant_turbines
                        if plant_turbine.maxdischarge <= missing_discharge
                            new_turbine = build_from_existing_turbines(plant_turbine, plant_name, river)
                            push!(plant_turbines, new_turbine) 
                            missing_discharge -= new_turbine.maxdischarge
                            println("New turbine for $river : $plant_name")
                            # TODO: add turbine  
                            push!(TURBINEINFO[river], new_turbine)
                            @goto start  
                        end 
                    end 
                    # save this state to go back to if other fails 
                    missing_discharge_save = missing_discharge 
                    plant_turbines_save = copy(plant_turbines)
                    # try adding turbines of similar models (max diff. 35 %) 
                    q_plant_turbines = [abs(missing_discharge -  plant_turbine.maxdischarge) / plant_turbine.maxdischarge for plant_turbine in plant_turbines]
                    if all(x -> x > threshold_plant_diff, q_plant_turbines)
                        break 
                    end 
                    for plant_turbine in plant_turbines, q in q_plant_turbines
                        if q  < threshold_plant_diff
                            target_turbine = largest_smaller_than_or_equal(sorted_turbines, missing_discharge)
                            if target_turbine !== nothing 
                                new_turbine = build_from_existing_turbines(target_turbine, plant_name, river)
                                push!(plant_turbines, new_turbine) 
                                # TODO: add turbine to TURBINEINFO_TEMP 
                                push!(TURBINEINFO_TEMP, new_turbine)
                                missing_discharge -= new_turbine.maxdischarge
                                println("New turbine for $river : $plant_name") 
                                break 
                            end 
                        end 
                    end  
                end 
                
                # then try increase discharge 
                plant_discharge_to_increase = Dict{Turbine, Int64}() 
                @label start2 
                while missing_discharge > 0
                    if isempty(plant_turbines)
                        # if there is still missing discharge and not possible to increase discharge
                        # at existing turbines, roll-back and add a smaller turbine  
                        # TODO: add turbine          
                        target_turbine = largest_smaller_than_or_equal(sorted_turbines, missing_discharge_save)
                        if target_turbine !== nothing
                            missing_discharge = missing_discharge_save
                            empty!(TURBINEINFO_TEMP)
                            empty!(plant_discharge_to_increase)
                            new_turbine = build_from_existing_turbines(target_turbine, plant_name, river)
                            missing_discharge -= new_turbine.maxdischarge
                            plant_turbines = copy(plant_turbines_save) 
                            push!(TURBINEINFO[river], new_turbine)
                            push!(plant_turbines, new_turbine)
                            println("trying again: $river : $plant_name , $missing_discharge")
                            @goto start2 
                        else
                            println("Couldn't find turbine smaller than $missing_discharge_save")
                            break 
                        end 
                    end 
                    # increase discharge at existing turbines 
                    plant_turbine = popfirst!(plant_turbines)
                    q = missing_discharge / plant_turbine.maxdischarge
                    if q < threshold_discharge_increase
                        # increase discharge at plant turbine 
                        # TODO: increase discharge at a temp turbine for now, then replace at the end 
                        plant_discharge_to_increase[plant_turbine] = missing_discharge
                        #plant_turbine.maxdischarge += missing_discharge
                        println("increased discharge for: $river : $plant_name with $missing_discharge")
                        missing_discharge -= missing_discharge 
                    else
                        #increase discharge at plant turbine 
                        # TODO: increase discharge at a temp turbine for now, then replace at the end 
                        #plant_turbine.maxdischarge += min(missing_discharge, round(plant_turbine.maxdischarge * threshold_discharge_increase))
                        plant_discharge_to_increase[plant_turbine] = min(missing_discharge, round(plant_turbine.maxdischarge * threshold_discharge_increase))
                        println("increased discharge for: $river : $plant_name with $(min(missing_discharge, round(plant_turbine.maxdischarge * threshold_discharge_increase)))")
                        missing_discharge -= min(missing_discharge, ceil(plant_turbine.maxdischarge * threshold_discharge_increase))  
                    end  
                end 

                # add turbines and missing discharge to turbines 
                if !isempty(plant_discharge_to_increase) 
                    for (plant, discharge_to_increase) in plant_discharge_to_increase
                        plant.maxdischarge += discharge_to_increase
                    end 
                end

                if !isempty(TURBINEINFO_TEMP)
                    for new_turbine in TURBINEINFO_TEMP
                        push!(TURBINEINFO[river], new_turbine)
                    end  
                end           
            end 
        end 
    #end 
end 


# reduce bottlenecks by increasing max_discharge only  
function increase_discharge(river)
    threshold_discharge_increase = 0.3 

    #for river in rivers 
        if haskey(river_bottlenecks, river)
            for (plant_name, missing_discharge) in river_bottlenecks[river]
                plant_turbines = [plant_turbine for plant_turbine in TURBINEINFO[river] if plant_turbine.name_nr[1] == plant_name]
                plant_turbines = sort(plant_turbines, by=t -> t.maxdischarge, rev=true)
                # increase discharge as much as possible  
                plant_discharge_to_increase = Dict{Turbine, Int64}() 
                if plant_name == :Vittjärv
                    println("test")
                end 
                while missing_discharge > 0
                    if isempty(plant_turbines)
                        # can't increase discharge anymore but still some left, leave it 
                        break          
                    end 
                    # increase discharge at existing turbines 
                    plant_turbine = popfirst!(plant_turbines)
                    q = missing_discharge / plant_turbine.maxdischarge
                    if q < threshold_discharge_increase
                        # increase discharge at plant turbine 
                        # TODO: increase discharge at a temp turbine for now, then replace at the end 
                        plant_discharge_to_increase[plant_turbine] = missing_discharge
                        #plant_turbine.maxdischarge += missing_discharge
                        println("increased discharge for: $river : $plant_name with $missing_discharge")
                        missing_discharge -= missing_discharge 
                    else
                        #increase discharge at plant turbine 
                        # TODO: increase discharge at a temp turbine for now, then replace at the end 
                        #plant_turbine.maxdischarge += min(missing_discharge, round(plant_turbine.maxdischarge * threshold_discharge_increase))
                        plant_discharge_to_increase[plant_turbine] = min(missing_discharge, round(plant_turbine.maxdischarge * threshold_discharge_increase))
                        println("increased discharge for: $river : $plant_name with $(min(missing_discharge, round(plant_turbine.maxdischarge * threshold_discharge_increase)))")
                        missing_discharge -= min(missing_discharge, ceil(plant_turbine.maxdischarge * threshold_discharge_increase))  
                    end  
                end 

                # add turbines and missing discharge to turbines 
                if !isempty(plant_discharge_to_increase) 
                    for (plant, discharge_to_increase) in plant_discharge_to_increase
                        plant.maxdischarge += discharge_to_increase
                    end 
                end

            end 
        end 
    #end 
end 
