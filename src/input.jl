using Dates, JLD2, DataFrames, XLSX

# Explicitly import what we need from Polynomials to avoid importing Polynomials.@variable which clashes with JuMP.
import Polynomials: Polynomials, Polynomial, roots, coeffs, derivative

export read_inputdata, estimate_effictive_discharge

function network_connections(river)

    plants = PLANTINFO[river]
    connections = NETWORK[river]
    plantinfo = Dict(p.name => p for p in plants)
    PLANT = [p.name for p in plants[1:end-1]] # Don't include the last plant as it is the Hav
    realplants = [plantinfo[p].nr_turbines != 0 for p in PLANT]
    PPLANT = PLANT[realplants]

    discharge_upstream = Dict{Symbol, Array{Upstream}}()
    downstream = Dict{Symbol, Array{Symbol}}()
    discharge_downstream = Dict{Symbol, Symbol}()
    passage_downstream = Dict{Symbol, Array{Symbol}}()
    drybed_downstream = Dict{Symbol, Array{Symbol}}()
    utskov_downstream = Dict{Symbol, Array{Symbol}}()

    for p in connections
        ups = Array{Upstream}(undef, 0)
        for up in p.upstream
            up.dischargedelay >= 0 && append!(ups, [up])
        end
        isempty(ups) && continue
        discharge_upstream[p.name] = ups
    end

    for up in connections
        downs = Array{Symbol}(undef, 0)
        ddowns = Array{Symbol}(undef, 0)
        pdowns = Array{Symbol}(undef, 0)
        dbdowns = Array{Symbol}(undef, 0)
        udowns = Array{Symbol}(undef, 0)
        for p in connections
            up.name in [a.name for a in p.upstream] && append!(downs, [p.name])
            up.name in [a.name for a in p.upstream if a.dischargedelay >= 0] && append!(ddowns, [p.name])
            up.name in [a.name for a in p.upstream if a.passagedelay >= 0] && append!(pdowns, [p.name])
            up.name in [a.name for a in p.upstream if a.drybeddelay >= 0] && append!(dbdowns, [p.name])
            up.name in [a.name for a in p.upstream if a.utskovdelay >= 0] && append!(udowns, [p.name])
        end
        downstream[up.name] = downs
        if up.name in PPLANT
            discharge_downstream[up.name] = ddowns[1]   # Only one downstream plant that recieves discharge
        end
        passage_downstream[up.name] = pdowns
        drybed_downstream[up.name] = dbdowns
        utskov_downstream[up.name] = udowns
    end

    length(downstream[PPLANT[end]]) > 1 && error("More than one downstream plant for the last power plant, infrastructure not supported.")

    discharge_recievers = [key for key in keys(discharge_upstream)]

    return discharge_upstream, downstream, discharge_downstream, passage_downstream, drybed_downstream, utskov_downstream, discharge_recievers
end

