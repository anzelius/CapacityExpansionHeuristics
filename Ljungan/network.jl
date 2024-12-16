

NETWORK[:Ljungan] = [
        # Upstream plant: name, dischargedelay (h), utskovdelay, passagedelay (h), drybeddelay (h) (if -1, there is no such passage)
        Connection(:Storsjö),        
        Connection(:Flåsjön,        Upstream(:Storsjö,       -1,  0, -1, -1)), 
        Connection(:Trångforsen,    Upstream(:Flåsjön,        8,  8, -1, -1)), # The reservoir is called Lännässjön             
        Connection(:Rätan,          Upstream(:Trångforsen,    8,  4, -1, -1)), 
        Connection(:Turinge,        Upstream(:Rätan,          1,  1, -1, -1)),
        Connection(:Bursnäs,        Upstream(:Turinge,        1,  1, -1, -1)),
        Connection(:Havern,         Upstream(:Bursnäs,        0,  0, -1, -1)), 
        Connection(:Järnvägsforsen, Upstream(:Havern,        -1,  0, -1, -1)), # The reservoir is named Holmsjön
        Connection(:Parteboda,      Upstream(:Järnvägsforsen, 0,  9, -1, -1)),
        Connection(:Hermansboda,    Upstream(:Parteboda,      1,  3, -1, -1)),
        Connection(:Ljungaverk,     Upstream(:Hermansboda,    0,  0, -1, -1)),
        Connection(:Leringsforsen),                                            # The reservoir is called Holmsjön-Leringen, and is 357 Mm3. I have lowered it to get feasible soultions with the inflowdata I have. This is probably due to non-rectangular shape, so the model is not able to fulfill the minlevel in leringen in july when starting from april/may. 
        Connection(:Torpshammar,    Upstream(:Leringsforsen,  1,  1, -1, -1)),
        Connection(:Nederede,       Upstream(:Ljungaverk,     1,  1, -1, -1), Upstream(:Torpshammar, 3, 3, -1, -1)),
        Connection(:Skallböle,      Upstream(:Nederede,       1,  1, -1, -1)),
        Connection(:Matfors,        Upstream(:Skallböle,      0,  0, -1, -1)),
        Connection(:Viforsen,       Upstream(:Matfors,        1,  1, -1, -1)),
        Connection(:Hav,            Upstream(:Viforsen,       0,  0, -1, -1))
    ]

