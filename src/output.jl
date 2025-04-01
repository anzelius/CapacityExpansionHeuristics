using StatsBase, XLSX

function savevariables(river, params, start_datetime, end_datetime, obj, model, scenario, results, solvetime, name)
    println("\nSaving variables to JLD2 archive...")

    folder = "$DATAFOLDER/$river/scenarios/$scenario/results"

    if !isdir(folder)
        mkpath(folder)
    end

    power_production = Dict((string(key[1]), key[2], key[3]) => value for (key, value) in value.(results.Power_production).data)
    discharge = Dict((string(key[1]), key[2], key[3]) => value for (key, value) in value.(results.Discharge).data)
    passage_flow = Dict((string(key[1]), key[2], key[3]) => value for (key, value) in value.(results.Passage_flow).data)
    drybed_flow = Dict((string(key[1]), key[2], key[3]) => value for (key, value) in value.(results.Drybed_flow).data)
    utskov_flow = Dict((string(key[1]), key[2], key[3]) => value for (key, value) in value.(results.Utskov_flow).data)
    total_flow = Dict((string(key[1]), key[2], key[3]) => value for (key, value) in value.(results.Total_flow).data)
    date_TIME = [string(dt) for dt in params.date_TIME]

    vars = (
        profit = value(results.Profit),
        load_diff = value(results.Load_diff),
        power_production = power_production,
        reservoir_content = value.(results.Reservoir_content).data,
        t_level = value.(results.Tail_level).data,
        f_level = value.(results.Forebay_level).data,
        #head = value.(results.Head).data,
        discharge = discharge,
        passage_flow = passage_flow,
        drybed_flow = drybed_flow,
        utskov_flow = utskov_flow,
        total_flow = total_flow,
        solve_t = solvetime)

    data = (
        PLANT = params.PLANT,
        PPLANT = params.PPLANT,
        RES = params.RES,
        TURBINE = params.TURBINE,
        date_TIME = date_TIME,
        discharge_recievers = params.discharge_recievers,
        downstream = params.downstream,
        discharge_downstream = params.discharge_downstream,
        passage_downstream = params.passage_downstream,
        drybed_downstream = params.drybed_downstream,
        utskov_downstream = params.utskov_downstream,
        discharge_upstream = params.discharge_upstream,
        spot_price = params.spot_price,
    )

    println("...saving jld2 file")
    jldsave("$folder/$(start_datetime) to $(end_datetime) $obj $model $scenario.jld2 $name"; vars..., data..., compress=true)

    power_data = value.(results.Power_production).data
    t_h_p = Vector{Float64}(undef, length(params.date_TIME))

    for (i,t) in enumerate(params.date_TIME)
        total = 0.0
        for p in params.PPLANT
            turbines = params.TURBINE[p]
            for j in turbines
                total += power_data[t,p,j]
            end
        end
        t_h_p[i] = total
    end

    prod_df = DataFrame(total_hourly_production = t_h_p, date_TIME = params.date_TIME)
    println("...saving Excel files")
    XLSX.openxlsx("$folder/Hela älven - $(start_datetime) to $(end_datetime) $obj $model $scenario - $name Produktion och intäkt.xlsx", mode="w") do xf
        sheet = xf[1]
        XLSX.rename!(sheet, "Produktion")

        # Headers
        sheet["A1"] = "Datum och tid"
        sheet["B1"] = "Totalt (MWh)"

        for i in 1:length(params.date_TIME)
            sheet["A$(i+1)"] = prod_df.date_TIME[i]
            sheet["B$(i+1)"] = prod_df.total_hourly_production[i]
        end

        sheet2 = XLSX.addsheet!(xf, "Intäkt")
        sheet2["A1"] = "Intäkt (MSEK)"
        sheet2["A2"] = vars.profit

        if obj == "Load"
            sheet3 = XLSX.addsheet!(xf, "Avvikelse")
            sheet3["A1"] = "Medel avvikelse (MWh/h)"
            sheet3["A2"] = sqrt(vars.load_diff)
        end
    end

    println("Results saved to $folder")
end

