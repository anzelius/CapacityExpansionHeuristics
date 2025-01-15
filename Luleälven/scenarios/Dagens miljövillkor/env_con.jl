
    ENVCON[:Luleälven, "Dagens miljövillkor"] = function (flow_params, level_params)

        flow_constraints!("min", "utskov", (:Ritsem, :Satisjaure), "01-01", "12-31", 0, 23, 2.6, flow_params)

    end