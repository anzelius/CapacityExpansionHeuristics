using JLD2, Dates, DataFrames

export establish_Q

function establish_Q(river)

println("\nEstablishing HHQ, MHQ, LHQ, MQ, HLQ, MLQ, LLQ for $river")
println("\n This is only requiered to be done first time each river is runned, since these parameters are saved to a file for later use.")
println("\n OBS: if the inflow data has been updated, and you want to update the Qmetrics, remove the old Qmetrics file and a new will be created with the new inflow data once the river is runned.")

plants = NETWORK[river]
PLANT = [p.name for p in plants[1:end-1]] # Don't include the last plant as it is the Hav
connections = NETWORK[river]
connectioninfo = Dict(c.name => c for c in connections)

println("\n -- Reading inflow data")
@time inflow_df = DataFrame(XLSX.readtable("$DATAFOLDER/$river/$(river)_inflow.xlsx", "Sheet1"))

days = inflow_df.Date
year = Dates.year.(days)
YEAR = string.(unique(year))
DAYS = 1:length(days)

inflow = Dict{Tuple{Int, Symbol}, Float64}()

for (i,row) in enumerate(eachrow(inflow_df))
    for plant in names(inflow_df)[2:end]  # Skip the Date column
        inflow[(i, Symbol(plant))] = max(row[plant], 0.0)
    end
end

println("\n The Q metrics are now beeing calculated based on the provided inflow data between $(YEAR[1]) and $(YEAR[end]) ...")

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

all_acc_upstream_inflow = @aa fill(-Inf, length(DAYS), length(PLANT)), DAYS, PLANT

for p in PLANT
    [all_acc_upstream_inflow[d,p] = sum(inflow[shift(DAYS, d-delay_between(p, pl)),pl]
                                    for pl in vcat(p, allupstream(p))) for d in DAYS]
end

HQ_year = @aa fill(-Inf, length(YEAR), length(PLANT)), YEAR, PLANT
LQ_year = @aa fill(-Inf, length(YEAR), length(PLANT)), YEAR, PLANT

HHQ = @aa fill(-Inf, length(PLANT)), PLANT
MHQ = @aa fill(-Inf, length(PLANT)), PLANT
LHQ = @aa fill(-Inf, length(PLANT)), PLANT
MQ  = @aa fill(-Inf, length(PLANT)), PLANT
HLQ = @aa fill(-Inf, length(PLANT)), PLANT
MLQ = @aa fill(-Inf, length(PLANT)), PLANT
LLQ = @aa fill(-Inf, length(PLANT)), PLANT

for p in PLANT, yr in YEAR
    i = (string.(year) .== yr)
    HQ_year[yr,p] = quantile(all_acc_upstream_inflow[i,p], 0.99)
    LQ_year[yr,p] = quantile(all_acc_upstream_inflow[i,p], 0.01)
end

[HHQ[p] = maximum(HQ_year[:,p]) for p in PLANT]
[MHQ[p] = mean(HQ_year[:,p]) for p in PLANT]
[LHQ[p] = minimum(HQ_year[:,p]) for p in PLANT]
[MQ[p] = mean(all_acc_upstream_inflow[:,p]) for p in PLANT]
[HLQ[p] = maximum(LQ_year[:,p]) for p in PLANT]
[MLQ[p] = mean(LQ_year[:,p]) for p in PLANT]
[LLQ[p] = minimum(LQ_year[:,p]) for p in PLANT]

# Create an empty DataFrame
df = DataFrame(Plant = String.(PLANT))

# Add columns for each parameter
df.HHQ = HHQ
df.MHQ = MHQ
df.LHQ = LHQ
df.MQ = MQ
df.HLQ = HLQ
df.MLQ = MLQ
df.LLQ = LLQ

# Print the DataFrame
println(df)

println("\nReading to file...")
    XLSX.writetable("$DATAFOLDER/$river/Qmetrics.xlsx", df)
    nothing
end