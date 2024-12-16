

NETWORK[:Umeälven] = [
        # Upstream plant: name, dischargedelay (h), utskovdelay, passagedelay (h), drybeddelay (h) (if -1, there is no such passage)
        Connection(:Abelvattnet),    
        Connection(:Gejmån,         Upstream(:Abelvattnet,    0,  0, -1, -1)), 
        Connection(:Björkvattnet,   Upstream(:Gejmån,         0,  0, -1, -1)), 
        Connection(:Ajaure),                   
        Connection(:Gardikfors,     Upstream(:Ajaure,         0,  0, -1, -1), Upstream(:Björkvattnet, -1,  1, -1, -1)), 
        Connection(:Juktan),        
        Connection(:Umluspen,       Upstream(:Gardikfors,     1,  1, -1, -1), Upstream(:Juktan, 1,  1, -1, -1)), #Storuman
        Connection(:Stensele,       Upstream(:Umluspen,       1,  1, -1, -1)), 
        Connection(:Grundfors,      Upstream(:Stensele,       2,  2, -1, -1)),
        Connection(:Rusfors,        Upstream(:Grundfors,      6,  6, -1, -1), Upstream(:Juktan, -1,  0, -1, -1)),
        Connection(:Bålforsen,      Upstream(:Rusfors,        4,  4, -1, -1)),
        Connection(:Betsele,        Upstream(:Bålforsen,      1,  1, -1, -1)),
        Connection(:Hällfors,       Upstream(:Betsele,        1,  1, -1, -1)),
        Connection(:Tuggen,         Upstream(:Hällfors,       1,  1, -1, -1)),
        Connection(:Bjurfors_övre,  Upstream(:Tuggen,         1,  1, -1, -1)),
        Connection(:Bjurfors_nedre, Upstream(:Bjurfors_övre,  0,  1, -1, -1)),
        Connection(:Harrsele,       Upstream(:Bjurfors_nedre, 1,  1, -1, -1)),
        Connection(:Pengfors,       Upstream(:Harrsele,       1,  1, -1, -1)),
        Connection(:Stornorrfors,   Upstream(:Pengfors,       2,  2, -1, -1)),
        Connection(:Hav,            Upstream(:Stornorrfors,   0,  0, -1, -1))
    ]
