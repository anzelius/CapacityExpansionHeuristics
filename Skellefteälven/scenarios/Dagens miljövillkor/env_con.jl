
    ENVCON[:Skellefteälven, "Dagens miljövillkor"] = function (flow_params, level_params)

        flow_constraints!("min", "utskov", (:Sädva, :Hornavan), "01-01", "12-31", 0, 23, 2.6, flow_params)

        flow_constraints!("min", "utskov", (:Hornavan, :Bergnäs), "01-01", "04-30", 0, 23, 20, flow_params)
        flow_constraints!("min", "utskov", (:Hornavan, :Bergnäs), "05-15", "05-31", 0, 23, 25, flow_params)
        flow_constraints!("min", "utskov", (:Hornavan, :Bergnäs), "06-01", "08-14", 0, 23, 50, flow_params)
        flow_constraints!("min", "utskov", (:Hornavan, :Bergnäs), "08-15", "08-31", 0, 23, 25, flow_params)
        flow_constraints!("min", "utskov", (:Hornavan, :Bergnäs), "09-01", "12-31", 0, 23, 20, flow_params)
        level_constraints!("min", "forebay", :Hornavan, "06-23", "08-15", 0, 23, 424.10, level_params)

        flow_constraints!("min", "utskov", (:Bergnäs, :Slagnäs), "01-01", "05-14", 0, 23, 15, flow_params)
        flow_constraints!("min", "utskov", (:Bergnäs, :Slagnäs), "05-15", "05-31", 0, 23, 25, flow_params)
        flow_constraints!("min", "utskov", (:Bergnäs, :Slagnäs), "06-01", "06-14", 0, 23, 35, flow_params)
        flow_constraints!("min", "utskov", (:Bergnäs, :Slagnäs), "06-15", "07-31", 0, 23, 45, flow_params)
        flow_constraints!("min", "utskov", (:Bergnäs, :Slagnäs), "08-01", "08-14", 0, 23, 35, flow_params)
        flow_constraints!("min", "utskov", (:Bergnäs, :Slagnäs), "08-15", "08-31", 0, 23, 25, flow_params)
        flow_constraints!("min", "utskov", (:Bergnäs, :Slagnäs), "09-01", "12-31", 0, 23, 15, flow_params)

        flow_constraints!("min", "utskov", (:Slagnäs, :Bastusel), "01-01", "04-30", 0, 23, 15, flow_params)
        flow_constraints!("min", "utskov", (:Slagnäs, :Bastusel), "05-15", "05-31", 0, 23, 25, flow_params)
        flow_constraints!("min", "utskov", (:Slagnäs, :Bastusel), "06-01", "08-14", 0, 23, 35, flow_params)
        flow_constraints!("min", "utskov", (:Slagnäs, :Bastusel), "08-15", "08-31", 0, 23, 25, flow_params)
        flow_constraints!("min", "utskov", (:Slagnäs, :Bastusel), "09-01", "12-31", 0, 23, 15, flow_params)

        level_constraints!("min", "forebay", :Båtfors, "06-01", "08-15", 0, 23, 161.0, level_params)
        level_constraints!("min", "forebay", :Finnfors, "06-01", "08-15", 0, 23, 143.7, level_params)
        level_constraints!("min", "forebay", :Granfors, "06-01", "08-15", 0, 23, 123.0, level_params)
        level_constraints!("min", "forebay", :Selsfors, "06-01", "08-15", 0, 23, 74.1, level_params)

        flow_constraints!("min", "utskov", (:Kvistforsen, :Bergsby), "01-01", "12-31", 0, 23, 20, flow_params)
        flow_constraints!("min", "utskov", (:Bergsby, :Hav), "01-01", "12-31", 0, 23, 10, flow_params)

        flow_constraints!("ramp_up", "total", (:Hornavan, :Bergnäs), "12-01", "12-31", 0, 23, 5/24, flow_params)
        flow_constraints!("ramp_up", "total", (:Hornavan, :Bergnäs), "01-01", "04-30", 0, 23, 5/24, flow_params)
        flow_constraints!("ramp_down", "total", (:Hornavan, :Bergnäs), "12-01", "12-31", 0, 23, 20/24, flow_params)
        flow_constraints!("ramp_down", "total", (:Hornavan, :Bergnäs), "01-01", "04-30", 0, 23, 20/24, flow_params)

        flow_constraints!("ramp_up", "total", (:Bergnäs, :Slagnäs), "01-01", "12-31", 0, 23, 50/24, flow_params)
        flow_constraints!("ramp_down", "total", (:Bergnäs, :Slagnäs), "01-01", "12-31", 0, 23, 50/24, flow_params)

    end