function read_inputdata(river, start_dt, end_dt, objective, model, scenario; env_con=true, silent=false)

    include("$DATAFOLDER/$river/network.jl")

    ##### TIME information #####
    start_datetime = DateTime(start_dt)
    end_datetime = DateTime(end_dt)
    start_date = Date(start_datetime)
    end_date = Date(end_datetime)
    start_week = Dates.week(start_date)
    end_week = Dates.week(end_date)

    date_TIME = collect(start_datetime:Hour(1):end_datetime)
    YEARS = unique(Dates.year.(date_TIME))

    println("\nReading $river input data for $(start_dt) to $(end_dt) ...")
    #println("TIME = ", date_TIME[1], " to ", date_TIME[end])
    println("Number of hours = ", length(date_TIME))
    #-----------------------------------------------------------------------------------------

    ##### Defining sets and parameters ########################################################
    plants = PLANTINFO[river]
    turbines = TURBINEINFO[river]
    connections = NETWORK[river]
    set_environmental_constraints! = ENVCON[river, scenario]

    plantinfo = Dict(p.name => p for p in plants)
    turbineinfo = Dict(t.name_nr => t for t in turbines)
    connectioninfo = Dict(c.name => c for c in connections)
    PLANT = [p.name for p in plants[1:end-1]] # Don't include the last plant as it is the Hav
    realplants = [plantinfo[p].nr_turbines != 0 for p in PLANT]
    reservoir = [plantinfo[p].nr_turbines == 0 for p in PLANT]
    PPLANT = PLANT[realplants]
    RES = PLANT[reservoir]
    TURBINE = Dict(plantinfo[p].nr_turbines > 0 ? p => collect(1:plantinfo[p].nr_turbines) : p => Int[] for p in PLANT)
    POINT = [:forebay, :tail]
    SEGMENT=1:10
    LAGS = 0:3

    grav = 9.81 # m/s2
    dens = 998 # kg/m3
    WtoMW = 1/1e6


    discharge_upstream, downstream, discharge_downstream, passage_downstream,
    drybed_downstream, utskov_downstream, discharge_recievers = network_connections(river)
    #-----------------------------------------------------------------------------------------


    ##### Read input files #####
    if isfile("$DATAFOLDER/$river/tailrace_coefficients.jld2")
        println("\n -- Reading tailrace coefficients")
        @time tailrace_coeff = load("$DATAFOLDER/$river/tailrace_coefficients.jld2")
        @unpack tailrace_constant, tailrace_per_dischargelags, tailrace_per_downstreamforebay = tailrace_coeff
    else
        println("\n -- Assuming constant tailrace levels for all plants")
        tailrace_constant = Dict{Symbol, Float64}()
        tailrace_per_dischargelags = Dict{Tuple{Symbol, Int}, Float64}()
        tailrace_per_downstreamforebay = Dict{Symbol, Float64}()

        for p in PPLANT
            tailrace_constant[p] = plantinfo[p].tailrace
            for i in LAGS
                tailrace_per_dischargelags[p,i] = 0.0
            end
            tailrace_per_downstreamforebay[p] = 0.0
            if isnan(tailrace_constant[p])
                error("Tailrace constant for $p is NaN")
            end
        end

    end
    for p in PPLANT
        if  !haskey(tailrace_constant, p)
            tailrace_constant[p] = plantinfo[p].tailrace
            println("No tailrace function for $p, assuming constant average tailrace")
        end
        for i in LAGS
            if !haskey(tailrace_per_dischargelags, (p,i))
                (tailrace_per_dischargelags[p,i] = 0.0)
            end
        end
        if !haskey(tailrace_per_downstreamforebay, p)
            (tailrace_per_downstreamforebay[p] = 0.0)
        end
        if isnan(tailrace_constant[p])
            error("Tailrace constant for $p is NaN")
        end
    end

    println("\n -- Reading historical reservoir levels")
    if !isfile("$DATAFOLDER/$river/$(river)_resBC.xlsx")
        println("\n No historical reservoir levels file found, assuming average values as boundary conditions...")
         resBC_df = DataFrame(XLSX.readtable("$DATAFOLDER/average_BC.xlsx", "Sheet1"))
    else
        @time resBC_df = DataFrame(XLSX.readtable("$DATAFOLDER/$river/$(river)_resBC.xlsx", "Sheet1"))
    end


    println("\n -- Reading price data")
        ##### Defining price areas depending on river #####
        if river in [:Skellefteälven, :Luleälven]
            Elområde = "SE1"
            elseif river in [:Ljungan, :Indalsälven, :Umeälven, :Ångermanälven, :Ljusnan]
            Elområde = "SE2"
            elseif river in [:Dalälven, :Götaälv, :Näckrosälven]
            Elområde = "SE3"
            else error("Elområde unknown")
        end
        spot_price = Dict{DateTime, Float64}()
    for y in YEARS 
        filename = "$DATAFOLDER/elspot_prices.xlsx"
        if check_sheet_exists(filename, "$(y)")
            @time price_df = DataFrame(XLSX.readtable("$DATAFOLDER/elspot_prices.xlsx", "$(y)"))
            date_TIME_yr = filter(dt -> year(dt) == y, date_TIME)
            for t in date_TIME_yr
                t_str = Dates.format(t, "yyyy-mm-dd HH:MM")
                if ismissing(price_df[price_df.date_times .== t_str, Elområde][1]) || isnan(price_df[price_df.date_times .== t_str, Elområde][1])
                    println(price_df[price_df.date_times .== t_str, Elområde][1])
                    error("No price data found for $Elområde for $(t_str)")
                end
                spot_price[t] = price_df[price_df.date_times .== t_str, Elområde][1]
            end
        else
            error("No sheet found for $(y) in elsport_prices.xlsx")
        end
    end
    println("Elområde: ", Elområde)

    if objective == "Load"
        println("\n -- Reading load data")
        if !isfile("$DATAFOLDER/$river/scenarios/Inga miljövillkor/results/Hela älven - $(start_dt) to $(end_dt) Profit $model Inga miljövillkor - Produktion och intäkt.xlsx")
            error("No load data found for $river $(start_datetime) to $(end_datetime) $model, run the model with objective Profit without environmental constraints first")
        end
        @time load_df = DataFrame(XLSX.readtable("$DATAFOLDER/$river/scenarios/Inga miljövillkor/results/Hela älven - $(start_dt) to $(end_dt) Profit $model Inga miljövillkor - Produktion och intäkt.xlsx", "Produktion"))
        load_vector = load_df[(load_df."Datum och tid" .>= date_TIME[1]) .& (load_df."Datum och tid" .<= date_TIME[end]), "Totalt (MWh)"]
        load_comp = Dict{DateTime, Float64}(t => load_vector[i] for (i,t) in enumerate(date_TIME))
    else
        load_comp = nothing
    end

    println("\n -- Reading inflow data")
    @time all_inflow_df = DataFrame(XLSX.readtable("$DATAFOLDER/$river/$(river)_inflow.xlsx", "Sheet1"))
    inflow_df = all_inflow_df[(all_inflow_df.Date .>= start_date) .& (all_inflow_df.Date .<= end_date), :]

    function expand_to_hourly(df)
        expanded_dates = Vector{DateTime}()
        expanded_data = Vector{Vector{Float64}}(undef, ncol(df) - 1)

        for i in 1:length(expanded_data)
            expanded_data[i] = Float64[]
        end

        for row in eachrow(df)
            date = row.Date
            hourly_times = [DateTime(date) + Hour(h) for h in 0:23]

            for i in 2:ncol(df)
                inflow_values = repeat([row[i]], 24)
                append!(expanded_data[i - 1], inflow_values)
            end
            append!(expanded_dates, hourly_times)
        end

        expanded_df = DataFrame(DateTime = expanded_dates)

        for i in 2:ncol(df)
            plant_name = names(df)[i]
            expanded_df[!, plant_name] = expanded_data[i - 1]
        end

        return expanded_df
    end

    hourly_inflow_df = expand_to_hourly(inflow_df)
    plant_names = filter(name -> name != "DateTime", names(hourly_inflow_df))
    inflow = Dict{Tuple{DateTime, Symbol}, Float64}((t, Symbol(p)) => hourly_inflow_df[hourly_inflow_df.DateTime .== t, p][1] for t in date_TIME, p in plant_names)

    if !isfile("$DATAFOLDER/$river/Qmetrics.xlsx")
        println("\n No Qmetrics file found, calculating Q metrics and creating the file...")
        establish_Q(river)
    end

    println("\n -- Reading Q file")
    @time Q = DataFrame(XLSX.readtable("$DATAFOLDER/$river/Qmetrics.xlsx", "Sheet1"))
    #-----------------------------------------------------------------------------------------

    ##### Constructing turbine efficiency curves #####
    println("\n -- Defining turbine efficiency curves")
        ed_coeff, k_firstseg, end_rampseg, end_zeroseg, end_zeroseg_poly, end_origoseg,
        k_segcoeff, m_segcoeff, k_segcoeff_origo, m_segcoeff_origo, maxturbed =
        estimate_effictive_discharge(PLANT, TURBINE, SEGMENT, turbineinfo, silent)
    #-----------------------------------------------------------------------------------------

    ##### Setting upper and lower bounds on forebay and tailrace water levels #####
    min_level = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()
    max_level = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()
    for t in date_TIME, p in plants
        max_level[t, p.name, :forebay] = p.reservoirhigh
        min_level[t, p.name, :forebay] = p.reservoirlow
    end

    for p in PPLANT
        per_discharge_min = minimum([0, sum(tailrace_per_dischargelags[p,n] for n in LAGS) * sum(turbineinfo[p,j].maxdischarge for j in TURBINE[p])])
        per_downstream_forebay_min = (p == PLANT[end]) ? 0.0 : minimum([tailrace_per_downstreamforebay[p] * minimum([min_level[t,discharge_downstream[p],:forebay] for t in date_TIME]), tailrace_per_downstreamforebay[p] * maximum([max_level[t,discharge_downstream[p],:forebay] for t in date_TIME])])
        per_discharge_max = maximum([0, sum(tailrace_per_dischargelags[p,n] for n in LAGS) * sum(turbineinfo[p,j].maxdischarge for j in TURBINE[p])])
        per_downstream_forebay_max = (p == PLANT[end]) ? 0.0 : maximum([tailrace_per_downstreamforebay[p] * minimum([min_level[t,discharge_downstream[p],:forebay] for t in date_TIME]), tailrace_per_downstreamforebay[p] * maximum([max_level[t,discharge_downstream[p],:forebay] for t in date_TIME])])
        for t in date_TIME
        min_level[t,p,:tail] = tailrace_constant[p] + per_discharge_min + per_downstream_forebay_min
        max_level[t,p,:tail] = tailrace_constant[p] + per_discharge_max + per_downstream_forebay_max
        end
    end


    if !silent
        println("\nWater level bounds [max forebay, min forebay, max tail, min tail]")
        println([[max_level[date_TIME[1],p,:forebay] for p in PLANT] [min_level[date_TIME[1],p,:forebay] for p in PLANT] [max_level[date_TIME[1],p,:tail] for p in PLANT] [min_level[date_TIME[1],p,:tail] for p in PLANT]])
    end
    #-----------------------------------------------------------------------------------------

    ##### Setting max and min head in the model #####
    maxhead = Dict{Symbol, Float64}(p => (max_level[date_TIME[1], p, :forebay] - min_level[date_TIME[1], p, :tail]) for p in PPLANT) #m.a.s
    minhead = Dict{Symbol, Float64}(p => (min_level[date_TIME[1], p, :forebay] - max_level[date_TIME[1], p, :tail]) for p in PPLANT) #m.a.s

    #--------------------------------------------------------------------------------------------

    ##### Print out control values #####
    if !silent
        println("\n[meanhead, meandischarge, maxdischarge, meaneta]")
        for p in PLANT, j in TURBINE[p]
        println("$p - $j: ", [plantinfo[p].meanhead turbineinfo[p,j].meandischarge turbineinfo[p,j].maxdischarge turbineinfo[p,j].meaneta])
        end
    end
    #-----------------------------------------------------------------------------------------

    ##### Printing out maximum turbine discharge to enable location of bottlenecks #####
    max_discharge_df = DataFrame(plant = Symbol[], max_plant_discharge = Float64[], MHQ = Float64[])

    for p in PPLANT
        max_d = sum(turbineinfo[p,j].maxdischarge for j in TURBINE[p])
        push!(max_discharge_df, (p, max_d, Q[Q.Plant .== String(p), "MHQ"][1]))
    end

    #println("\n", max_discharge_df)
    #-----------------------------------------------------------------------------------------

    ##### Finding the aggregated capacity in the river #####
    maxcap = Dict{Symbol, Float64}()
    for p in PPLANT
        maxcap[p] = sum(maxhead[p]*maxturbed[p,j]*grav*dens*WtoMW for j in TURBINE[p])
    end
    aggcap = sum(maxcap[p] for p in PPLANT)
    !silent && println("\nTheoretic max capacity in river = ", round(aggcap; digits=1), " MW")
    !silent && println("")
    !silent && [println("$p = ", round(maxcap[p]; digits=1), " MW") for p in PPLANT]
    #-----------------------------------------------------------------------------------------

    ##### Calculating total inflow from upstream to plant #####
    function allupstream(plant)
        directlyupstream = getfield.(connectioninfo[plant].upstream, :name)
        isempty(directlyupstream) && return directlyupstream
        return vcat(directlyupstream..., allupstream.(directlyupstream)...) |> unique
    end

    function delay_between(plant, plant2, totaldelay=0)
        plant == plant2 && return totaldelay
        upstream = connectioninfo[plant].upstream
        isempty(upstream) && return 999    # oops, miss
        return minimum(delay_between(up.name, plant2, totaldelay + up.dischargedelay) for up in upstream)
    end

    acc_upstream_inflow = Dict{Tuple{DateTime, Symbol}, Float64}()
    println("\n -- Calculating total inflow from all upstream to each plant")
    @time   for p in PLANT, dt in date_TIME
                acc_upstream_inflow[dt,p] = sum(maximum([inflow[dtshift(date_TIME, dt, tw),pl] for tw in (delay_between(p, pl)):(delay_between(p, pl)+24)])
                                            for pl in vcat(p, allupstream(p)))
            end
    #-----------------------------------------------------------------------------------------


    ##### Applying environmental constraints #####
    min_total_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                          # m3/s
    max_total_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                          # m3/s
    ramp_up_total_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                      # m3/s/h
    ramp_down_total_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                    # m3/s/h

    min_passage_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                        # m3/s
    max_passage_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                        # m3/s
    ramp_up_passage_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                    # m3/s/h
    ramp_down_passage_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                  # m3/s/h

    min_drybed_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                         # m3/s
    max_drybed_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                         # m3/s
    ramp_up_drybed_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                     # m3/s/h
    ramp_down_drybed_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                   # m3/s/h

    min_utskov_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                         # m3/s
    max_utskov_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                         # m3/s
    ramp_up_utskov_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                     # m3/s/h
    ramp_down_utskov_flow = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}()                                   # m3/s/h

    ramp_up_level = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}((t,p,point) => 1 for t in date_TIME, p in PLANT, point in POINT)
    ramp_down_level = Dict{Tuple{DateTime, Symbol, Symbol}, Float64}((t,p,point) => 1 for t in date_TIME, p in PLANT, point in POINT)


    # ----------------- Default values for environmental constraints ------------------------------------------------------
    println("\n -- Setting default values for environmental constraints")
    for t in date_TIME, p in PLANT, p2 in downstream[p]
        min_total_flow[t,p,p2] = 0.0
        max_total_flow[t,p,p2] = NaN
        ramp_up_total_flow[t,p,p2] = 1e4
        ramp_down_total_flow[t,p,p2] = 1e4
    end

    for t in date_TIME, p in PLANT, p2 in passage_downstream[p]
        min_passage_flow[t,p,p2] = 0.0
        max_passage_flow[t,p,p2] = NaN
        ramp_up_passage_flow[t,p,p2] = 1e4
        ramp_down_passage_flow[t,p,p2] = 1e4
    end

    for t in date_TIME, p in PLANT, p2 in drybed_downstream[p]
        min_drybed_flow[t,p,p2] = 0.0
        max_drybed_flow[t,p,p2] = NaN
        ramp_up_drybed_flow[t,p,p2] = 1e4
        ramp_down_drybed_flow[t,p,p2] = 1e4
    end

    for t in date_TIME, p in PLANT, p2 in utskov_downstream[p]
        min_utskov_flow[t,p,p2] = 0.0
        max_utskov_flow[t,p,p2] = NaN
        ramp_up_utskov_flow[t,p,p2] = 1e4
        ramp_down_utskov_flow[t,p,p2] = 1e4
    end

    #= for t in date_TIME, p in RES, p2 in downstream[p]
            ramp_up_total_flow[t,p,p2] = Q[Q.Plant .== String(p), "MHQ"][1]/(24*7)
            ramp_down_total_flow[t,p,p2] = Q[Q.Plant .== String(p), "MHQ"][1]/(24*7)
    end =#

    #-----------------------------------------------------------------------------------------

    flow_params = (; date_TIME, PLANT, PPLANT, RES, Q, acc_upstream_inflow, downstream, passage_downstream, drybed_downstream, utskov_downstream,
        max_total_flow, min_total_flow, ramp_up_total_flow, ramp_down_total_flow,
        max_passage_flow, min_passage_flow, ramp_up_passage_flow, ramp_down_passage_flow,
        max_drybed_flow, min_drybed_flow, ramp_up_drybed_flow, ramp_down_drybed_flow,
        max_utskov_flow, min_utskov_flow, ramp_up_utskov_flow, ramp_down_utskov_flow, connectioninfo)

    level_params = (; date_TIME, min_level, max_level, ramp_up_level, ramp_down_level)
    
    if env_con
        println("\n -- Applying environmental constraints")
        set_environmental_constraints!(flow_params, level_params)
    end
    #-----------------------------------------------------------------------------------------

    ##### Setting maximum flow constraints if they were not set by the environmental constraints #####
    println("\n -- Setting maximum flow constraints if they were not set by the environmental constraints")

    for t in date_TIME, p in PLANT, p2 in downstream[p]
        if isnan(max_total_flow[t,p,p2])
            max_total_flow[t,p,p2] = maximum([Q[Q.Plant .== String(p), "MHQ"][1], acc_upstream_inflow[t,p],
                                ((p in PPLANT ? sum(turbineinfo[p,j].maxdischarge for j in TURBINE[p]) : 0.0)
                                + (p2 in passage_downstream[p] ? min_passage_flow[t,p,p2] : 0.0)
                                + (p2 in drybed_downstream[p] ? min_drybed_flow[t,p,p2] : 0.0)
                                + (p2 in utskov_downstream[p] ? min_utskov_flow[t,p,p2] : 0.0) )])
        end
        if p2 in passage_downstream[p] && isnan(max_passage_flow[t,p,p2])
            max_passage_flow[t,p,p2] = maximum([Q[Q.Plant .== String(p), "MHQ"][1], acc_upstream_inflow[t,p]])
        end
        if p2 in drybed_downstream[p] && isnan(max_drybed_flow[t,p,p2])
            max_drybed_flow[t,p,p2] = maximum([Q[Q.Plant .== String(p), "MHQ"][1], acc_upstream_inflow[t,p]])
        end
        if p2 in utskov_downstream[p] && isnan(max_utskov_flow[t,p,p2])
            max_utskov_flow[t,p,p2] = maximum([Q[Q.Plant .== String(p), "MHQ"][1], acc_upstream_inflow[t,p]])
        end
    end

    ##### Allowing lower spillage than minimum spillage if inflow is lower than the requirement #####
    println("\n -- Allowing lower flow limits if inflow is lower than the requirement")
    for p in PLANT, t in date_TIME

        total_min_flows = ((isempty(passage_downstream[p]) ? 0.0 : sum(min_passage_flow[t,p,p2] for p2 in passage_downstream[p]))
                        + (isempty(drybed_downstream[p]) ? 0.0 : sum(min_drybed_flow[t,p,p2] for p2 in drybed_downstream[p]))
                        + (isempty(utskov_downstream[p]) ? 0.0 : sum(min_utskov_flow[t,p,p2] for p2 in utskov_downstream[p])))

        min_passage_flow_share = (isempty(passage_downstream[p]) ? 0.0 : sum(min_passage_flow[t,p,p2] for p2 in passage_downstream[p]) / total_min_flows)
        min_drybed_flow_share = (isempty(drybed_downstream[p]) ? 0.0 : sum(min_drybed_flow[t,p,p2] for p2 in drybed_downstream[p]) / total_min_flows)
        min_utskov_flow_share = (isempty(utskov_downstream[p]) ? 0.0 : sum(min_utskov_flow[t,p,p2] for p2 in utskov_downstream[p]) / total_min_flows)

        if acc_upstream_inflow[t,p] < total_min_flows
            [min_passage_flow[t,p,p2] = (acc_upstream_inflow[t,p]*min_passage_flow_share)/length(passage_downstream[p]) for p2 in passage_downstream[p]]
            [min_drybed_flow[t,p,p2] = (acc_upstream_inflow[t,p]*min_drybed_flow_share)/length(drybed_downstream[p]) for p2 in drybed_downstream[p]]
            [min_utskov_flow[t,p,p2] = (acc_upstream_inflow[t,p]*min_utskov_flow_share)/length(utskov_downstream[p]) for p2 in utskov_downstream[p]]
        end
    end
    #-----------------------------------------------------------------------------------------

    ##### Defining start and end reservoir levels and reservoir area #####
    println("\n -- Defining start and end reservoir levels")
    start_week = week(date_TIME[1])
    end_week = week(date_TIME[end])
    start_year = year(date_TIME[1])
    end_year = year(date_TIME[end])

    start_level = Dict{Symbol, Float64}()
    end_level = Dict{Symbol, Float64}()
    for p in PLANT
        if isfile("$DATAFOLDER/$river/$(river)_resBC.xlsx")
            start_value = resBC_df[(resBC_df.Week .== start_week) .& (resBC_df.Year .== start_year), p][1]
            end_value = resBC_df[(resBC_df.Week .== end_week) .& (resBC_df.Year .== end_year), p][1]
        else
            start_value = (plantinfo[p].reservoirhigh-plantinfo[p].reservoirlow)*resBC_df[resBC_df.Week .== start_week, :Fyllnadsgrad][1]+plantinfo[p].reservoirlow
            end_value = (plantinfo[p].reservoirhigh-plantinfo[p].reservoirlow)*resBC_df[resBC_df.Week .== end_week, :Fyllnadsgrad][1]+plantinfo[p].reservoirlow
        end
        start_level[p] = maximum([start_value, min_level[date_TIME[1], p, :forebay]])
        start_level[p] = minimum([start_level[p], max_level[date_TIME[1], p, :forebay]])
        end_level[p] = maximum([end_value, min_level[date_TIME[end], p, :forebay]])
        end_level[p] = minimum([end_level[p], max_level[date_TIME[end], p, :forebay]])
    end

    start_reservoir_content = Dict{Symbol, Float64}(p.name => (start_level[p.name] - p.reservoirlow) / (p.reservoirhigh - p.reservoirlow) * p.reservoir*Mm3toHE for p in plants[1:end-1])
    end_reservoir_content = Dict{Symbol, Float64}(p.name => (end_level[p.name] - p.reservoirlow) / (p.reservoirhigh - p.reservoirlow) * p.reservoir*Mm3toHE for p in plants[1:end-1])
    reservoir_start = Dict{Symbol, Float64}(p => start_reservoir_content[p] for p in PLANT)   # HE
    reservoir_end = Dict{Symbol, Float64}(p => end_reservoir_content[p] for p in PLANT)   # HE
    reservoir_area = Dict{Symbol, Float64}(p.name => p.reservoir*Mm3toHE / (p.reservoirhigh - p.reservoirlow) for p in plants[1:end-1]) #HE/m
    # --------------------------------------------------------------------------------------------------------

    println("\nTotal time for reading input:")

    return (; PLANT, PPLANT, RES, TURBINE, SEGMENT, POINT, LAGS, date_TIME, plantinfo, turbineinfo, connectioninfo, realplants,
            discharge_recievers, downstream, discharge_downstream, passage_downstream, drybed_downstream, utskov_downstream, discharge_upstream,
            maxcap, aggcap, inflow, spot_price, load_comp, grav, dens, WtoMW,
            max_total_flow, min_total_flow, ramp_up_total_flow, ramp_down_total_flow,
            max_passage_flow, min_passage_flow, ramp_up_passage_flow, ramp_down_passage_flow,
            max_drybed_flow, min_drybed_flow, ramp_up_drybed_flow, ramp_down_drybed_flow,
            max_utskov_flow, min_utskov_flow, ramp_up_utskov_flow, ramp_down_utskov_flow,
            max_level, min_level, ramp_up_level, ramp_down_level,
            k_firstseg, end_rampseg, end_zeroseg, end_zeroseg_poly, end_origoseg,
            k_segcoeff, m_segcoeff, k_segcoeff_origo, m_segcoeff_origo, ed_coeff,
            maxhead, minhead, reservoir_start, reservoir_end, reservoir_area,
            tailrace_per_dischargelags, tailrace_per_downstreamforebay, tailrace_constant)