function export_plantdata_to_xslx(river::Union{String, Symbol}, scenarios::Vector{String}, start_datetime::String, end_datetime::String, obj::String, model::String, plant::Union{String, Symbol}, power::Bool, level::Bool, flow::Bool)
    river = isa(river, String) ? Symbol(river) : river
    plant = isa(plant, String) ? Symbol(plant) : plant

    folder = "$DATAFOLDER/$river/scenarios"
    paths = ["$folder/$scenario/results" for scenario in scenarios]
    rundata = readresults(paths, obj, model, start_datetime, end_datetime)
    scenarios = unique([run.scenario for run in rundata])

    isempty(scenarios) && error("No runs for these scenarios for this time span")
    nr_scenarios = length(scenarios)

    for scenario in scenarios
        for run in rundata
            if run.scenario == scenario
                if power
                    println("...saving turbine power production to Excel file")

                    # Generate the file path explicitly
                    file_path = "$folder/$(run.scenario)/results/$(plant) - $(start_datetime) to $(end_datetime) $obj $model $(run.scenario) - Produktion och intäkt.xlsx"

                    # Open the Excel file and write data
                    XLSX.openxlsx(file_path, mode="w") do xf
                        # Explicitly add the sheet and avoid renaming
                        sheet = xf[1]
                        XLSX.rename!(sheet, "Produktion")
                        # Headers
                        sheet["A1"] = "Datum och tid"

                        # Write date and time in the first column
                        for ii in 1:length(run.date_TIME)
                            sheet["A$(ii+1)"] = run.date_TIME[ii]
                        end

                        # Write each turbine's production in a separate column
                        for (i, j) in enumerate(run.TURBINE[plant])
                            # Set the header for each turbine
                            col_letter = Char('B' + i - 1)
                            sheet[string(col_letter)*"1"] = "Turbin $j (MWh)"

                            # Get production data for the turbine
                            turbpowervalues = [run.power_turbines[t, plant, j] for t in run.date_TIME]

                            # Write each production value in the appropriate column
                            for (ii, t) in enumerate(run.date_TIME)
                                sheet[string(col_letter)*"$(ii+1)"] = round(turbpowervalues[ii], digits=3)
                            end
                        end

                        col_letter = Char(col_letter+1)
                        sheet[string(col_letter)*"1"] = "Totalt (MWh)"
                        totalpowervalues = [sum(run.power_turbines[t, plant, j] for j in run.TURBINE[plant]) for t in run.date_TIME]
                        for (ii, t) in enumerate(run.date_TIME)
                            sheet[string(col_letter)*"$(ii+1)"] = round(totalpowervalues[ii], digits=3)
                        end

                        plant_profit = sum(totalpowervalues[i] * run.spot_price[DateTime(t)] for (i, t) in enumerate(run.date_TIME))/1e6

                        sheet2 = XLSX.addsheet!(xf, "Intäkt")
                        sheet2["A1"] = "Intäkt (MSEK)"
                        sheet2["A2"] = plant_profit
                    end

                end
                if flow
                    println("...saving water flows to Excel file")

                    XLSX.openxlsx("$folder/$(run.scenario)/results/$plant - $(start_datetime) to $(end_datetime) $obj $model $(run.scenario) - Flöden.xlsx", mode="w") do xf
                        for (i, p2) in enumerate(run.downstream[plant])
                            if i == 1
                                sheet = xf[i]
                                XLSX.rename!(sheet, "Till $p2")
                            else
                                sheet = XLSX.addsheet!(xf, "Till $p2")
                            end

                            # Write date and time in the first column
                            sheet["A1"] = "Datum och tid"
                            for ii in 1:length(run.date_TIME)
                                sheet["A$(ii+1)"] = run.date_TIME[ii]
                            end

                            if plant in run.PPLANT && p2 == run.discharge_downstream[plant]
                                # Write each turbine's discharge in a separate column
                                for (ii, j) in enumerate(run.TURBINE[plant])
                                    # Set the header for each turbine
                                    col_letter = Char('B' + ii - 1)
                                    sheet[string(col_letter)*"1"] = "Turbin $j"

                                    # Get production data for the turbine
                                    dischargevalues = [run.discharge[t, plant, j] for t in run.date_TIME]

                                    # Write each discharge value in the appropriate column
                                    for iii in 1:length(run.date_TIME)
                                        sheet["$col_letter$(iii+1)"] = round(dischargevalues[iii], digits=3)
                                    end
                                end
                            else
                                col_letter = Char('A')
                            end

                            if p2 in run.passage_downstream[plant]
                                col_letter = Char(col_letter+1)
                                sheet[string(col_letter)*"1"] = "Passage"
                                passagevalues = [run.passage_flow[t, plant, p2] for t in run.date_TIME]
                                for iii in 1:length(run.date_TIME)
                                    sheet["$col_letter$(iii+1)"] = round(passagevalues[iii], digits=3)
                                end
                            end
                            if p2 in run.drybed_downstream[plant]
                                col_letter = Char(col_letter+1)
                                sheet[string(col_letter)*"1"] = "Torrfåra"
                                drybedvalues = [run.drybed_flow[t, plant, p2] for t in run.date_TIME]
                                for iii in 1:length(run.date_TIME)
                                    sheet["$col_letter$(iii+1)"] = round(drybedvalues[iii], digits=3)
                                end
                            end
                            if p2 in run.utskov_downstream[plant]
                                col_letter = Char(col_letter+1)
                                sheet[string(col_letter)*"1"] = "Utskov"
                                utskovvalues = [run.utskov_flow[t, plant, p2] for t in run.date_TIME]
                                for iii in 1:length(run.date_TIME)
                                    sheet["$col_letter$(iii+1)"] = round(utskovvalues[iii], digits=3)
                                end
                            end
                            col_letter = Char(col_letter+1)
                            sheet[string(col_letter)*"1"] = "Totalt"
                            totalvalues = [run.total_flow[t, plant, p2] for t in run.date_TIME]
                            for iii in 1:length(run.date_TIME)
                                sheet["$col_letter$(iii+1)"] = round(totalvalues[iii], digits=3)
                            end
                        end

                    end
                end
                if level
                    println("...saving water levels to Excel file")
                    XLSX.openxlsx("$folder/$(run.scenario)/results/$plant - $(start_datetime) to $(end_datetime) $obj $model $(run.scenario) - Vattenytor.xlsx", mode="w") do xf
                        sheet = xf[1]
                        XLSX.rename!(sheet, "Vattenytor")

                        sheet["A1"] = "Datum och tid"
                        # Write date and time in the first column
                        for ii in 1:length(run.date_TIME)
                            sheet["A$(ii+1)"] = run.date_TIME[ii]
                        end

                        sheet["B1"] = "ÖVY"
                        ovylevels = [run.forebay_level[t, plant] for t in run.date_TIME]
                        for ii in 1:length(run.date_TIME)
                            sheet["B$(ii+1)"] = round(ovylevels[ii], digits=3)
                        end

                        if plant in run.PPLANT
                            sheet["C1"] = "NVY"
                            nvylevels = [run.tail_level[t, plant] for t in run.date_TIME]
                            for ii in 1:length(run.date_TIME)
                                sheet["C$(ii+1)"] = round(nvylevels[ii], digits=3)
                            end
                        end
                    end
                end
            end
        end
    end
