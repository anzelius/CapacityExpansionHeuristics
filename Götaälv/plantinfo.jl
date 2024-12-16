

PLANTINFO[:Götaälv] = [
        # name, nr of turbines, reported capacity, reservoir size, reservoir level limits (high & low / DG & SG), tailrace avg, mean head
        #                   nr    MW     Mm3       m       m       m        m
        Plant(:Höljes,       2,  128,    270,  304.0,  270.0,  201.8,   85.24), 
        Plant(:Tåsan,        1,   40,    156,  422.4,  420.4,  153.4,  267.96),
        Plant(:Letten,       2,   36,    139,  348.0,  339.0,  155.2,  188.32), # HE estimated by 15.5km2 lake area * 9m regleringsamplitud
        Plant(:Edsforsen,    2,    9,    0.1,  135.5,  134.4,  127.9,    7.03),
        Plant(:Skoga,        2, 13.6,    0.1,  127.8,  127.6,  118.2,    9.51),
        Plant(:Kvien,        1,  2.7,     80,  310.7,  306.0,  286.8,   21.58), # HE estimated by 16.8km2 lake area * 4.7m regleringsamplitud
        Plant(:Nain,         1,    7,     36,  267.8,  264.9,  220.0,   46.37), # HE estimated by 12.3km2 lake area * 2.9m regleringsamplitud
        Plant(:Knon,         1,    6,    3.5,  217.2,  215.5,  185.6,   30.77), # HE estimated by 2km2 lake area * 1.7m regleringsamplitud
        Plant(:Laggåsen,     1,  2.7,    4.7,  230.5,  229.4,  188.2,   41.78), # HE estimated by 4.3km2 lake area * 1.1m regleringsamplitud
        Plant(:Traneberg,    1,  0.8,     13,  203.3,  201.6,  183.5,   18.97), # HE estimated by 7.6km2 lake area * 1.7m regleringsamplitud
        Plant(:Malta,        1,  6.1,    1.2,  184.0,  183.3,  155.1,   28.54), # HE estimated by 1.7km2 lake area * 0.7m regleringsamplitud
        Plant(:Hagfors,      2,  4.9,    0.1,  155.2,  154.9,  131.9,   23.19),
        Plant(:Stjern,       1,  1.9,    0.1,  132.1,  131.5,  123.4,     8.4),
        Plant(:Råda,         1,   22,    5.5,  123.5,  123.0,  117.2,     6.0), # HE estimated by 11km2 lake area * 0.5m regleringsamplitud
        Plant(:Krakerud,     2,   22,    0.1,  117.4,  116.9,  105.8,   11.33),
        Plant(:Forshult,     2,   24,    0.1,  106.6,  105.3,   93.4,   12.58),
        Plant(:Skymnäs,      2, 15.6,    0.1,   93.0,   92.8,   82.2,   10.68), 
        Plant(:Munkfors,     3,   33,    0.1,   81.5,   80.5,   63.7,   17.31), 
        Plant(:Dejefors,     4,   20,    0.1,   62.1,   61.8,   51.1,   10.85),
        Plant(:Forshaga,     3,  6.6,    0.1,   51.0,   50.7,   46.4,    4.43), 
        Plant(:Vänern,       0,  NaN,   9400,   44.9,   43.3,    NaN,     NaN),
        Plant(:Vargön,       3,   34,    0.1,   44.6,   43.0,   39.1,    4.71),
        Plant(:Trollhättan, 10,  283,      4,   39.5,   38.4,    7.0,   31.92), 
        Plant(:Lilla_Edet,   4, 46.2,    3.5,    7.3,    6.3,    0.5,     6.3),
        Plant(:Hav,          0,  NaN,    NaN,    NaN,    NaN,    NaN,     NaN)
    ]