function flow_constraints!(type::String, pathway::String, stretch::Tuple{Symbol, Symbol},
    fromdate::String, todate::String, fromtime::Int, totime::Int, value,
    flow_params)

    @unpack date_TIME, PLANT, PPLANT, RES, Q, acc_upstream_inflow, downstream, passage_downstream, drybed_downstream, utskov_downstream,
    max_total_flow, min_total_flow, ramp_up_total_flow, ramp_down_total_flow,
    max_passage_flow, min_passage_flow, ramp_up_passage_flow, ramp_down_passage_flow,
    max_drybed_flow, min_drybed_flow, ramp_up_drybed_flow, ramp_down_drybed_flow,
    max_utskov_flow, min_utskov_flow, ramp_up_utskov_flow, ramp_down_utskov_flow, connectioninfo = flow_params

    chosen_datetimes = filter_datetimes(date_TIME, fromdate, todate, fromtime, totime)

    if typeof(value) == String
        m = match(r"([A-Z]{2,3})(\d+)", value)
        n = match(r"^Tillrinning(1[0-9]{2}|[1-9][0-9]?)$", value)
        if m !== nothing
            Q_letters = m.captures[1]
            Qnames = filter(x -> x != "Plant", names(Q))
            if Q_letters in Qnames
                number = parse(Int, m.captures[2])
                value_dict = Dict(t => (number/100)*Q[Q.Plant .== String(stretch[1]), Q_letters][1] for t in chosen_datetimes)
            else
                error("$Qletter is not a valid flow metric")
            end
        elseif n !== nothing
            number = parse(Int, n.captures[1])
            value_dict = Dict(t => (number/100)*acc_upstream_inflow[t, stretch[1]] for t in chosen_datetimes)
        else
            error("$value is not a valid value for flow constraints")
        end
    elseif typeof(value) == Float64 || typeof(value) == Int
        value_dict = Dict(t => value for t in chosen_datetimes)
    else
        error("$value is not a valid value for flow constraints")
    end

    if pathway == "total"
        if stretch[2] ∉ downstream[stretch[1]]
            error("There is no direct flow connection between $(stretch[1]) and $(stretch[2])")
        end
    elseif pathway == "passage"
        if stretch[2] ∉ passage_downstream[stretch[1]]
            @warn("Made a new passage connection between $(stretch[1]) and $(stretch[2])")
            passage_downstream[stretch[1]] = [stretch[2]]
            up_vector = connectioninfo[stretch[2]].upstream
            up_index = findfirst(u -> u.name == stretch[1], up_vector)
            up = up_vector[up_index]
            println(up)
            println("Delaytime is $(up.passagedelay)")
            up.passagedelay = up.utskovdelay
            println("Delaytime has been updated to $(up.passagedelay)")
            for t in date_TIME
                min_passage_flow[t,stretch[1],stretch[2]] = 0.0
                max_passage_flow[t,stretch[1],stretch[2]] = NaN
                ramp_up_passage_flow[t,stretch[1],stretch[2]] = 1e4
                ramp_down_passage_flow[t,stretch[1],stretch[2]] = 1e4
            end
        end
    elseif pathway == "drybed"
        if stretch[2] ∉ drybed_downstream[stretch[1]]
            error("There is no drybed connection between $(stretch[1]) to $(stretch[2])")
        end
    elseif pathway == "utskov"
        if stretch[2] ∉ utskov_downstream[stretch[1]]
            error("There is no utskov connection between $(stretch[1]) to $(stretch[2])")
        end
    else
        error("$(pathway) is not a valid pathway")
    end

    if type == "max"
        if pathway == "total"
            [max_total_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "passage"
            [max_passage_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "drybed"
            [max_drybed_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "utskov"
            [max_utskov_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        end
    elseif type == "min"
        if pathway == "total"
            [min_total_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "passage"
            [min_passage_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "drybed"
            [min_drybed_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "utskov"
            [min_utskov_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        end
    elseif type == "ramp_up"
        if pathway == "total"
            [ramp_up_total_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "passage"
            [ramp_up_passage_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "drybed"
            [ramp_up_drybed_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "utskov"
            [ramp_up_utskov_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        end
    elseif type == "ramp_down"
        if pathway == "total"
            [ramp_down_total_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "passage"
            [ramp_down_passage_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "drybed"
            [ramp_down_drybed_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        elseif pathway == "utskov"
            [ramp_down_utskov_flow[t, stretch[1], stretch[2]] = value_dict[t] for t in chosen_datetimes]
        end
    else
        error("$(type) is not a valid type")
    end

end

function level_constraints!(type::String, surface::String, plant::Symbol,
    fromdate::String, todate::String, fromtime::Int, totime::Int, value,
    level_params)

    @unpack date_TIME, min_level, max_level, ramp_up_level, ramp_down_level = level_params

    chosen_datetimes = filter_datetimes(date_TIME, fromdate, todate, fromtime, totime)

    if surface ∉ ["forebay", "tail"]
        error("$(surface) is not a valid surface")
    end

    if type == "max"
        if surface == "forebay"
            [max_level[t, plant, :forebay] = value for t in chosen_datetimes]
        elseif surface == "tail"
            [max_level[t, plant, :tail] = value for t in chosen_datetimes]
        end
    elseif type == "min"
        if surface == "forebay"
            [min_level[t, plant, :forebay] = value for t in chosen_datetimes]
        elseif surface == "tail"
            [min_level[t, plant, :tail] = value for t in chosen_datetimes]
        end
    elseif type == "ramp_up"
        if surface == "forebay"
            [ramp_up_level[t, plant, :forebay] = value for t in chosen_datetimes]
        elseif surface == "tail"
            [ramp_up_level[t, plant, :tail] = value for t in chosen_datetimes]
        end
    elseif type == "ramp_down"
        if surface == "forebay"
            [ramp_down_level[t, plant, :forebay] = value for t in chosen_datetimes]
        elseif surface == "tail"
            [ramp_down_level[t, plant, :tail] = value for t in chosen_datetimes]
        end
    else
        error("$(type) is not a valid type")
    end
end

function reservoir_limit_change!(plant::Symbol, fromdate::String, todate::String, initial_level::Float64, level_increase_per_day::Float64, level_params)
    @unpack date_TIME, min_level, max_level = level_params

    maxmin="max"

    from_month, from_day = parse(Int, fromdate[1:2]), parse(Int, fromdate[4:5])
    to_month, to_day = parse(Int, todate[1:2]), parse(Int, todate[4:5])
    if (from_month > to_month) || (from_month == to_month && from_day > to_day)
        error("Invalid date range: fromdate must be before todate")
    end

    # Initialize increment and current year tracker
    increment = 0
    current_year = year(date_TIME[1])  # Start with the first year in date_TIME

    if maxmin ∉ ["max", "min"]
        error("$(maxmin) is not a valid value for maxmin")
    end

    # Loop through each DateTime in date_TIME to check and update levels
    for dt in date_TIME
        # Reset increment and set first_day_complete to false if a new year starts
        if year(dt) != current_year
            increment = 0
            current_year = year(dt)
        end
        # Update levels if `dt` is in the specified date range
        if is_in_date_range(dt, fromdate, todate)
            if maxmin == "max"
                max_level[(dt, plant, :forebay)] = initial_level + level_increase_per_day * increment
            elseif maxmin == "min"
                min_level[(dt, plant, :forebay)] = initial_level + level_increase_per_day * increment
            else
                println("maxmin= ", maxmin)
                error("Invalid maxmin value: must be either 'max' or 'min'")
            end
            # Only start incrementing on the second day at midnight (00:00)
            if Time(dt) == Time(23, 0)
                increment += 1
            end
        end
    end
end

function filter_datetimes(date_TIME::Vector{DateTime}, start_date::String, end_date::String, start_hour::Int, end_hour::Int)
    # Parse the start and end dates for month and day
    start_month, start_day = parse(Int, start_date[1:2]), parse(Int, start_date[4:5])
    end_month, end_day = parse(Int, end_date[1:2]), parse(Int, end_date[4:5])

    # Define the time range
    start_time = Time(start_hour, 0)
    end_time = Time(end_hour, 0)

    # Filter `date_TIME` based on date and time conditions
    filtered_datetimes = [
        dt for dt in date_TIME if
        (start_time <= Time(dt) <= end_time) &&
        (
            # Case 1: Non-wrap-around range within the same month
            (start_month == end_month && start_day <= day(dt) <= end_day && month(dt) == start_month) ||

            # Case 2: Non-wrap-around range across different months
            (start_month < end_month &&
                ((month(dt) == start_month && day(dt) >= start_day) ||
                (month(dt) == end_month && day(dt) <= end_day) ||
                (month(dt) > start_month && month(dt) < end_month))) ||

            # Case 3: Wrap-around range (e.g., Dec 30 to Feb 5)
            (start_month > end_month &&
                ((month(dt) == start_month && day(dt) >= start_day) ||
                (month(dt) == end_month && day(dt) <= end_day) ||
                (month(dt) > start_month || month(dt) < end_month)))
        )
    ]

    return filtered_datetimes
end

# Define date range filter
function is_in_date_range(dt::DateTime, fromdate, todate)
    # Parse `fromdate` and `todate` for month-day boundaries
    start_month, start_day = parse(Int, fromdate[1:2]), parse(Int, fromdate[4:5])
    end_month, end_day = parse(Int, todate[1:2]), parse(Int, todate[4:5])

    (start_month < end_month &&
        ((month(dt) == start_month && day(dt) >= start_day) ||
            (month(dt) == end_month && day(dt) <= end_day) ||
            (month(dt) > start_month && month(dt) < end_month))) ||
    (start_month > end_month &&
        ((month(dt) == start_month && day(dt) >= start_day) ||
            (month(dt) == end_month && day(dt) <= end_day) ||
            (month(dt) > start_month || month(dt) < end_month))) ||
    (start_month == end_month && start_day <= day(dt) <= end_day && month(dt) == start_month)
end