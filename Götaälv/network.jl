
NETWORK[:Götaälv] = [
        # Upstream plant: name, dischargedelay (h), utskovdelay, passagedelay (h), drybeddelay (h) (if -1, there is no such passage)
        Connection(:Höljes),       
        Connection(:Tåsan),       
        Connection(:Letten),     
        Connection(:Edsforsen,    Upstream(:Höljes,      28, 28, -1, -1), Upstream(:Tåsan, 24,  24, -1, -1), Upstream(:Letten, 24, 24, -1, -1)),
        Connection(:Skoga,        Upstream(:Edsforsen,    0,  0, -1, -1)),
        Connection(:Kvien),       
        Connection(:Nain,         Upstream(:Kvien,        4,  4, -1, -1)),
        Connection(:Knon),        
        Connection(:Laggåsen),    
        Connection(:Traneberg),   
        Connection(:Malta,        Upstream(:Traneberg,    1,  1, -1, -1), Upstream(:Laggåsen, 2, 2, -1, -1), Upstream(:Knon, 2, 2, -1, -1), Upstream(:Nain, 3, 3, -1, -1)),
        Connection(:Hagfors,      Upstream(:Malta,        1,  1, -1, -1)),
        Connection(:Stjern,       Upstream(:Hagfors,      1,  1, -1, -1)),
        Connection(:Råda,         Upstream(:Stjern,       1,  1, -1, -1)),
        Connection(:Krakerud,     Upstream(:Skoga,        2,  2, -1, -1),  Upstream(:Råda, 2, 2, -1, -1)),
        Connection(:Forshult,     Upstream(:Krakerud,     1,  1, -1, -1)),
        Connection(:Skymnäs,      Upstream(:Forshult,     0,  0, -1, -1)), 
        Connection(:Munkfors,     Upstream(:Skymnäs,      2,  2, -1, -1)), 
        Connection(:Dejefors,     Upstream(:Munkfors,     3,  3, -1, -1)),
        Connection(:Forshaga,     Upstream(:Dejefors,     1,  1, -1, -1)), 
        Connection(:Vänern,       Upstream(:Forshaga,     1,  1, -1, -1)),
        Connection(:Vargön,       Upstream(:Vänern,      -1,  0, -1, -1)),
        Connection(:Trollhättan,  Upstream(:Vargön,       1,  1, -1, -1)), 
        Connection(:Lilla_Edet,   Upstream(:Trollhättan,  0,  0, -1, -1)),
        Connection(:Hav,          Upstream(:Lilla_Edet,   0,  0, -1, -1))
    ]