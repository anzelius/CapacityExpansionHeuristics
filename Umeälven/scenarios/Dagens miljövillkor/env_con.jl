
    ENVCON[:Umeälven, "Dagens miljövillkor"] = function (flow_params, level_params)

        flow_constraints!("min", "total", (:Gejmån, :Björkvattnet), "06-01", "08-31", 0, 23, 0.23, flow_params)
        flow_constraints!("min", "total", (:Harrsele, :Pengfors), "04-01", "11-30", 0, 23, 0.1, flow_params)
        flow_constraints!("min", "total", (:Harrsele, :Pengfors), "08-01", "09-30", 0, 23, 0.2, flow_params)
        flow_constraints!("min", "total", (:Stornorrfors, :Hav), "05-20", "06-15", 0, 23, 10, flow_params)
        flow_constraints!("min", "total", (:Stornorrfors, :Hav), "06-16", "08-31", 0, 23, 29.10, flow_params)
        flow_constraints!("min", "total", (:Stornorrfors, :Hav), "09-01", "09-30", 0, 23, 22.90, flow_params)

        flow_constraints!("min", "utskov", (:Juktan, :Rusfors), "01-01", "12-31", 0, 23, 3, flow_params)
        flow_constraints!("min", "utskov", (:Juktan, :Rusfors), "04-23", "04-30", 0, 23, 6, flow_params)
        flow_constraints!("min", "utskov", (:Juktan, :Rusfors), "06-02", "10-15", 0, 23, 5, flow_params)

        level_constraints!("min", "forebay", :Umluspen, "06-15", "08-31", 0, 23, 351.0, level_params)

    end