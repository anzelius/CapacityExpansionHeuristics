using JLD2, Dates

export establish_res_boundary_conditions

function establish_res_boundary_conditions(river)

println("\nEstablishing weekly average reservoir levels for 2016-2020 for $river ...")


plants, etapoints, set_environmental_constraints! = riverdata(river)
plantinfo = Dict(p.name => p for p in plants)
PLANT = [p.name for p in plants]

vars = load("$DATAFOLDER/$river/$river"*"_rawdata.jld2")
    @unpack hours, forebay_level = vars

##### Data cleaning:  #####

# Replace all negative waterlevel values with last ok value
for (i,p) in enumerate(PLANT)
    up = @view forebay_level[:, i]
    quick_clean!(up, mean(up[up.>0]))
end

# Clean forebay level data (all values more than 10cm outside of reservoir limits are replaced with previous ok value)
for (i,p) in enumerate(PLANT)
    fb = @view forebay_level[:, i]
    last_ok = mean(fb[fb.>0])       # take average if the first value needs to be replaced
    for (j, q) in enumerate(fb)
        if q < plantinfo[p].reservoirlow-0.1 || q > plantinfo[p].reservoirhigh+0.1
            forebay_level[j, i] = last_ok
        else
            last_ok = q
        end
    end
end

# Clean forebay level data (all values outside of reservoir limits are replaced with max or min value)

for (i,p) in enumerate(PLANT)
    fb = @view forebay_level[:, i]
    for (j, q) in enumerate(fb)
        if q < plantinfo[p].reservoirlow
            forebay_level[j, i] = plantinfo[p].reservoirlow
        elseif q > plantinfo[p].reservoirhigh
            forebay_level[j, i] = plantinfo[p].reservoirhigh
        end
    end
end

year = Dates.year.(hours)
week = Dates.week.(hours)

hist_level = Dict{Tuple{Int64, Int64, Symbol}, Float64}()

for (n,p) in enumerate(PLANT), yr in 2016:2020, w in 1:53
    i = (year .== yr) .& (week .== w)
    hist_level[w,yr,p] = mean(forebay_level[i,n])
end

println("\nReading to file...")
    jldsave("$DATAFOLDER/$river/$river"*"_res_BC.jld2"; hist_level, compress=true)
    nothing
end