end

function printbasicresults(params, results; type, power, e, recalculate=false)
    @unpack rivermodel, Power_production, Discharge, Reservoir_content = results
    @unpack PLANT, PPLANT, TURBINE, date_TIME, realplants, spot_price = params
    println("Profit (Million SEK): ", round(objective_value(rivermodel), digits=2))
    try
        println("Best bound: ", objective_bound(rivermodel))
    catch
        println("Best bound: [none available]")
    end
    println("Total power production (TWh): ", round(sum(value.(Power_production))/1e6, digits=2))

    pp = value.(Power_production) 
    sum_result = [sum(pp[t, :, :]) for t in date_TIME]
    println("Top power (MW): ", maximum(sum_result))
    top_power_date = date_TIME[argmax(sum_result)] 
    println("Date: $top_power_date")

    captured_price = round(objective_value(rivermodel)*1e6/sum(value.(Power_production)), digits = 2)
    println("Captured price (SEK/MWh): ", captured_price)
    if recalculate
        _, powerproduction, profit, _, _ = recalculate_variables(params, results; type, power, e)
        println("Recalculated Profit (Million SEK): ", round(profit, digits=2))
        println("Recalculated Total power production (TWh): ", round(sum(powerproduction)/1e6, digits=2))
        captured_price_recalculated = round(profit*1e6/sum(powerproduction), digits = 2)
        println("Recalculated Captured price (SEK/MWh): ", captured_price_recalculated)
        
        sum_result2 = [sum(powerproduction[t, :, :]) for t in date_TIME]
        println("Recalculated top power (MW): ", maximum(sum_result2))
    end
    #println("Discharge usage at top power: ")
    #d = value.(Discharge) 
    #for p in PPLANT
    #    println("$p : $(sum(d[top_power_date, p, :]))")
    #end 
#sum_d = [sum(d[:, p, :]) for p in PPLANT]
end
