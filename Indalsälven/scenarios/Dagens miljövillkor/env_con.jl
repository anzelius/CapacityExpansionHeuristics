

ENVCON[:Indalsälven, "Dagens miljövillkor"] = function (flow_params, level_params)

    reservoir_limit_change!(:Anjan, "02-01", "04-10", 423.5, -0.05, level_params)
    reservoir_limit_change!(:Torrön, "02-01", "04-10", 417.5, -0.07, level_params)
    reservoir_limit_change!(:Juveln, "02-01", "04-10", 395.2, -0.05, level_params)
    reservoir_limit_change!(:Järpströmmen, "02-01", "04-10", 383.3, -0.015, level_params)
    reservoir_limit_change!(:Lillå, "02-01", "04-10", 324.4, -0.01/3, level_params)

    flow_constraints!("min", "utskov", (:Juveln, :Järpströmmen), "01-01", "04-30", 0, 23, 0.5, flow_params)
    flow_constraints!("min", "utskov", (:Juveln, :Järpströmmen), "05-01", "09-30", 0, 23, 1.5, flow_params)
    flow_constraints!("min", "utskov", (:Juveln, :Järpströmmen), "10-01", "12-31", 0, 23, 0.5, flow_params)

    flow_constraints!("min", "utskov", (:Slagsån, :Mörsil), "01-01", "12-31", 0, 23, 0.2, flow_params)

    level_constraints!("min", "forebay", :Ockesjön, "06-01", "10-31", 0, 23, 299.1, level_params)

    flow_constraints!("min", "utskov", (:Alsensjön, :Hissmofors), "05-01", "05-30", 18, 23, 0.5, flow_params)
    flow_constraints!("min", "utskov", (:Alsensjön, :Hissmofors), "05-02", "05-31", 0, 6, 0.5, flow_params)
    flow_constraints!("min", "utskov", (:Alsensjön, :Hissmofors), "08-15", "10-14", 18, 23, 1, flow_params)
    flow_constraints!("min", "utskov", (:Alsensjön, :Hissmofors), "08-16", "10-15", 0, 6, 1, flow_params)

    flow_constraints!("min", "utskov", (:Lillå, :Strömbacka), "01-01", "12-31", 0, 23, 0.5, flow_params)

    flow_constraints!("min", "utskov", (:Billsta, :Hissmofors), "01-01", "12-31", 0, 23, 0.5, flow_params)

    flow_constraints!("min", "utskov", (:Strömbacka, :Billsta), "01-01", "12-31", 0, 23, 0.5, flow_params)

    flow_constraints!("min", "total", (:Hissmofors, :Kattstrupeforsen), "01-01", "12-31", 0, 23, 50, flow_params)

    flow_constraints!("min", "total", (:Kattstrupeforsen, :Granboforsen), "01-01", "12-31", 0, 23, 50, flow_params)

    flow_constraints!("min", "total", (:Granboforsen, :Midskog), "01-01", "12-31", 0, 23, 50, flow_params)

    flow_constraints!("min", "utskov", (:Långså, :Rönnöfors), "01-01", "12-31", 0, 23, 1.1, flow_params)

    level_constraints!("max", "forebay", :Rönnöfors, "06-01", "09-30", 0, 23, 325.2, level_params)
    level_constraints!("min", "forebay", :Rönnöfors, "06-01", "09-30", 0, 23, 324.7, level_params)

    flow_constraints!("min", "utskov", (:Landösjön, :Midskog), "01-01", "12-31", 0, 23, 4.4, flow_params)
    flow_constraints!("min", "utskov", (:Landösjön, :Midskog), "06-01", "09-30", 0, 23, 15, flow_params)
    flow_constraints!("min", "utskov", (:Landösjön, :Midskog), "10-01", "12-31", 0, 23, 4.4, flow_params)

    flow_constraints!("min", "utskov", (:Kvarnfallet, :Näsaforsen), "01-01", "12-31", 0, 23, 0.1, flow_params)

    flow_constraints!("min", "total", (:Näsaforsen, :Högfors), "01-01", "12-31", 0, 23, 5, flow_params)

    flow_constraints!("min", "total", (:Högfors, :Midskog), "01-01", "12-31", 0, 23, 5, flow_params)

    flow_constraints!("min", "total", (:Midskog, :Näverede), "01-01", "12-31", 0, 23, 100, flow_params)

    level_constraints!("max", "forebay", :Krångede, "01-15", "02-28", 0, 23, 204.0, level_params)
    level_constraints!("max", "forebay", :Krångede, "03-01", "03-31", 0, 23, 203.5, level_params)
    level_constraints!("max", "forebay", :Krångede, "04-01", "04-14", 0, 23, 202.8, level_params)
    level_constraints!("max", "forebay", :Krångede, "04-15", "04-16", 0, 23, 202.3, level_params)
    flow_constraints!("min", "total", (:Krångede, :Gammelänge), "01-01", "12-31", 0, 23, 100, flow_params)

    flow_constraints!("min", "total", (:Gammelänge, :Hammarforsen), "01-01", "12-31", 0, 23, 100, flow_params)

    flow_constraints!("min", "total", (:Hammarforsen, :Svarthålsforsen), "01-01", "12-31", 0, 23, 70, flow_params)

    flow_constraints!("min", "total", (:Svarthålsforsen, :Stadsforsen), "01-01", "12-31", 0, 23, 50, flow_params)

    flow_constraints!("min", "total", (:Hölleforsen, :Järkvissle), "01-01", "12-31", 0, 23, 50, flow_params)

    flow_constraints!("min", "total", (:Järkvissle, :Bergeforsen), "01-01", "12-31", 0, 23, 50, flow_params)

end