end


function estimate_effictive_discharge(PLANT, TURBINE, SEGMENT, turbineinfo, silent)

    ed_coeff = Dict{Tuple{Symbol, Int64}, Any}()
    curve_color = Dict{Tuple{Symbol, Int64}, Symbol}()
    maxturbed = Dict{Tuple{Symbol, Int64}, Float64}()
    origolinepoint = Dict()
    segmentpoints = Dict()
    origosegmentpoints = Dict()
    k_segcoeff = Dict()
    k_segcoeff_origo = Dict()
    m_segcoeff = Dict()
    m_segcoeff_origo = Dict()
    k_firstseg = Dict{Tuple{Symbol, Int64}, Float64}()
    end_rampseg = Dict{Tuple{Symbol, Int64}, Float64}()
    end_zeroseg = Dict{Tuple{Symbol, Int64}, Float64}()
    end_zeroseg_poly = Dict{Tuple{Symbol, Int64}, Float64}()
    end_origoseg = Dict{Tuple{Symbol, Int64}, Float64}()

    for (i, p) in enumerate(PLANT), j in TURBINE[p]

        if isempty(turbineinfo[p,j].etapoints)
            f = generate_quadratic(turbineinfo[p,j].meandischarge, turbineinfo[p,j].meaneta, turbineinfo[p,j].maxdischarge*0.2)
            p_discharge = [turbineinfo[p,j].maxdischarge*0.2, turbineinfo[p,j].meandischarge, turbineinfo[p,j].maxdischarge]
            p_eta = [f(turbineinfo[p,j].maxdischarge*0.2), f(turbineinfo[p,j].meandischarge), f(turbineinfo[p,j].maxdischarge)]
        else
            p_discharge = [turbineinfo[p,j].etapoints[i].d for i in 1:length(turbineinfo[p,j].etapoints)]
            p_eta = [turbineinfo[p,j].etapoints[i].e for i in 1:length(turbineinfo[p,j].etapoints)]
        end

        p_pe = p_discharge .* p_eta
        Eff_discharge = Polynomials.fit(p_discharge, p_pe, 2)  # fit 2nd degree polynomial to Eff_discharge points (not eta!)
        curve_color[p,j] = :green
        maxturbed[p,j] = maximum(Eff_discharge.(0:turbineinfo[p,j].maxdischarge))
        ed_coeff[p,j] = coeffs(Eff_discharge)

        dPE = derivative(Eff_discharge)
        root = minimum(roots(Eff_discharge))
        cpe = ed_coeff[p,j]
        origolinepoint = sqrt(cpe[1] / cpe[3])      # origoline touching a + bx + cx2 has x=sqrt(a/c)

        segmentpoints = range(root, stop=turbineinfo[p,j].maxdischarge, length=length(SEGMENT))
        origosegmentpoints = range(origolinepoint, stop=turbineinfo[p,j].maxdischarge, length=length(SEGMENT))

        k_firstseg[p,j] = 0.3

        for s in SEGMENT
            x, ox = segmentpoints[s], origosegmentpoints[s]
            k_segcoeff[p,j,s] = dPE(x)
            m_segcoeff[p,j,s] = Eff_discharge(x) - k_segcoeff[p,j,s] * x
            k_segcoeff_origo[p,j,s] = dPE(ox)
            m_segcoeff_origo[p,j,s] = (s == 1) ? 0.0 : Eff_discharge(ox) - k_segcoeff_origo[p,j,s] * ox
        end

        end_rampseg[p,j] = m_segcoeff[p,j,1] / (k_firstseg[p,j] - k_segcoeff[p,j,1])
        end_rampseg[p,j] = (end_rampseg[p,j] > turbineinfo[p,j].maxdischarge) ? 0.0 : end_rampseg[p,j]
        end_zeroseg[p,j] = -m_segcoeff[p,j,1] / k_segcoeff[p,j,1]
        end_zeroseg_poly[p,j] = root
        end_origoseg[p,j] = origolinepoint

        if !silent
            plotly()
            d = 0:.01:turbineinfo[p,j].maxdischarge
            dd = 0:.01:minimum(roots(Eff_discharge))

            # plotting effective discharge (discharge*eta)
            a = plot()
            for s in SEGMENT
                plot!(a, d, k_segcoeff_origo[p,j,s] .* d .+ m_segcoeff_origo[p,j,s], line=(2, :gold, :solid), la=1, label=(s<=1 ? "model B:L" : nothing))
            end
            plot!(a, d, Eff_discharge.(d), line=(7, :grey30), label="Effective discharge")
            plot!(a, dd, zeros(length(dd)), line=(7, :grey30, :solid), label=nothing)
            plot!(a, d, max.(k_firstseg[p,j] * d, Eff_discharge.(d)), line=(7, :dodgerblue2, :dash), label="model A")
            plot!(a, xlim=(0,turbineinfo[p,j].maxdischarge*1.05), ylim=(0,turbineinfo[p,j].maxdischarge*1.05), legend=:bottomright, xlabel="Discharge [m3/s]", ylabel="Effective discharge [m3/s]",
             tickfont=16, legendfont=16, guidefont=18, titlefont=20, size = (800, 500), automargin=true, left_margin=10mm, show=true) # title="Effective Discharge",

            # plotting efficiency
            ps=1
            b = plot()
            for s in SEGMENT
                plot!(b, d, k_segcoeff_origo[p,j,s] .+ m_segcoeff_origo[p,j,s]./d, line=(2*ps, :gold, :solid), la=1, label=nothing) #(s<=1 ? "B:L and C" : nothing))
            end
            plot!(b, d, Eff_discharge.(d)./d, line=(7*ps, :grey30, :solid), label=nothing) #"Typical turbine")
            plot!(b, dd, zeros(length(dd)), line=(7*ps, :grey30, :solid), label=nothing)
            plot!(b, d, max.(k_firstseg[p,j], Eff_discharge.(d)./d), line=(7*ps, :dodgerblue2, :dash), label=nothing) #"model A")
            plot!(b, xlim=(0, turbineinfo[p,j].maxdischarge.*1.05), ylim=(0,1.1), legend=nothing, xlabel=nothing, ylabel="Efficiency",
            tickfont=16*ps, legendfont=16*ps, guidefont=18*ps, titlefont=20*ps, size = (800*ps, 500*ps), automargin=true, left_margin=10mm, show=true) #title="Efficiency",

            # plotting them together
            plot(b, a, layout=(2), size=(1200, 500), legend=:outertopright, title="$p - $j", show=true)#, link=:x)  #title="Efficiency",
        end
    end

    return ed_coeff, k_firstseg, end_rampseg, end_zeroseg, end_zeroseg_poly, end_origoseg,
           k_segcoeff, m_segcoeff, k_segcoeff_origo, m_segcoeff_origo, maxturbed
end
