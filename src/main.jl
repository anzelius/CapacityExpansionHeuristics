include("model/constants.jl")
#include("model/FORSA.jl") 
include("identify expansions/identify_expansions.jl")
include("ordering/get_order_expansions.jl")
include("runners/run_model.jl")


###################################
# Parameters 
###################################
river = :Skellefteälven  # [:All, :Dalälven, :Götaälv, :Indalsälven, :Ljungan, :Ljusnan, :Luleälven, :Skellefteälven, :Umeälven, :Ångermanälven]
start_datetime = "2016-01-01T08" 
end_datetime = "2016-01-30T08"  
objective = "Profit"
model = "Linear" 
environmental_constraints_scenario = "Dagens miljövillkor"  # ['Dagens miljövillkor', 'Inga miljövillkor'] 

expansion_strategy = "Match flow"  # ['None', 'Bottlenecks', 'Match flow', 'New bottlenecks', 'Match flow bottlenecks'] 
order_metric = :dDxuD  # [:HxD, :dDxuD, (:TopFirst)]
strict_order = true 
order_grouping = :percentile  # [:percentile, :step] 
order_basis = :aggregated  # [:river, :aggregated]  
settings = (percentile = 10:45:100, step_size = 10, flow_match="MHQ", flow_scale=0.75, top_plant_scale=1.5, price_factor=0.8, peak_date="2016-01-02T08")

theoretical = true 
price_profile_scenario = :none  # [:none, (:dunkelflaute), :peak, :volatility, (:extended)] 

save_file_name = "test" 
save_variables = false
save_csv = true
silent = true 


function initialize_run(river::Symbol, start_datetime::String, end_datetime::String, 
    objective::String, model::String, environmental_constraints_scenario::String,
    expansion_strategy::String, order_metric::Symbol, strict_order::Bool, order_grouping::Symbol, 
    order_basis::Symbol, settings::NamedTuple; 
    theoretical::Bool=false, price_profile_scenario::String="", save_file_name::String="",  
    recalc::NamedTuple=(;), save_variables=false, silent=true,
    )

    order_of_expansion = Vector{Dict{Symbol, Int32}}()
    if expansion_strategy != "None"
        plants_to_expand = Dict{Symbol, Vector{Dict{Symbol, Int32}}}()
        if river == :All
            _, plants_to_expand = identify_expansions_all_rivers(expansion_strategy, settings) 
        elseif river in rivers
            _, plants_to_expand_ = identify_expansions_one_river(river, expansion_strategy, settings) 
            plants_to_expand[river] = plants_to_expand_
        else
            @error("Invalid river")
        end 

        order_of_expansion = get_order_of_expansion(plants_to_expand, order_metric, strict_order, order_grouping, order_basis, settings) 
    end

    results = run_model(river, order_of_expansion, start_datetime, end_datetime, objective, model, environmental_constraints_scenario, 
    price_profile_scenario, theoretical, settings, save_file_name, recalc, save_variables, silent)  

    df = make_df(results) 
    println(df[df.Variable .!= "hourly_power", :])
    save_csv && CSV.write("$save_file_name.csv", df)
end 


# TODO: save results to csv file 
function make_df(results) 
    # Collect column and row names
    outer_keys = collect(keys(results))  # Column names
    inner_keys = collect(union([keys(v) for v in values(results)]...))  # Row names (includes "hourly_power")

    # Initialize DataFrame with row keys
    df = DataFrame(Variable = inner_keys)

    # Fill each column
    for col_key in outer_keys
        col_data = [get(get(results, col_key, Dict()), row_key, "") for row_key in inner_keys]
        df[!, col_key] = col_data
    end

    return df 
end 

function print_aggregated_results(results)
    outer_keys = collect(keys(results))          # column names
    # Row names (excluding "hourly_power")
    inner_keys = filter(k -> k != "hourly_power", union([keys(v) for v in values(results)]...))

    # Header
    println(rpad("", 10), join(rpad(k, 12) for k in outer_keys))

    # Rows
    for row_key in inner_keys
        row = rpad(row_key, 10)
        for col_key in outer_keys
            val = get(get(results, col_key, Dict()), row_key, "")
            row *= rpad(string(val), 12)
        end
        println(row)
    end
end 

initialize_run(river, start_datetime, end_datetime, 
    objective, model, environmental_constraints_scenario,
    expansion_strategy, order_metric, strict_order, order_grouping, 
    order_basis, settings)