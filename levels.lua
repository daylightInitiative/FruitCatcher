
-- how do we structure levels?
-- we could have a numoffruit (onscreen) and then a reserve amount for each level to fire event


local levels = {

    -- maybe we should merge all this
    levelNames = {
        [1] = "grassland",
        [2] = "grassland_night"
    },

    levelBackgrounds = {
        [1] = "assets/fruitgame_background.png",
        [2] = "assets/fruitgame_background_level2.png"
    },

    [1] = {
        [1] = 5,
        [2] = 5,
        [3] = 10,
        [4] = 10,
        [5] = 10,
    },

    [2] = {
        [1] = 5,
        [2] = 5,
        [3] = 10,
        [4] = 10,
        [5] = 10, 
    },

}



return levels