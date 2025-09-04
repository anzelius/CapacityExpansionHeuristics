include("model/constants.jl")
#include("model/FORSA.jl") 
include("identify expansions/identify_expansions.jl")
include("ordering/get_order_expansions.jl")
include("runners/run_model.jl")


###################################
# Parameters 
###################################
river = :All  # [:All, :Dalälven, :Götaälv, :Indalsälven, :Ljungan, :Ljusnan, :Luleälven, :Skellefteälven, :Umeälven, :Ångermanälven]
start_datetime = "2016-01-01T08" 
end_datetime = "2016-01-30T08"  
objective = "Profit"
model = "Linear" 
environmental_constraints_scenario = "Dagens miljövillkor"  # ['Dagens miljövillkor', 'Inga miljövillkor'] 

expansion_strategy = "Match flow"  # ['None', 'Bottlenecks', 'Match flow', 'New bottlenecks', 'Match flow bottlenecks'] 
order_metric = :dDxuD  # [:HxD, :dDxuD, (:TopFirst)]
strict_order = true 
order_grouping = :step  # [:percentile, :step] 
order_basis = :aggregated  # [:river, :aggregated]  
settings = (percentile = 10:10:100, step_size = 10, flow_match="MHQ", flow_scale=0.75, top_plant_scale=1.5, price_factor=0.8, peak_date="2016-01-02T08")

theoretical = false 
price_profile_scenario = :none  # [:none, (:dunkelflaute), :peak, :volatility, (:extended)] 

save_file_name = "" 
save_variables = false
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

    # TODO: saving and printing results 
    # save results to csv file 
    # print basic aggregated results 
    # save aggregated results to fie 
end 

initialize_run(river, start_datetime, end_datetime, 
    objective, model, environmental_constraints_scenario,
    expansion_strategy, order_metric, strict_order, order_grouping, 
    order_basis, settings)