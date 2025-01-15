
     ENVCON[:Ångermanälven, "Dagens miljövillkor"] = function (flow_params, level_params)

        flow_constraints!("min", "utskov", (:Ransaren, :Stalon), "01-01", "12-31", 0, 23, 2.0, flow_params)
        flow_constraints!("min", "utskov", (:Ransaren, :Stalon), "07-01", "08-31", 0, 23, 5, flow_params)
        flow_constraints!("min", "utskov", (:Ransaren, :Stalon), "09-01", "09-15", 0, 23, 6, flow_params)
        flow_constraints!("min", "utskov", (:Stalon, :Malgomaj), "01-01", "12-31", 0, 23, 1.5, flow_params)
        flow_constraints!("min", "utskov", (:Stalon, :Malgomaj), "05-01", "05-31", 0, 23, 5.75, flow_params)
        flow_constraints!("min", "utskov", (:Stalon, :Malgomaj), "06-01", "06-20", 0, 23, 10, flow_params)
        flow_constraints!("min", "utskov", (:Stalon, :Malgomaj), "06-21", "07-31", 0, 23, 25, flow_params)
        flow_constraints!("min", "utskov", (:Stalon, :Malgomaj), "08-01", "08-20", 0, 23, 17.5, flow_params)
        flow_constraints!("min", "utskov", (:Stalon, :Malgomaj), "08-21", "09-20", 0, 23, 10, flow_params)
        flow_constraints!("min", "utskov", (:Stalon, :Malgomaj), "09-21", "10-10", 0, 23, 5.75, flow_params)
        flow_constraints!("min", "utskov", (:Vojmsjön, :Volgsjöfors), "01-01", "12-31", 0, 23, 3, flow_params)
        flow_constraints!("min", "utskov", (:Ormsjön, :Borgforsen), "01-01", "12-31", 0, 23, 5.7, flow_params)
        flow_constraints!("min", "utskov", (:Ormsjön, :Borgforsen), "05-31", "10-01", 0, 23, 12, flow_params)
        flow_constraints!("min", "utskov", (:Vängelsjön, :Kilforsen), "01-01", "12-31", 0, 23, 3, flow_params)
        flow_constraints!("min", "utskov", (:Blåsjön, :Junsterforsen), "05-31", "07-31", 8, 22, 4, flow_params)
        flow_constraints!("min", "utskov", (:Blåsjön, :Junsterforsen), "08-01", "09-30", 8, 18, 4, flow_params)
        flow_constraints!("min", "utskov", (:Junsterforsen, :Gäddede), "05-15", "06-14", 10, 20, 5.5, flow_params)
        flow_constraints!("min", "utskov", (:Junsterforsen, :Gäddede), "06-15", "07-31", 8, 22, 5.5, flow_params)
        flow_constraints!("min", "utskov", (:Junsterforsen, :Gäddede), "08-01", "08-31", 8, 18, 5.5, flow_params)
        flow_constraints!("min", "utskov", (:Bågede, :Lövön), "01-01", "04-15", 0, 23, 2.5, flow_params)
        flow_constraints!("min", "utskov", (:Bågede, :Lövön), "04-16", "05-15", 0, 23, 3, flow_params)
        flow_constraints!("min", "utskov", (:Bågede, :Lövön), "05-16", "09-15", 0, 23, 6, flow_params)
        flow_constraints!("min", "utskov", (:Bågede, :Lövön), "09-16", "12-31", 0, 23, 3, flow_params)
        flow_constraints!("min", "utskov", (:Lövön, :Storfinnforsen), "01-01", "12-31", 0, 23, 3, flow_params)
        flow_constraints!("min", "utskov", (:Lövön, :Storfinnforsen), "05-01", "09-30", 0, 23, 10, flow_params)
        flow_constraints!("min", "utskov", (:Lövön, :Vängelsjön), "01-01", "12-31", 0, 23, "Tillrinning10", flow_params)
        flow_constraints!("min", "utskov", (:Nämforsen, :Moforsen), "06-15", "07-31", 8, 22, 125, flow_params)
        flow_constraints!("min", "utskov", (:Nämforsen, :Moforsen), "08-01", "08-15", 8, 21, 125, flow_params)
        flow_constraints!("min", "utskov", (:Nämforsen, :Moforsen), "06-29", "06-30", 0, 23, 125, flow_params)

        flow_constraints!("min", "total", (:Gäddede, :Bågede), "01-01", "12-31", 0, 23, 20, flow_params)
        flow_constraints!("min", "total", (:Edsele, :Forsse), "01-01", "12-31", 0, 23, 50, flow_params)
        flow_constraints!("min", "total", (:Sollefteå, :Hav), "01-01", "05-14", 0, 23, 75, flow_params)
        flow_constraints!("min", "total", (:Sollefteå, :Hav), "05-15", "05-31", 0, 23, 95, flow_params)
        flow_constraints!("min", "total", (:Sollefteå, :Hav), "06-01", "08-31", 0, 23, 123, flow_params)
        flow_constraints!("min", "total", (:Sollefteå, :Hav), "09-01", "09-15", 0, 23, 95, flow_params)
        flow_constraints!("min", "total", (:Sollefteå, :Hav), "09-16", "12-31", 0, 23, 75, flow_params)

        flow_constraints!("ramp_up", "total", (:Ransaren, :Stalon), "01-01", "06-06", 0, 23, 8/24, flow_params) # Islagd tid enl. SMHI medel mellan 1945-1986
        flow_constraints!("ramp_up", "total", (:Ransaren, :Stalon), "06-07", "11-23", 0, 23, 20/24, flow_params)
        flow_constraints!("ramp_up", "total", (:Ransaren, :Stalon), "11-24", "12-31", 0, 23, 8/24, flow_params) # Islagd tid enl. SMHI medel mellan 1945-1986
        flow_constraints!("ramp_up", "total", (:Vojmsjön, :Volgsjöfors), "01-01", "12-31", 0, 23, 75/24, flow_params)
        flow_constraints!("ramp_down", "total", (:Ransaren, :Stalon), "01-01", "06-06", 0, 23, 8/24, flow_params) # Islagd tid enl. SMHI medel mellan 1945-1986
        flow_constraints!("ramp_down", "total", (:Ransaren, :Stalon), "06-07", "11-23", 0, 23, 20/24, flow_params)
        flow_constraints!("ramp_down", "total", (:Ransaren, :Stalon), "11-24", "12-31", 0, 23, 8/24, flow_params) # Islagd tid enl. SMHI medel mellan 1945-1986
        flow_constraints!("ramp_down", "total", (:Vojmsjön, :Volgsjöfors), "01-01", "12-31", 0, 23, 75/24, flow_params)

        level_constraints!("min", "forebay", :Tåsjö, "07-01", "11-01", 0, 23, 252.5, level_params)
        level_constraints!("min", "forebay", :Ormsjön, "05-31", "10-15", 0, 23, 265.0, level_params) # Från och med vårfloden egentligen. Satte fast värde på sista maj nu.
        level_constraints!("min", "forebay", :Stalon, "07-01", "10-01", 0, 23, 541.2, level_params)
        level_constraints!("min", "forebay", :Malgomaj, "07-01", "09-30", 0, 23, 342.5, level_params)
        level_constraints!("min", "forebay", :Sollefteå, "06-01", "08-31", 0, 23, 9.3, level_params)
    end