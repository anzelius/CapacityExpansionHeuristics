
NETWORK[:Skellefteälven] = [
       # Upstream plant: name, dischargedelay (h), utskovdelay, passagedelay (h), drybeddelay (h) (if -1, there is no such passage)
        Connection(:Rebnis),      
        Connection(:Sädva),       
        Connection(:Hornavan,    Upstream(:Rebnis,      24, 48, -1, -1), Upstream(:Sädva,  24, 48, -1, -1)),
        Connection(:Bergnäs,     Upstream(:Hornavan,    -1,  3, -1, -1)),
        Connection(:Slagnäs,     Upstream(:Bergnäs,      8,  3, -1, -1)),
        Connection(:Bastusel,    Upstream(:Slagnäs,      6,  4, -1, -1)),
        Connection(:Grytfors,    Upstream(:Bastusel,     0,  6, -1, -1)),
        Connection(:Gallejaur,   Upstream(:Grytfors,     2,  0, -1, -1)),
        Connection(:Vargfors,    Upstream(:Gallejaur,    0,  6, -1, -1)), 
        Connection(:Rengård,     Upstream(:Vargfors,     3,  3, -1, -1)),
        Connection(:Båtfors,     Upstream(:Rengård,      1,  1, -1, -1)),
        Connection(:Finnfors,    Upstream(:Båtfors,      1,  0, -1, -1)),
        Connection(:Granfors,    Upstream(:Finnfors,     1,  1, -1, -1)), 
        Connection(:Krångfors,   Upstream(:Granfors,     1,  0, -1, -1)), 
        Connection(:Selsfors,    Upstream(:Krångfors,    0,  1, -1, -1)),
        Connection(:Kvistforsen, Upstream(:Selsfors,     0,  0, -1, -1)), 
        Connection(:Bergsby,     Upstream(:Kvistforsen,  0,  0, -1, -1)),
        Connection(:Hav,         Upstream(:Bergsby,     -1,  0, -1, -1)) 
    ]