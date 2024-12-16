

PLANTINFO[:Indalsälven] = [
        # name, nr of turbines, reported capacity, reservoir size, reservoir level limits (high & low / DG & SG), tailrace avg, mean head
        #                       nr      MW     Mm3       m       m       m        m
        Plant(:Lillå,            1,    0.5,  103.0,  324.5,  323.3,  314.2,    9.73), # Magasinet heter Näckten
        Plant(:Strömbacka,       1,    0.5, 0.0001,  314.1,  313.4,  304.9,    8.84), # SG och DG från ÖVYdaya
        Plant(:Billsta,          1,   0.42, 0.0001,  303.9,  302.9,  294.9,    8.48), # SG och DG från ÖVYdaya
        Plant(:Sällsjö,          2,    166,  700.0,  492.9,  466.0,  294.9,  184.58), # Magasinet heter Håckren 
        Plant(:Duved,            1,    6.4,   11.0,  602.0,  595.5,  388.4,   210.4), # Magasinet heter Greningen
        Plant(:Slagsån,          1,    0.8,   14.2,  391.6,  391.0,  331.7,   59.65), # Magasinen heter Norsjön och Helgesjön, SG DG från data på ÖVY pga inte vid reservoaren
        Plant(:Anjan,            1,     25,  309.0,  423.5,  414.3,  379.6,    39.3), # Magasinen Storrensjön+Anjan
        Plant(:Torrön,           1,     24, 1178.0,  417.5,  404.6,  392.7,   18.33), 
        Plant(:Juveln,           1,     14,  269.0,  395.2,  386.6,  380.6,   10.27), 
        Plant(:Järpströmmen,     3,    120,  502.0,  383.3,  380.0,  317.8,   63.89), # Magasinet heter Kallsjön
        Plant(:Mörsil,           2,     40,    8.1,  317.4,  316.9,  300.1,   17.08), # Magasinet heter Liten #Upstream(:Handöl_nedre, 10, 10)
        Plant(:Ockesjön,         0,    NaN,   16.8,  301.0,  298.9,    NaN,     NaN), # Magasinsvolym uppsakattat ifrån fallhöjd (från mörsils NVY och Ockesjöns sänkningsgräns) * sjöarean (8km^2)
        Plant(:Alsensjön,        0,    NaN,   65.0,  295.5,  294.7,    NaN,     NaN), # Alsen och Näldsjön är samma här
        Plant(:Hissmofors,       3,     66, 1262.0,  293.3,  290.5,  273.3,   18.57), # Magasinet heter Storsjön            
        Plant(:Kattstrupeforsen, 3,     62,    4.3,  273.8,  272.7,  257.2,   16.05), 
        Plant(:Granboforsen,     2,     25,    0.6,  257.5,  257.3,  251.1,    6.32),
        Plant(:Långså,           1,     50,  206.0,  536.5,  534.0,  325.3,  209.95), # Magasinet heter Mjölkvattnet + Burvattnet + Övre lille mjölkvattnet
        Plant(:Oldå,             1,     62,  197.0,  596.0,  581.0,  322.6,  265.94), # Magasinet heter Korsvattnet + Övre oldsjön
        Plant(:Rönnöfors,        1,      4,   14.0,  325.5,  324.3,  318.4,    6.45),
        Plant(:Landösjön,        0,    NaN,  163.0,  319.6,  316.0,    NaN,     NaN),
        Plant(:Stensjöfallet,    1,    117,  174.4,  682.7,  655.2,  359.9,  309.06), # Magasinet heter Stora Stensjön
        Plant(:Kvarnfallet,      1,     17,   11.0,  365.0,  362.6,  313.2,   50.59), # Magasinet heter Rörvattnet                                   
        Plant(:Lövhöjden,        1,    8.5,   61.0,  487.0,  476.0,  384.8,   96.75), # Magasinet heter Stor-Foskvattnet 
        Plant(:Ålviken,          1,      6,   0.04,  388.0,  387.9,  313.7,   74.25), # Magasinsvolym upskattad från SG/DG och sjöyta, SG DG från ÖVYdata
        Plant(:Näsaforsen,       1,     15,  147.0,  300.0,  299.4,  283.9,    15.8), # Magasinet heter Hotagen, SG DG från data på Näsaforsen
        Plant(:Högfors,          2,     62,    0.8,  265.9,  265.4,  253.2,   12.41), # Magasinet heter Sandvikssjön
        Plant(:Midskog,          3,    158,   56.0,  251.3,  249.0,  223.7,   26.48),
        Plant(:Näverede,         2,   75.6,   0.01,  224.2,  224.1,  211.7,   12.48),
        Plant(:Stugun,           2,   45.5,   0.01,  211.3,  211.0,  203.8,    7.36),
        Plant(:Krångede,         6,  165.6,   59.8,  204.0,  202.0,  143.1,    59.9), # Magasinet heter Gesunden
        Plant(:Gammelänge,       3,     78,   0.01,  144.0,  143.8,  126.2,   17.73), 
        Plant(:Hammarforsen,     5,     79,  360.0,  125.5,  125.0,  105.7,   19.53),
        Plant(:Svarthålsforsen,  3,   86.4,   0.01,  105.0,  104.9,   89.6,   15.35),
        Plant(:Stadsforsen,      3,  147.6,    3.9,   90.0,   88.0,   61.5,   27.52),
        Plant(:Hölleforsen,      3,    149,    0.8,   61.5,   60.5,   36.9,   24.07),
        Plant(:Järkvissle,       2,   96.5,   10.8,   37.5,   35.5,   23.2,   13.31),
        Plant(:Sillre,           1,   11.7,   35.5,  216.0,  210.5,   21.2,  192.02), # Magasinen heter Skälsjön och Oxsjön
        Plant(:Bergeforsen,      4,  168.5,   1.08,   23.0,   22.0,      0,   22.75),
        Plant(:Hav,              0,    NaN,    NaN,    NaN,    NaN,    NaN,     NaN)
        ]