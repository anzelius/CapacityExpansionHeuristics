function buildmodel(params, start_datetime, end_datetime, objective; type, power, e)
    println("\nBuilding model...")
    println("Start date & time = ", start_datetime)
    println("End date & time = ", end_datetime)


    @unpack PLANT, PPLANT, RES, TURBINE, SEGMENT, POINT, LAGS, date_TIME, plantinfo, turbineinfo, connectioninfo, realplants,
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
            tailrace_per_dischargelags, tailrace_per_downstreamforebay, tailrace_constant  = params

    println("Number of hours = ", length(date_TIME))
    println("type = ", type)

    rivermodel = Model()
    
    @variables rivermodel begin
        Profit                                                                    # unbounded, it's the objective                                                    # million SEK
        Load_diff                                                                 >= 0                                                                               # MWh                                                  
        Power_production[t in date_TIME, p in PPLANT, j in TURBINE[p]]            # lower bound set below                                                            # MWh/h
        Reservoir_content[t in date_TIME, p in PLANT]                             >= 0,                             (upper_bound = plantinfo[p].reservoir*Mm3toHE)   # HE (m3/s * 1h)
        Tail_level[t in date_TIME, p in PPLANT]                                   >= min_level[t,p,:tail],          (upper_bound = max_level[t,p,:tail])             # m 
        Forebay_level[t in date_TIME, p in PLANT]                                 >= min_level[t,p,:forebay],       (upper_bound = max_level[t,p,:forebay])          # m 
        Head[t in date_TIME, p in PPLANT]                                         >= minhead[p],                    (upper_bound = maxhead[p])                       # m  
        Discharge[t in date_TIME, p in PPLANT, j in TURBINE[p]]                   >= 0,                             (upper_bound = turbineinfo[p,j].maxdischarge)    # m3/s
        Eff_discharge[t in date_TIME, p in PPLANT, j in TURBINE[p]]               >= 0,                             (upper_bound = turbineinfo[p,j].maxdischarge)    # m3/s
        Passage_flow[t in date_TIME, p in PLANT, p2 in passage_downstream[p]]     >= min_passage_flow[t,p,p2],      (upper_bound = max_passage_flow[t,p,p2])         # m3/s
        Drybed_flow[t in date_TIME, p in PLANT, p2 in drybed_downstream[p]]       >= min_drybed_flow[t,p,p2],       (upper_bound = max_drybed_flow[t,p,p2])          # m3/s
        Utskov_flow[t in date_TIME, p in PLANT, p2 in utskov_downstream[p]]       >= min_utskov_flow[t,p,p2],       (upper_bound = max_utskov_flow[t,p,p2])          # m3/s
        Total_flow[t in date_TIME, p in PLANT, p2 in downstream[p]]               >= min_total_flow[t,p,p2],        (upper_bound = max_total_flow[t,p,p2])           # m3/s
    end #variables


    if !contains(power, "taylor")
        for t in date_TIME, p in PPLANT, j in TURBINE[p]
            set_lower_bound(Power_production[t,p,j], 0)
        end
    end

    @constraints rivermodel begin

        All_flows[t in date_TIME, p in PLANT, p2 in downstream[p]],
            Total_flow[t,p,p2] == ((p in PPLANT && p2 == discharge_downstream[p] ? sum(Discharge[t,p,j] for j in TURBINE[p]) : 0.0) 
                                  + (p2 in passage_downstream[p] ? Passage_flow[t,p,p2] : 0.0)
                                  + (p2 in drybed_downstream[p] ? Drybed_flow[t,p,p2] : 0.0)
                                  + (p2 in utskov_downstream[p] ? Utskov_flow[t,p,p2] : 0.0))

        Total_flow_up[t in date_TIME[2:end], p in PLANT, p2 in downstream[p]],
                Total_flow[t,p,p2] <= Total_flow[dtshift(date_TIME, t, 1),p,p2] + ramp_up_total_flow[t,p,p2]
        
        Total_flow_down[t in date_TIME[2:end], p in PLANT, p2 in downstream[p]],
                Total_flow[t,p,p2] >= Total_flow[dtshift(date_TIME, t, 1),p,p2] - ramp_down_total_flow[t,p,p2]

        Passage_flow_up[t in date_TIME[2:end], p in PLANT, p2 in passage_downstream[p]],
                Passage_flow[t,p,p2] <= Passage_flow[dtshift(date_TIME, t, 1),p,p2] + ramp_up_passage_flow[t,p,p2]

        Passage_flow_down[t in date_TIME[2:end], p in PLANT, p2 in passage_downstream[p]],
                Passage_flow[t,p,p2] >= Passage_flow[dtshift(date_TIME, t, 1),p,p2] - ramp_down_passage_flow[t,p,p2]
                
        Drybed_flow_up[t in date_TIME[2:end], p in PPLANT, p2 in drybed_downstream[p]],
                Drybed_flow[t,p,p2] <= Drybed_flow[dtshift(date_TIME, t, 1),p,p2] + ramp_up_drybed_flow[t,p,p2]

        Drybed_flow_down[t in date_TIME[2:end], p in PPLANT, p2 in drybed_downstream[p]],
                Drybed_flow[t,p,p2] >= Drybed_flow[dtshift(date_TIME, t, 1),p,p2] - ramp_down_drybed_flow[t,p,p2]

        Utskov_flow_up[t in date_TIME[2:end], p in PPLANT, p2 in utskov_downstream[p]],
                Utskov_flow[t,p,p2] <= Utskov_flow[dtshift(date_TIME, t, 1),p,p2] + ramp_up_utskov_flow[t,p,p2]

        Utskov_flow_down[t in date_TIME[2:end], p in PPLANT, p2 in utskov_downstream[p]],
                Utskov_flow[t,p,p2] >= Utskov_flow[dtshift(date_TIME, t, 1),p,p2] - ramp_down_utskov_flow[t,p,p2]

        Reservoir_final[p in PLANT],
        	Reservoir_content[date_TIME[end],p] >= reservoir_end[p]
        
        Water_Balance[t in date_TIME, p in PLANT],
            Reservoir_content[t,p] == (t > date_TIME[1] ? Reservoir_content[dtshift(date_TIME, t, 1),p] : reservoir_start[p]) +
                1 * (
                    + inflow[t,p]
                    - sum(Passage_flow[t,p,p2] for p2 in passage_downstream[p])
                    - sum(Drybed_flow[t,p,p2] for p2 in drybed_downstream[p])
                    - sum(Utskov_flow[t,p,p2] for p2 in utskov_downstream[p])
                    - sum(Discharge[t,p,j] for j in TURBINE[p])
                    + sum(Passage_flow[dtshift(date_TIME,t,up.passagedelay),up.name,p] for up in connectioninfo[p].upstream if p in passage_downstream[up.name])
                    + sum(Drybed_flow[dtshift(date_TIME,t,up.drybeddelay),up.name,p] for up in connectioninfo[p].upstream if p in drybed_downstream[up.name])
                    + sum(Utskov_flow[dtshift(date_TIME,t,up.utskovdelay),up.name,p] for up in connectioninfo[p].upstream if p in utskov_downstream[up.name])
                    + (p in discharge_recievers ? sum(Discharge[dtshift(date_TIME,t,up.dischargedelay),up.name,j] for up in discharge_upstream[p] for j in TURBINE[up.name]) : 0.0)
            ) 

        Forebay_level_constraint[t in date_TIME, p in PLANT],
            Forebay_level[t,p] == plantinfo[p].reservoirlow + Reservoir_content[t,p] / reservoir_area[p]
            
        Tailrace_level[t in date_TIME, p in PPLANT],
            Tail_level[t,p] == tailrace_constant[p] +
                sum(tailrace_per_dischargelags[p,n] * sum(Discharge[dtshift(date_TIME,t,n),p,j] for j in TURBINE[p]) for n in LAGS) +
                    ((downstream[p] == [:Hav]) ? 0.0 :
                        tailrace_per_downstreamforebay[p] * Forebay_level[t,discharge_downstream[p]])

        Forebay_level_up[t in date_TIME[2:end], p in PLANT],
            Forebay_level[t,p] <= Forebay_level[dtshift(date_TIME, t, 1),p] + ramp_up_level[t, p, :forebay]

        Forebay_level_down[t in date_TIME[2:end], p in PLANT],
            Forebay_level[t,p] >= Forebay_level[dtshift(date_TIME, t, 1),p] - ramp_down_level[t, p, :forebay]

        Tailrace_level_up[t in date_TIME[2:end], p in PPLANT],
            Tail_level[t,p] <= Tail_level[dtshift(date_TIME, t, 1),p] + ramp_up_level[t, p, :tail]

        Tailrace_level_down[t in date_TIME[2:end], p in PPLANT],
            Tail_level[t,p] >= Tail_level[dtshift(date_TIME, t, 1),p] - ramp_down_level[t, p, :tail]

        Calculate_head[t in date_TIME, p in PPLANT],
            Head[t,p] == Forebay_level[t, p] - Tail_level[t, p]

        Calculate_Profit,
            Profit == sum(sum(Power_production[t,p,j] for p in PPLANT for j in TURBINE[p]) * spot_price[t] for t in date_TIME) / 1e6
        
        end #constraints

        if objective == "Load"

            @constraints rivermodel begin
            Calculate_Load_diff,
                Load_diff >= sum((sum(Power_production[t,p,j] for p in PPLANT for j in TURBINE[p]) - load_comp[t])^2 for t in date_TIME)/length(date_TIME)
            end #constraints
        else
            Load_diff = NaN
        end


    if e == "cv segments origo"
            @constraints rivermodel begin
                eta_segments[t in date_TIME, p in PPLANT, j in TURBINE[p], s in SEGMENT], 
                    Eff_discharge[t,p,j] <= k_segcoeff_origo[p,j,s] * Discharge[t,p,j] + m_segcoeff_origo[p,j,s]
            end
        elseif type == :NLP && e == "ncv poly rampseg"
            @NLconstraint(rivermodel,
                eta_poly[t in date_TIME, p in PPLANT, j in TURBINE[p]],
                    Eff_discharge[t,p,j] <= (Discharge[t,p,j] <= end_rampseg[p,j]) * k_firstseg[p,j] * Discharge[t,p,j] +
                        (Discharge[t,p,j] > end_rampseg[p,j]) * sum(ed_coeff[p,j][i] * Discharge[t,p,j]^(i-1) for i = 1:3)
            )
        else 
            error("No alternative with: type = $type, e = $e.")
    end
    
    if contains(power, "taylor")
            @constraints rivermodel begin
                Calc_Power_production[t in date_TIME, p in PPLANT, j in TURBINE[p]],
                    Power_production[t,p,j] == ((plantinfo[p].meanhead * Eff_discharge[t,p,j] + Head[t,p] * turbineinfo[p,j].meandischarge * turbineinfo[p,j].meaneta +
                            - plantinfo[p].meanhead * turbineinfo[p,j].meaneta * turbineinfo[p,j].meandischarge) * grav * dens * WtoMW)
            end
        elseif type == :NLP && power == "bilinear HeadE"
            @NLconstraint(rivermodel,
                [t in date_TIME, p in PPLANT, j in TURBINE[p]], # Workaround for Gurobi bug, not naming constraint saves a lot of model generation time
                    Power_production[t,p,j] <= Head[t,p] * Eff_discharge[t,p,j] * grav * dens * WtoMW
            )
        else 
            error("No alternative with: type = $type, power = $power.")
    end

    if objective == "Profit"
        @objective(rivermodel, Max, Profit)
    elseif objective == "Load"
        @objective(rivermodel, Min, Load_diff)
    else
        error("No alternative with: objective = $objective.")
    end

    return (; rivermodel, Profit, Load_diff, Power_production, Reservoir_content, Tail_level, Forebay_level, Head, 
              Discharge, Eff_discharge, Passage_flow, Drybed_flow, Utskov_flow, Total_flow)
