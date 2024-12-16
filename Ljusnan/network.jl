
NETWORK[:Ljusnan] = [
        # Upstream plant: name, dischargedelay (h), utskovdelay, passagedelay (h), drybeddelay (h) (if -1, there is no such passage)                 
        Connection(:Lossen),           
        Connection(:Mittån),             
        Connection(:Halvfari,         Upstream(:Lossen,           1,  1, -1, -1), Upstream(:Mittån,    1,  1, -1, -1)),
        Connection(:Sveg,             Upstream(:Halvfari,        24, 24, -1, -1)), 
        Connection(:Byarforsen,       Upstream(:Sveg,             0,  0, -1, -1)), 
        Connection(:Krokströmmen,     Upstream(:Byarforsen,       2,  2, -1, -1)), 
        Connection(:Långströmmen,     Upstream(:Krokströmmen,     0,  0, -1, -1)),
        Connection(:Storåströmmen,    Upstream(:Långströmmen,     1,  1, -1, -1)),
        Connection(:Öjeforsen,        Upstream(:Storåströmmen,    0,  0, -1, -1)),
        Connection(:Laforsen,         Upstream(:Öjeforsen,        1,  1, -1, -1)), 
        Connection(:Norränge,         Upstream(:Laforsen,        20, 20, -1, -1)), 
        Connection(:Lottefors,        Upstream(:Norränge,         1,  1, -1, -1)),
        Connection(:Dönje,            Upstream(:Lottefors,        0,  0, -1, -1)),
        Connection(:Viksjöfors),      
        Connection(:Alfta,            Upstream(:Viksjöfors,       0,  0, -1, -1)), 
        Connection(:Sunnerstaholm,    Upstream(:Alfta,            6,  6, -1, -1)),
        Connection(:Lenninge,         Upstream(:Sunnerstaholm,    0,  0, -1, -1)),
        Connection(:Landafors,        Upstream(:Dönje,            2,  2, -1, -1), Upstream(:Lenninge, 2,  2, -1, -1)), 
        Connection(:Bergvik,          Upstream(:Landafors,        1,  1, -1, -1)), 
        Connection(:Höljebro,         Upstream(:Bergvik,          1,  1, -1, -1)), 
        Connection(:Ljusne_Strömmar,  Upstream(:Höljebro,         0,  0, -1, -1)), 
        Connection(:Ljusnefors,       Upstream(:Ljusne_Strömmar,  0,  0, -1, -1)), 
        Connection(:Hav,              Upstream(:Ljusnefors,       0,  0, -1, -1))
    ]
