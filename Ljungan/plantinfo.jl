
PLANTINFO[:Ljungan] = [
        # name, nr of turbines, reported capacity, reservoir size, reservoir level limits (high & low / DG & SG), tailrace avg, mean head
        #                      nr   MW      Mm3       m       m       m       m
        Plant(:Storsjö,        0,  NaN,      96,  566.0,  561.6,    NaN,    NaN), 
        Plant(:Flåsjön,        1,   20,     400,  495.3,  465.0,  437.0,  43.13), 
        Plant(:Trångforsen,    1,   73,      20,  437.5,  436.5,  353.3,  83.74), # The reservoir is called Lännässjön             
        Plant(:Rätan,          2,   60,       4,  350.4,  349.9,  289.0,  61.15), 
        Plant(:Turinge,        2,   18,     1.8,  288.9,  288.5,  266.6,  22.08),
        Plant(:Bursnäs,        1,    8,    0.01,  266.4,  266.3,  259.0,   7.36),
        Plant(:Havern,         0,  NaN,     102,  259.5,  256.2,    NaN,    NaN), 
        Plant(:Järnvägsforsen, 2,  100,     192,  244.9,  240.4,  156.8,  85.86), # The reservoir is named Holmsjön
        Plant(:Parteboda,      2,   35,    0.58,  158.1,  157.9,  124.7,  33.30),
        Plant(:Hermansboda,    2,   12,    0.36,  123.5,  123.4,  112.3,  11.12),
        Plant(:Ljungaverk,     2,   59,    2.43,  112.2,  111.9,   59.9,  52.15),
        Plant(:Leringsforsen,  1,    9,     357,  201.9,  192.7,  181.9,  15.45), # The reservoir is called Holmsjön-Leringen, and is 357 Mm3. I have lowered it to get feasible soultions with the inflowdata I have. This is probably due to non-rectangular shape, so the model is not able to fulfill the minlevel in leringen in july when starting from april/may. 
        Plant(:Torpshammar,    2,  119,     2.6,  185.6,  185.2,   59.3, 126.06),
        Plant(:Nederede,       2,   16,     2.4,   58.6,   58.2,   50.3,   8.06),
        Plant(:Skallböle,      3,   46,    11.3,   50.4,   49.8,   29.1,  20.98),
        Plant(:Matfors,        1,   21,     0.1,   29.1,   28.9,   18.8,  10.25),
        Plant(:Viforsen,       1,   10,     4.3,   19.0,   18.4,   10.7,   8.02),
        Plant(:Hav,            0,  NaN,     NaN,    NaN,    NaN,    NaN,    NaN)
    ]

