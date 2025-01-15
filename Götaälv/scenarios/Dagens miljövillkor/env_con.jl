ENVCON[:Götaälv, "Dagens miljövillkor"] = function (flow_params, level_params)
    flow_constraints!("min", "passage", (:Krakerud, :Forshult), "03-12", "05-12", 0, 23, 2.0, flow_params)
end