include("model/constants.jl")
include("identify expansions/identify_expansions.jl")
include("ordering/get_order_expansions.jl")
include("runners/run_model.jl")
include("output/output.jl")


###################################
# Parameters 
###################################
river = :All  # [:All, :Dalälven, :Götaälv, :Indalsälven, :Ljungan, :Ljusnan, :Luleälven, :Skellefteälven, :Umeälven, :Ångermanälven]
start_datetime = "2016-01-01T08" 
end_datetime = "2016-12-31T08"  
objective = "Profit"
model = "Linear" 
environmental_constraints_scenario = "Dagens miljövillkor"  # ['Dagens miljövillkor', 'Inga miljövillkor'] 

expansion_strategy = "Match flow"  # ['None', 'Bottlenecks', 'Match flow', 'New bottlenecks', 'Match flow bottlenecks'] 
order_metric = :HxD  # [:HxD, :dDxuD, (:TopFirst)]
strict_order = true 
order_grouping = :percentile  # [:percentile, :step] 
order_basis = :aggregated  # [:river, :aggregated]  
settings = (percentile = 6.66:6.66:100, step_size = 10, flow_match="LHQ", flow_scale=0.75, top_plant_scale=1.5, price_factor=1.1, peak_date="2016-01-02T08")

end_start_constraints = true  # false = theoretical, true = real  
price_profile_scenario = :volatility  # [:none, (:dunkelflaute), :peak, :volatility, (:extended)] 

save_file_name = "All 0.75LHQ HxD aggregated 2016 1yr"  
save_variables = false
save_csv = true
silent = true 


function initialize_run(river::Symbol, start_datetime::String, end_datetime::String, 
    objective::String, model::String, environmental_constraints_scenario::String,
    expansion_strategy::String, order_metric::Symbol, strict_order::Bool, order_grouping::Symbol, 
    order_basis::Symbol, settings::NamedTuple,
    end_start_constraints::Bool, price_profile_scenario::Symbol, save_file_name::String;  
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
    price_profile_scenario, end_start_constraints, settings, save_file_name, recalc, save_variables, silent)  

    df = make_df(results) 
    println(df[df.Variable .!= "hourly_power", :])
    save_csv && CSV.write("$(save_file_name).csv", df)
end 


initialize_run(river, start_datetime, end_datetime, 
    objective, model, environmental_constraints_scenario,
    expansion_strategy, order_metric, strict_order, order_grouping, 
    order_basis, settings, end_start_constraints, price_profile_scenario, save_file_name)