end


# Set start values using equations in run 2, no matter how variables in run 1 were calculated.
function set_start_values!(params, results, results2; type, power, e)
    @unpack date_TIME, PLANT, PPLANT, TURBINE = params
    Eff_discharge, Power_production, Profit, Forebay_level, Tail_level, Head = recalculate_variables(params, results; type, power, e)
    for t in date_TIME, p in PPLANT
        set_start_value(results2.Tail_level[t, p], Tail_level[t, p])
        set_start_value(results2.Head[t,p], Head[t,p])
        for j in TURBINE[p]
            set_start_value(results2.Eff_discharge[t,p,j], Eff_discharge[t,p,j])
            set_start_value(results2.Power_production[t,p,j], Power_production[t,p,j])
        end
    end
    set_start_value(results2.Profit, Profit)
end

function recalculate_variables(params, results; type, power, e)
    @unpack date_TIME, PLANT, PPLANT, SEGMENT, plantinfo, turbineinfo, realplants, downstream, TURBINE, spot_price, grav, dens, WtoMW, minhead, maxhead, ed_coeff,
            end_rampseg, k_firstseg, k_segcoeff, m_segcoeff, k_segcoeff_origo, m_segcoeff_origo,
            tailrace_constant, tailrace_per_dischargelags, tailrace_per_downstreamforebay, discharge_downstream, LAGS,
            min_level, max_level = params
    
    if typeof(results.Power_production) <: JuMP.Containers.SparseAxisArray
        Discharge, Head, Eff_discharge, Power_production, Forebay_level, Tail_level =
            value.(results.Discharge), value.(results.Head), value.(results.Eff_discharge), value.(results.Power_production), value.(results.Forebay_level), value.(results.Tail_level)
    else
        @unpack Discharge, Head, Eff_discharge, Power_production, Forebay_level, Tail_level = results
    end

    for t in date_TIME, p in PPLANT
        Tail_level[t, p] = tailrace_constant[p] +
            sum(tailrace_per_dischargelags[p,n] * sum(Discharge[dtshift(date_TIME,t,n), p, j] for j in TURBINE[p]) for n in LAGS) + ((downstream[p] == [:Hav]) ? 0.0 :
            tailrace_per_downstreamforebay[p] * Forebay_level[t, discharge_downstream[p]])

        Head[t,p] = Forebay_level[t, p] - Tail_level[t, p]

        for j in TURBINE[p]
            if e == "cv segments origo"
                Eff_discharge[t,p,j] = minimum(k_segcoeff_origo[p,j,s] * Discharge[t,p,j] + m_segcoeff_origo[p,j,s] for s in SEGMENT)
            elseif type == :NLP && e == "ncv poly rampseg"
                Eff_discharge[t,p,j] = (Discharge[t,p,j] <= end_rampseg[p,j]) ? k_firstseg[p,j] * Discharge[t,p,j] :
                        sum(ed_coeff[p,j][i] * Discharge[t,p,j]^(i-1) for i = 1:3)
            end

            if contains(power, "taylor")
                Power_production[t,p,j] = (plantinfo[p].nr_turbines == 0 ? 0.0 :
                    (plantinfo[p].meanhead * Eff_discharge[t,p,j] + Head[t,p] * turbineinfo[p,j].meandischarge * turbineinfo[p,j].meaneta +
                        - plantinfo[p].meanhead * turbineinfo[p,j].meaneta * turbineinfo[p,j].meandischarge) * grav * dens * WtoMW)
            elseif power == "bilinear HeadE"
                Power_production[t,p,j] = (Head[t,p] * Eff_discharge[t,p,j] * grav * dens * WtoMW)
            end
        end
    end

    Profit = sum(sum(Power_production[t,p,j] for p in PPLANT for j in TURBINE[p]) * spot_price[t] for t in date_TIME) / 1e6
    
    return Eff_discharge, Power_production, Profit, Forebay_level, Tail_level, Head
end
