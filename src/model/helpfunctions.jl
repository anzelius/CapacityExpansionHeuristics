
shift(v, t) = v[mod1(t - v[1] + 1, length(v))]

function dtshift(date_TIME::Vector{DateTime}, specified_datetime::DateTime, hours_before::Int)
    # Find the index of the specified DateTime
    idx = findfirst(x -> x == specified_datetime, date_TIME)
    
    # Check if the index exists
    if idx !== nothing
        # Calculate the wrapped-around index
        wrapped_index = mod1(idx - hours_before, length(date_TIME))
        return date_TIME[wrapped_index]
    else
        return nothing  # Return `nothing` if specified_datetime is not found in date_TIME
    end
end

function check_sheet_exists(filename::String, sheet_name::String) :: Bool
    # Open the Excel file in read mode
    XLSX.openxlsx(filename, mode="r") do workbook
        # Check if the sheet name exists in the workbook's sheet names
        return sheet_name in XLSX.sheetnames(workbook)
    end
end

sumdrop(x; dims) = (dims > ndims(x)) ? x : dropdims(sum(x; dims); dims)

lookup(dict, keys::AbstractArray) = getindex.(Ref(dict), keys)

function generate_quadratic(h::Union{Int, Float64}, k::Float64, x1::Union{Int, Float64})
    # h is the x-coordinate of the vertex, k is the y-coordinate of the vertex, 
    # and x1 is the x-coordinate of one of the x-intercept
    # Calculate 'a' using the vertex form: f(x) = a(x - h)^2 + k
    # At the x-intercept (x1, 0), the function value should be 0
    a = -k / ((h - x1)^2)  # Negative a to ensure the parabola opens downwards

    # Return the quadratic function
    return x -> a * (x - h)^2 + k
end

function positivequantile(x::AbstractVector, q)
    f = (x .> 0)
    return any(f) ? quantile(x[f], q) : (q isa Vector) ? fill(-Inf, length(q)) : -Inf
end

function is_between(start, stop, dt::DateTime)
    yr = year(dt)
    h = hour(dt)
    start_datetime = DateTime(yr, start[1], start[2], start[3])
    stop_datetime = DateTime(yr, stop[1], stop[2], stop[3])
    range = start_datetime:Hour(1):stop_datetime
    return dt in range && (start[3] <= h <= stop[3]) 
end

function timerange(start, stop, date_TIME)
    valid_hours = BitVector([is_between(start, stop, dt) for dt in date_TIME])
    return valid_hours
end

function quick_clean!(vect, avg; forbid_zero=true)
    last_ok = avg
    for (i, e) in enumerate(vect)
        if e < 0 || (forbid_zero && e == 0)
            vect[i] = last_ok
        else
            last_ok = e
        end
    end
end



