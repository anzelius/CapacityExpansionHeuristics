
NETWORK[:Luleälven] = [
        # Upstream plant: name, dischargedelay (h), utskovdelay, passagedelay (h), drybeddelay (h) (if -1, there is no such passage)
        Connection(:Seitevare),   
        Connection(:Parki,       Upstream(:Seitevare,   0,  0, -1, -1)), 
        Connection(:Randi,       Upstream(:Parki,       1,  1, -1, -1)),
        Connection(:Akkats,      Upstream(:Randi,       1,  1, -1, -1)),
        Connection(:Letsi,       Upstream(:Akkats,      2,  2, -1, -1)),
        Connection(:Ritsem),     
        Connection(:Satisjaure,  Upstream(:Ritsem,     -1,  0, -1, -1)),
        Connection(:Suorva,      Upstream(:Ritsem,      0,  0, -1, -1)),
        Connection(:Vietas,      Upstream(:Suorva,     -1,  0, -1, -1), Upstream(:Satisjaure, -1, 0, -1, -1)),
        Connection(:Langas,      Upstream(:Vietas,      0,  0, -1, -1)),
        Connection(:Porjus,      Upstream(:Langas,     -1,  0, -1, -1)),
        Connection(:Harsprånget, Upstream(:Porjus,      0,  0, -1, -1)),
        Connection(:Ligga,       Upstream(:Harsprånget, 1,  1, -1, -1)), 
        Connection(:Messaure,    Upstream(:Ligga,       1,  1, -1, -1)), 
        Connection(:Porsi,       Upstream(:Messaure,    3,  3, -1, -1),  Upstream(:Letsi, 1,  1, -1, -1)),
        Connection(:Laxede,      Upstream(:Porsi,       1,  1, -1, -1)), 
        Connection(:Vittjärv,    Upstream(:Laxede,      5,  5, -1, -1)), 
        Connection(:Boden,       Upstream(:Vittjärv,    1,  1, -1, -1)),
        Connection(:Hav,         Upstream(:Boden,       0,  0, -1, -1)) 
    ]