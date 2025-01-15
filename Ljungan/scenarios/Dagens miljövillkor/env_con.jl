
    ENVCON[:Ljungan, "Dagens miljövillkor"] = function (flow_params, level_params)


        level_constraints!("max", "forebay", :Storsjö, "01-01", "07-15", 0, 23, 565.7, level_params)
        level_constraints!("min", "forebay", :Storsjö, "06-05", "09-16", 0, 23, 565.5, level_params)
        flow_constraints!("min", "utskov", (:Storsjö, :Flåsjön), "01-01", "12-31", 0, 23, 1.6, flow_params)

        flow_constraints!("min", "total", (:Flåsjön, :Trångforsen), "01-01", "12-31", 0, 23, 2.6, flow_params)

        level_constraints!("min", "forebay", :Trångforsen, "01-01", "02-20", 0, 23, 437.2, level_params)
        level_constraints!("min", "forebay", :Trångforsen, "06-05", "12-31", 0, 23, 437.2, level_params)
        flow_constraints!("min", "utskov", (:Trångforsen, :Rätan), "06-01", "08-24", 0, 23, 3, flow_params)
        flow_constraints!("min", "utskov", (:Trångforsen, :Rätan), "08-25", "08-25", 0, 23, 2.5, flow_params)
        flow_constraints!("min", "utskov", (:Trångforsen, :Rätan), "08-26", "08-26", 0, 23, 2, flow_params)
        flow_constraints!("min", "utskov", (:Trångforsen, :Rätan), "08-27", "08-27", 0, 23, 1.5, flow_params)
        flow_constraints!("min", "utskov", (:Trångforsen, :Rätan), "08-28", "08-28", 0, 23, 1, flow_params)
        flow_constraints!("min", "utskov", (:Trångforsen, :Rätan), "08-29", "08-29", 0, 23, 0.5, flow_params)
        flow_constraints!("min", "total", (:Trångforsen, :Rätan), "01-01", "12-31", 0, 23, 6, flow_params)

        level_constraints!("min", "forebay", :Havern, "06-10", "09-16", 0, 23, 258.5, level_params)
        level_constraints!("min", "forebay", :Havern, "09-17", "12-31", 0, 23, 257.1, level_params)

        level_constraints!("min", "forebay", :Järnvägsforsen, "01-01", "02-28", 0, 23, 241.4, level_params)
        level_constraints!("min", "forebay", :Järnvägsforsen, "06-10", "09-16", 0, 23, 243.8, level_params)
        level_constraints!("min", "forebay", :Järnvägsforsen, "09-17", "12-31", 0, 23, 241.4, level_params)
        flow_constraints!("min", "utskov", (:Järnvägsforsen, :Parteboda), "01-01", "05-15", 0, 23, 2, flow_params)
        flow_constraints!("min", "utskov", (:Järnvägsforsen, :Parteboda), "05-16", "09-30", 0, 23, 6, flow_params)
        flow_constraints!("min", "utskov", (:Järnvägsforsen, :Parteboda), "10-01", "12-31", 0, 23, 2, flow_params)
        flow_constraints!("min", "total", (:Järnvägsforsen, :Parteboda), "01-01", "12-31", 0, 23, 20, flow_params)

        flow_constraints!("min", "utskov", (:Parteboda, :Hermansboda), "06-01", "06-10", 8, 21, 3, flow_params)
        flow_constraints!("min", "utskov", (:Parteboda, :Hermansboda), "06-11", "07-10", 8, 23, 3, flow_params)
        flow_constraints!("min", "utskov", (:Parteboda, :Hermansboda), "07-11", "07-31", 8, 21, 3, flow_params)
        flow_constraints!("min", "utskov", (:Parteboda, :Hermansboda), "08-01", "08-15", 8, 20, 3, flow_params)
        flow_constraints!("min", "utskov", (:Parteboda, :Hermansboda), "08-16", "10-23", 8, 19, 3, flow_params)
        flow_constraints!("min", "utskov", (:Parteboda, :Hermansboda), "06-21", "06-21", 8, 23, 10, flow_params)
        flow_constraints!("min", "utskov", (:Parteboda, :Hermansboda), "06-22", "06-22", 8, 23, 10, flow_params)
        flow_constraints!("min", "utskov", (:Parteboda, :Hermansboda), "06-23", "06-24", 0, 23, 10, flow_params)

        flow_constraints!("min", "utskov", (:Ljungaverk, :Nederede), "01-01", "05-15", 0, 23, 0.5, flow_params)
        flow_constraints!("min", "utskov", (:Ljungaverk, :Nederede), "05-16", "08-31", 0, 23, 5, flow_params)

        level_constraints!("min", "forebay", :Leringsforsen, "07-01", "07-31", 0, 23, 198, level_params) # 200.5 egentligen. Var tvungen att sänka för att inflödet skulle räcka till att nå SG. Eventuellt en ganska orektangulär dam som egentligen når högre nivå med mindre vatten.
        level_constraints!("min", "forebay", :Leringsforsen, "08-01", "08-31", 0, 23, 199, level_params) # 201.5 egentligen

        level_constraints!("min", "forebay", :Torpshammar, "01-01", "05-15", 0, 23, 185.2, level_params)
        level_constraints!("min", "forebay", :Torpshammar, "05-16", "09-30", 0, 23, 185.5, level_params)
        level_constraints!("min", "forebay", :Torpshammar, "10-01", "12-31", 0, 23, 185.2, level_params)

        flow_constraints!("min", "utskov", (:Matfors, :Viforsen), "05-16", "08-15", 8, 21, 2.5, flow_params)
        flow_constraints!("min", "utskov", (:Matfors, :Viforsen), "08-16", "09-30", 8, 20, 2.5, flow_params)

        level_constraints!("min", "forebay", :Viforsen, "05-16", "09-30", 0, 23, 18.7, level_params)

    end