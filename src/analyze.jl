using Plots, Dates, Colors, StatsPlots
plotlyjs()

function plot_riverinfo(river::Union{String, Symbol}, scenarios::Vector{String}, obj::String, model:: String, start_datetime::String, end_datetime::String, display_plots::Bool=true)
    river = isa(river, String) ? Symbol(river) : river

    plotsettings = (legend = :outertopright, grid = :on, ticks=:native, top_margin=8mm, left_margin=8mm, titlefont = ("Computer Modern", 14, :bold),
                    guidefont = ("Computer Modern", 12, :bold), tickfont = ("Computer Modern", 10), legendfont = ("Computer Modern", 12, :bold))
    barplotsettings = (legend = :outertopright, grid = :on, top_margin=8mm, left_margin=8mm, titlefont = ("Computer Modern", 14, :bold),
                    guidefont = ("Computer Modern", 12, :bold), tickfont = ("Computer Modern", 10), legendfont = ("Computer Modern", 12, :bold))

    scenario_colors = [:dodgerblue4, :olivedrab4, :darkorange, :teal, :firebrick, :darkorchid4, :gold, :sienna, :honeydew4, :gray20]

    folder = "$DATAFOLDER/$river/scenarios"

    paths = ["$folder/$scenario/results" for scenario in scenarios]

    rundata = readresults(paths, obj, model, start_datetime, end_datetime)

    scenarios = unique([run.scenario for run in rundata])

    nr_scenarios = length(scenarios)

    profits = Dict{String, Float64}()
    total_productions = Dict{String, Float64}()
    captured_prices = Dict{String, Float64}()

    hourly_datetimes, xtick_dates, xtick_indexes = generate_hourly_datetimes(start_datetime, end_datetime)

    powerplot = plot(title = "Produktionsprofil - $(river)", xlabel = false, ylabel = "Produktion [MWh/h]"; plotsettings...)
    PDC = plot(title = "Ordnad total produktion - $(river)", xlabel = "Timmar", ylabel = "Produktion [MWh/h]"; plotsettings...)

    for (i,scenario) in enumerate(scenarios)
        for run in rundata
            if run.scenario == scenario
                powervalues = [sum(run.power_turbines[t,p,j] for p in run.PPLANT for j in run.TURBINE[p]) for t in run.date_TIME]
                pdc = sort(powervalues, rev=true)
                hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, powervalues)]
                plot!(powerplot, hourly_datetimes, powervalues,
                      color = scenario_colors[i], label = scenario, lw = 2, la=0.8,
                      hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                plot!(PDC, 1:length(pdc), pdc, color = scenario_colors[i], label = scenario, lw = 2, la=0.8, size = (900, 450); plotsettings...)
                profits[scenario] = run.profit # In MSEK
                total_productions[scenario] = sum(run.power_turbines[t,p,j] for t in run.date_TIME for p in run.PPLANT for j in run.TURBINE[p]) / 1e6 # In TWh
                captured_prices[scenario] = profits[scenario] / total_productions[scenario] # in MSEK/TWh or SEK/MWh
            end
        end
    end

    if display_plots
        display(powerplot)
        display(PDC)
    end

    profit_values = [profits[sc] for sc in scenarios]
    total_production_values = [total_productions[sc] for sc in scenarios]
    captured_price_values = [captured_prices[sc] for sc in scenarios]

    name = repeat([""], outer=nr_scenarios)
    ctg = repeat(scenarios, inner=1) |> CategoricalArray
    levels!(ctg, scenarios)
    col = repeat(scenario_colors[1:nr_scenarios], outer=1)

    hover_text1 = [string(round(val, digits=2)) for val in profit_values]
    hover_text2 = [string(round(val, digits=2)) for val in total_production_values]
    hover_text3 = [string(round(val, digits=2)) for val in captured_price_values]

    p3 = groupedbar(name, captured_price_values, group=ctg, color = col, lw=0, hover=hover_text3,
               title = "Medelintäkt - $(river)", xlabel = "", ylabel = "[SEK/MWh]"; barplotsettings..., legend=:outerbottomright, show=display_plots, size=(650, 450))
    p1 = groupedbar(name, profit_values, group=ctg, color = col, lw=0, hover=hover_text1,
               title = "Intäkt - $(river)", xlabel = "", ylabel = "[MSEK]"; barplotsettings..., legend=:outerbottomright, show=display_plots, size=(650, 450))
    p2 = groupedbar(name, total_production_values, group=ctg, color = col, lw=0, hover=hover_text2,
               title = "Total produktion - $(river)", xlabel = "", ylabel = "[TWh]"; barplotsettings..., legend=:outerbottomright, show=display_plots, size=(650, 450))

    figurefolder = "$folder/figures"
    isdir(figurefolder) || mkdir(figurefolder)

    scenariostring = join(scenarios, "-")

    savefig(powerplot, "$figurefolder/powerprod_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
    savefig(PDC, "$figurefolder/PDC_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime)_PDC.html")
    savefig(p1, "$figurefolder/profit_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
    savefig(p2, "$figurefolder/totalproduction_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
    savefig(p3, "$figurefolder/capturedprice_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")

    plots_dict = Dict(
        "Produktionsprofil" => "$figurefolder/powerprod_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html",
        "Ordnad produktion" => "$figurefolder/PDC_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime)_PDC.html",
        "Intäkt" => "$figurefolder/profit_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html",
        "Total produktion" => "$figurefolder/totalproduction_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html",
        "Medelintäkt" => "$figurefolder/capturedprice_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html",
    )
    return plots_dict
end

function plot_plantinfo(river::Union{String, Symbol}, scenarios::Vector{String}, obj::String, model:: String, start_datetime::String, end_datetime::String, plant::Union{String, Symbol}; power::Bool=false, level::Bool=false, flow::Bool=false, display_plots::Bool = true)
    river = isa(river, String) ? Symbol(river) : river
    plant = isa(plant, String) ? Symbol(plant) : plant

    plots_dict = Dict{String, String}()
    plotsettings = (legend = :outertopright, grid = :on, ticks=:native, top_margin=8mm, left_margin=8mm, titlefont = ("Computer Modern", 14, :bold),
                    guidefont = ("Computer Modern", 12, :bold), tickfont = ("Computer Modern", 10), legendfont = ("Computer Modern", 12, :bold))
    barplotsettings = (legend = :outertopright, grid = :on, top_margin=8mm, left_margin=8mm, titlefont = ("Computer Modern", 14, :bold),
                    guidefont = ("Computer Modern", 12, :bold), tickfont = ("Computer Modern", 10), legendfont = ("Computer Modern", 12, :bold))

    scenario_colors = [:dodgerblue4, :olivedrab4, :darkorange, :teal, :firebrick, :darkorchid4, :gold, :sienna, :honeydew4, :gray20]
    linestyles = [:solid, :dot, :dash, :dashdot, :dashdotdot, :solid, :dash, :dot, :dashdot, :dashdotdot]

    folder = "$DATAFOLDER/$river/scenarios"

    paths = ["$folder/$scenario/results" for scenario in scenarios]

    rundata = readresults(paths, obj, model, start_datetime, end_datetime)

    scenarios = unique([run.scenario for run in rundata])

    scenariostring = join(scenarios, "-")

    nr_scenarios = length(scenarios)

    PPLANT = rundata[1].PPLANT

    profits = Dict{String, Float64}()
    total_productions = Dict{String, Float64}()
    captured_prices = Dict{String, Float64}()

    hourly_datetimes, xtick_dates, xtick_indexes = generate_hourly_datetimes(start_datetime, end_datetime)

    power && (plantpowerplot = plot(title = "Produktionsprofil - $(plant)", xlabel = false, ylabel = "[MWh/h]"; plotsettings...))
    power && (plantPDCplot = plot(title = "Ordnad produktion - $(plant)", xlabel = "Timmar", ylabel = "[MWh/h]"; plotsettings...))
    level && (reservoircontentplot = plot(title = "Magasinsinnehåll - $(plant)", xlabel = false, ylabel = "[Mm3]"; plotsettings...))
    level && (forebayplot = plot(title = "Övre vattenyta - $(plant)", xlabel = false, ylabel = "[m.ö.h]"; plotsettings...))
    level && (plant in PPLANT) && (tailplot = plot(title = "Nedre vattenyta - $(plant)", xlabel = false, ylabel = "[m.ö.h]"; plotsettings...))
    flow && (plant in PPLANT) && (dischargeplot = plot(title = "Totala turbinflöden - $(plant)", xlabel = false, ylabel = "[m3/s]"; plotsettings...))
    flow && (passageflowplot = plot(title = "Passagelösning - $(plant)", xlabel = false, ylabel = "[m3/s]"; plotsettings...))
    flow && (drybedflowplot = plot(title = "Torrfåra - $(plant)", xlabel = false, ylabel = "[m3/s]"; plotsettings...))
    flow && (utskovflowplot = plot(title = "Utskov - $(plant)", xlabel = false, ylabel = "[m3/s]"; plotsettings...))
    flow && (totalflowplot = plot(title = "Totalflöde - $(plant)", xlabel = false, ylabel = "[m3/s]"; plotsettings...))


    passage_downstream_plant = [rundata[i].passage_downstream[plant] for i in 1:length(rundata)]
    drybed_downstream_plant = [rundata[i].drybed_downstream[plant] for i in 1:length(rundata)]
    utskov_downstream_plant = [rundata[i].utskov_downstream[plant] for i in 1:length(rundata)]
    plotpassage = (all(isempty, passage_downstream_plant) ? false : true)
    plotdrybed = (all(isempty, drybed_downstream_plant) ? false : true)
    plotutskov = (all(isempty, utskov_downstream_plant) ? false : true)

    for (i,scenario) in enumerate(scenarios)
        for run in rundata
            if run.scenario == scenario

                if plant in run.PPLANT && power
                    powervalues = [sum(run.power_turbines[t,plant,j] for j in run.TURBINE[plant]) for t in run.date_TIME]
                    hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, powervalues)]
                    plot!(plantpowerplot, hourly_datetimes, powervalues,
                        color = scenario_colors[i], label = scenario, lw = 2, la=0.8,
                        hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                    pdc = sort(powervalues, rev=true)
                    plot!(plantPDCplot, 1:length(pdc), pdc, color = scenario_colors[i], label = scenario, lw = 2, la=0.8, size = (900, 450); plotsettings...)
                    profits[scenario] = sum(powervalues[i]*run.spot_price[DateTime(t)] for (i,t) in enumerate(run.date_TIME)) / 1e6 # In MSEK
                    total_productions[scenario] = sum(powervalues) / 1e6 # In TWh
                    captured_prices[scenario] = profits[scenario] / total_productions[scenario] # in MSEK/TWh or SEK/MWh
                end

                @time (level || flow) ? params = read_inputdata(river, start_datetime, end_datetime, run.objective, run.model_type, scenario, silent=true) : params = nothing

                if level
                    resvalues = [run.reservoir_content[t,plant]/Mm3toHE for t in run.date_TIME]
                    hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, resvalues)]
                    plot!(reservoircontentplot, hourly_datetimes, resvalues,
                        color = scenario_colors[i], label = scenario, lw = 2, la=0.8, ylim=(0,params.plantinfo[plant].reservoir*1.1),
                        hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                    resmin = [(params.min_level[DateTime(t),plant,:forebay]/params.plantinfo[plant].reservoirlow - 1)*params.plantinfo[plant].reservoir for t in run.date_TIME]
                    hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, resmin)]
                    plot!(reservoircontentplot, hourly_datetimes, resmin,
                        color = scenario_colors[i], label = "$scenario - Min. content", lw = 1, la=0.8, ls = :dot, hover=hover_text)
                    resmax = [(params.max_level[DateTime(t),plant,:forebay]/params.plantinfo[plant].reservoirhigh)*params.plantinfo[plant].reservoir for t in run.date_TIME]
                    hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, resmax)]
                    plot!(reservoircontentplot, hourly_datetimes, resmax,
                        color = scenario_colors[i], label = "$scenario - Max. content", lw = 1, la=0.8, ls = :dash, hover=hover_text)

                    fvalues = [run.forebay_level[t,plant] for t in run.date_TIME]
                    hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, fvalues)]
                    plot!(forebayplot, hourly_datetimes, fvalues,
                        color = scenario_colors[i], label = "$scenario", lw = 2, la=0.8, ls = :solid,
                        hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                    minvalues = [params.min_level[DateTime(t),plant,:forebay] for t in run.date_TIME]
                    hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, minvalues)]
                    plot!(forebayplot, hourly_datetimes, minvalues,
                        color = scenario_colors[i], label = "$scenario - Min. level", lw = 1, la=0.8, ls = :dot, hover=hover_text)
                    maxvalues = [params.max_level[DateTime(t),plant,:forebay] for t in run.date_TIME]
                    hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, maxvalues)]
                    plot!(forebayplot, hourly_datetimes, maxvalues,
                        color = scenario_colors[i], label = "$scenario - Max. level", lw = 1, la=0.8, ls = :dash, hover=hover_text)

                    if plant in run.PPLANT
                        tvalues = [run.tail_level[t,plant] for t in run.date_TIME]
                        hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, tvalues)]
                        plot!(tailplot, hourly_datetimes, tvalues,
                            color = scenario_colors[i], label = "$scenario", lw = 2, la=0.8, ls = :solid,
                            hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                        minvalues = [params.min_level[DateTime(t),plant,:tail] for t in run.date_TIME]
                        hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, minvalues)]
                        plot!(tailplot, hourly_datetimes, minvalues,
                            color = scenario_colors[i], label = "$scenario - Min. level", lw = 1, la=0.8, ls = :dot, hover=hover_text)
                        maxvalues = [params.max_level[DateTime(t),plant,:tail] for t in run.date_TIME]
                        hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, maxvalues)]
                        plot!(tailplot, hourly_datetimes, maxvalues,
                            color = scenario_colors[i], label = "$scenario - Max. level", lw = 1, la=0.8, ls = :dash, hover=hover_text)
                    end
                end

                if flow
                    if plant in run.PPLANT
                       #=  for (ii,j) in enumerate(run.TURBINE[plant])
                            dvalues = [run.discharge[t,plant,j] for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, dvalues)]
                            plot!(dischargeplot, hourly_datetimes, dvalues,
                                color = scenario_colors[i], label = "$(scenario) - Turbine $j ", lw = 2, la=0.8, ls = linestyles[ii+1],
                                hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                            maxvalues = [params.turbineinfo[plant,j].maxdischarge for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, maxvalues)]
                            plot!(dischargeplot, hourly_datetimes, maxvalues,
                                color = scenario_colors[i], label = "$(scenario) - Max. Turbine $j", lw = 1, la=0.8, ls = :dash, hover=hover_text)
                        end =#
                        if length(run.TURBINE[plant]) > 0 #1
                            dvalues = [round(sum(run.discharge[t,plant,j] for j in run.TURBINE[plant]), digits=2) for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, dvalues)]
                            plot!(dischargeplot, hourly_datetimes, dvalues,
                                color = scenario_colors[i], label = "$(scenario)", lw = 2, la=0.8, ls = :solid,
                                hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                            maxvalues = [sum(params.turbineinfo[plant,j].maxdischarge for j in run.TURBINE[plant]) for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, maxvalues)]
                            plot!(dischargeplot, hourly_datetimes, maxvalues,
                                color = scenario_colors[i], label = "$(scenario) - Max.", lw = 1, la=0.8, ls = :dash, hover=hover_text)
                        end
                    end
                        for (ii,p2) in enumerate(run.passage_downstream[plant])
                            spvalues = [round(run.passage_flow[t,plant,p2], digits=2) for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, spvalues)]
                            plot!(passageflowplot, hourly_datetimes, spvalues,
                                color = scenario_colors[i], label = "$(scenario) - $plant to $p2", lw = 2, la=0.8, ls = linestyles[ii],
                                hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                            minvalues = [params.min_passage_flow[DateTime(t),plant,p2] for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, minvalues)]
                            plot!(passageflowplot, hourly_datetimes, minvalues,
                                color = scenario_colors[i], label = "$(scenario) - Min. $plant to $p2", lw = 1, la=0.8, ls = :dot, hover=hover_text)
                            #= maxvalues = [params.max_passage_flow[t,plant,p2] for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, maxvalues)]
                            plot!(passageflowplot, hourly_datetimes, maxvalues,
                                color = :black, label = "$(scenario) - Max. $plant to $p2", lw = 1, la=0.8, ls = :dash, hover=hover_text) =#

                        end

                        for (ii,p2) in enumerate(run.drybed_downstream[plant])
                            sdvalues = [round(run.drybed_flow[t,plant,p2], digits=2) for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, sdvalues)]
                            plot!(drybedflowplot, hourly_datetimes, sdvalues,
                                color = scenario_colors[i], label = "$(scenario) - $plant to $p2", lw = 2, la=0.8, ls = linestyles[ii],
                                hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                            minvalues = [params.min_drybed_flow[t,plant,p2] for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, minvalues)]
                            plot!(drybedflowplot, hourly_datetimes, minvalues,
                                color = scenario_colors[i], label = "$(scenario) - Min. $plant to $p2", lw = 1, la=0.8, ls = :dot, hover=hover_text)
                            #= maxvalues = [params.maxspill_drybed[t,plant,p2] for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, maxvalues)]
                            plot!(drybedflowplot, hourly_datetimes, maxvalues,
                                color = :black, label = "$(scenario) - Max. $plant to $p2", lw = 1, la=0.8, ls = :dash, hover=hover_text) =#
                        end

                        for (ii, p2) in enumerate(run.utskov_downstream[plant])
                            suvalues = [round(run.utskov_flow[t,plant,p2], digits=2) for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, suvalues)]
                            plot!(utskovflowplot, hourly_datetimes, suvalues,
                                color = scenario_colors[i], label = "$(scenario) - $plant to $p2", lw = 2, la=0.8, ls = linestyles[ii],
                                hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                            minvalues = [params.min_utskov_flow[DateTime(t),plant,p2] for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, minvalues)]
                            plot!(utskovflowplot, hourly_datetimes, minvalues,
                                color = scenario_colors[i], label = "$(scenario) - Min. $plant to $p2", lw = 1, la=0.8, ls = :dot, hover=hover_text)
                            #= maxvalues = [params.max_utskov_flow[t,plant,p2] for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, maxvalues)]
                            plot!(utskovflowplot, hourly_datetimes, maxvalues,
                                color = :black, label = "$(scenario) - Max. $plant to $p2", lw = 1, la=0.8, ls = :dash, hover=hover_text) =#
                        end

                        for (ii,p2) in enumerate(run.downstream[plant])
                            tfvalues = [round(run.total_flow[t,plant,p2], digits=2) for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, tfvalues)]
                            plot!(totalflowplot, hourly_datetimes, tfvalues,
                                color = scenario_colors[i], label = "$(scenario) - $plant to $p2", lw = 3, la=0.8, ls = linestyles[ii],
                                hover = hover_text, xticks=(xtick_indexes, string.(xtick_dates)), xrotation=45, size = (900, 450); plotsettings...)
                            minvalues = [params.min_total_flow[DateTime(t),plant,p2] for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, minvalues)]
                            plot!(totalflowplot, hourly_datetimes, minvalues,
                                color = scenario_colors[i], label = "$(scenario) - Min. $plant to $p2", lw = 1, la=0.8, ls = :dot, hover=hover_text)
                            maxvalues = [params.max_total_flow[DateTime(t),plant,p2] for t in run.date_TIME]
                            hover_text=[dt * ": " * string(round(val, digits=2)) for (dt, val) in zip(hourly_datetimes, maxvalues)]
                            plot!(totalflowplot, hourly_datetimes, maxvalues,
                                color = scenario_colors[i], label = "$(scenario) - Max. $plant to $p2", lw = 1, la=0.8, ls = :dash, hover=hover_text)
                        end
                end
            end
        end
    end

    figurefolder = "$folder/figures"
    isdir(figurefolder) || mkdir(figurefolder)

    if power
        if display_plots
            display(plantpowerplot)
            display(plantPDCplot)
        end

        profit_values = [profits[sc] for sc in scenarios]
        total_production_values = [total_productions[sc] for sc in scenarios]
        captured_price_values = [captured_prices[sc] for sc in scenarios]

        name = repeat([""], outer=nr_scenarios)
        ctg = repeat(scenarios, inner=1) |> CategoricalArray
        levels!(ctg, scenarios)
        col = repeat(scenario_colors[1:nr_scenarios], outer=1)

        hover_text1 = [string(round(val, digits=2)) for val in profit_values]
        hover_text2 = [string(round(val.*1000, digits=2)) for val in total_production_values]
        hover_text3 = [string(round(val, digits=2)) for val in captured_price_values]

        p = groupedbar(name, profit_values, group=ctg, color = col, lw=0, hover=hover_text1,
                title = "Intäkt - $(plant)", xlabel = "", ylabel = "[MSEK]"; barplotsettings..., legend=:outerbottomright, show=display_plots, size=(650, 450))
        tp = groupedbar(name, total_production_values.*1000, group=ctg, color = col, lw=0, hover=hover_text2,
                title = "Total produktion - $(plant)", xlabel = "", ylabel = "[GWh]"; barplotsettings..., legend=:outerbottomright, show=display_plots, size=(650, 450))
        cp = groupedbar(name, captured_price_values, group=ctg, color = col, lw=0, hover=hover_text3,
                title = "Medelintäkt - $(plant)", xlabel = "", ylabel = "[SEK/MWh]"; barplotsettings..., legend=:outerbottomright, show=display_plots, size=(650, 450))

                savefig(plantpowerplot, "$figurefolder/$(plant)_powerprod_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
                savefig(plantPDCplot, "$figurefolder/$(plant)_PDC_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime)_PDC.html")
                savefig(p, "$figurefolder/$(plant)_profit_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
                savefig(tp, "$figurefolder/$(plant)_totalproduction_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
                savefig(cp, "$figurefolder/$(plant)_capturedprice_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")

                plots_dict["Produktionsprofil"] = "$figurefolder/$(plant)_powerprod_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html"
                plots_dict["Ordnad produktion"] = "$figurefolder/$(plant)_PDC_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime)_PDC.html"
                plots_dict["Intäkt"] = "$figurefolder/$(plant)_profit_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html"
                plots_dict["Total produktion"] = "$figurefolder/$(plant)_totalproduction_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html"
                plots_dict["Medelintäkt"] = "$figurefolder/$(plant)_capturedprice_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html"
            end

    if level
        if display_plots
            display(reservoircontentplot)
            display(forebayplot)
            plant in PPLANT && display(tailplot)
        end
        savefig(reservoircontentplot, "$figurefolder/$(plant)_reservoircontent_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        savefig(forebayplot, "$figurefolder/$(plant)_forebay_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        plant in PPLANT && savefig(tailplot, "$figurefolder/$(plant)_tail_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")

        plots_dict["Magasinsinnehåll"] = "$figurefolder/$(plant)_reservoircontent_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html"
        plots_dict["Övre vattenyta"] = "$figurefolder/$(plant)_forebay_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html"
        plant in PPLANT && (plots_dict["Nedre vattenyta"] = "$figurefolder/$(plant)_tail_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
    end

    if flow
        if display_plots
            (plant in PPLANT) && display(dischargeplot)
            plotpassage && display(passageflowplot)
            plotdrybed && display(drybedflowplot)
            plotutskov && display(utskovflowplot)
            display(totalflowplot)
        end
        plant in PPLANT && savefig(dischargeplot, "$figurefolder/$(plant)_discharge_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        plotpassage && savefig(passageflowplot, "$figurefolder/$(plant)_passageflow_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        plotdrybed && savefig(drybedflowplot, "$figurefolder/$(plant)_drybedflow_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        plotutskov && savefig(utskovflowplot, "$figurefolder/$(plant)_utskovflow_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        savefig(totalflowplot, "$figurefolder/$(plant)_totalflow_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")

        plant in PPLANT && (plots_dict["Flöde till turbiner"] = "$figurefolder/$(plant)_discharge_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        plotpassage && (plots_dict["Flöde i passagelösning"] = "$figurefolder/$(plant)_passageflow_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        plotdrybed && (plots_dict["Flöde i torrfåra"] = "$figurefolder/$(plant)_drybedflow_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        plotutskov && (plots_dict["Flöde i utskov"] = "$figurefolder/$(plant)_utskovflow_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html")
        plots_dict["Totalt flöde"] = "$figurefolder/$(plant)_totalflow_$(scenariostring)_$(obj)_$(model)_$(start_datetime)-$(end_datetime).html"
    end

    return plots_dict
end


function readresults(paths, obj, model, start_datetime, end_datetime)

    runs = listruns(paths, obj, model, start_datetime, end_datetime)
    rundata = NamedTuple[]

    for (path, filename, name, start_datetime, end_datetime, objective, model_type, scenario) in runs
            profit,                     # Float64
            power_turbines,             # OrderedCollections.OrderedDict{Tuple{DateTime, Symbol, Int64}, Float64}
            res_cont,                   # Matrix{Float64}
            t_level,                    # Matrix{Float64}
            f_level,                    # Matrix{Float64}
            #hd,                        # Matrix{Float64}
            discharge,                  # OrderedCollections.OrderedDict{Tuple{DateTime, Symbol, Int64}, Float64}
            passage_flow,               # OrderedCollections.OrderedDict{Tuple{DateTime, Symbol, Symbol}, Float64}
            drybed_flow,                # OrderedCollections.OrderedDict{Tuple{DateTime, Symbol, Symbol}, Float64}
            utskov_flow,                # OrderedCollections.OrderedDict{Tuple{DateTime, Symbol, Symbol}, Float64}
            total_flow,                 # OrderedCollections.OrderedDict{Tuple{DateTime, Symbol, Symbol}, Float64}
            PLANT,                      # Vector{Symbol}
            PPLANT,                     # Vector{Symbol}
            TURBINE,                    # Dict{Symbol, Vector{Int64}}
            date_TIME,                  # Vector{DateTime}
            downstream,                 # Dict{Symbol, Array{Symbol}}
            discharge_downstream,       # Dict{Symbol, Symbol}
            passage_downstream,         # Dict{Symbol, Array{Symbol}}
            drybed_downstream,          # Dict{Symbol, Array{Symbol}}
            utskov_downstream,          # Dict{Symbol, Array{Symbol}}
            spot_price =                # Dict{Int64, Float64}
                    load("$path/$filename", "profit", "power_production", "reservoir_content", "t_level", "f_level", "discharge", "passage_flow", "drybed_flow", "utskov_flow", "total_flow",
                    "PLANT", "PPLANT", "TURBINE", "date_TIME", "downstream", "discharge_downstream", "passage_downstream", "drybed_downstream", "utskov_downstream", "spot_price")

            reservoir_content, tail_level, forebay_level, head = (Dict() for _ in 1:4)

            [reservoir_content[t,p] = res_cont[a,b] for (a,t) in enumerate(date_TIME), (b,p) in enumerate(PLANT)]
            [forebay_level[t,p] = f_level[a,b] for (a,t) in enumerate(date_TIME), (b,p) in enumerate(PLANT)]
            [tail_level[t,p] = t_level[a,b] for (a,t) in enumerate(date_TIME), (b,p) in enumerate(PPLANT)]
            #[head[t,p] = hd[a,b] for (a,t) in enumerate(date_TIME), (b,p) in enumerate(PPLANT)]

            push!(rundata, (; name, start_datetime, end_datetime, objective, model_type, scenario,
                  profit, power_turbines, reservoir_content, tail_level, forebay_level, discharge, passage_flow, drybed_flow, utskov_flow, total_flow,
                  PLANT, PPLANT, TURBINE, date_TIME, downstream, discharge_downstream, passage_downstream, drybed_downstream, utskov_downstream, spot_price))
    end

    return rundata
end


function listruns(paths::Vector{String}, obj::String, model::String, start_datetime::String, end_datetime::String)

    files = []

    for p in paths

        dir_files = readdir(p)

        for file in dir_files
            match = Base.match(r"((\d{4}-\d{2}-\d{2}T\d{2}) to (\d{4}-\d{2}-\d{2}T\d{2}) (Profit|Load) (Linear|NonLinear) (.+).jld2)", file) #(Profit|Load) #(.+))(\.\w+)$
            if match !== nothing
                full_match, start_date_str, end_date_str, objective, model_type, scenario = match.captures

                if (start_datetime == start_date_str) && (end_datetime == end_date_str) && objective == obj && model_type == model

                    file_info = (
                        path = p,
                        filename = file,
                        name = replace(file, r"\.\w+$" => ""),  # Remove file extension if present
                        start_datetime = start_datetime,
                        end_datetime = end_datetime,
                        objective = objective,
                        model_type = model_type,
                        scenario = scenario,
                    )
                    push!(files, file_info)
                end
            end
        end
    end

    return files   # Vector of NamedTuples (filename, name, start_datetime, end_datetime, model_type, scenario)
end

function generate_hourly_datetimes(start_datetime::String, end_datetime::String)
    start_dt = DateTime(start_datetime)
    end_dt = DateTime(end_datetime)

    hourly_datetimes = collect(start_dt:Hour(1):end_dt)
    xtick_dates = [dt for dt in hourly_datetimes if day(dt) == 1 && hour(dt) == 0]
    xtick_indexes = findall(dt -> day(dt) == 1 && hour(dt) == 0, hourly_datetimes)

    return [Dates.format(dt, "yyyy-mm-ddTHH") for dt in hourly_datetimes], [Dates.format(dt, "yyyy-mm-dd") for dt in xtick_dates], xtick_indexes
end