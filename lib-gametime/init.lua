--
-- For Stuff related to initializing players, games, etc.

require "lib-gametime.assemble-pod-epochs"
require "lib-gametime.game-options"
require "lib-gametime.names"
require "lib-gametime.quick-start"
require "config"

function initMod()

    if (global.init == nil) then global.init = false end -- Tells it to set up the first pod.

    if (global.nextLifePod == nil) then
        global.nextLifePod = {

            name = "",
            warningTick = 0,  -- Filled in at init
            arrivalTick = 0,  -- Filled in at init
            product = nil,
            tracked = {},
            arrivalPosition = {x = 0, y = 0}, -- Filled in at init

            warningMinimapGhosts = {},
        }
    end

    if (global.nextToNextLifePod == nil) then
        global.nextToNextLifePod = {
            feedback_extra_time = 0,
            radar_overflow = 0,
        }
    end

    if (CONFIG.LIFE_POD_PERIOD_MIN >= CONFIG.LIFE_POD_PERIOD_MAX) then
        debugError("Config Error: LIFE_POD_PERIOD or WARNING_TIME interval is invalid")
    end

    if (global.deadPodsPopulation == nil) then
        global.deadPodsPopulation = 0
    end

    if (global.lifePods == nil) then
        global.lifePods = {}
    end

    global.Xoffsets = {
        {x=3,y=-3},
        {x=-2,y=-3},

        {x=-1,y=-2},
        {x=-2,y=-2},
        {x=2,y=-2},
        {x=3,y=-2},

        {x=-1,y=-1},
        {x=0,y=-1},
        {x=1,y=-1},
        {x=2,y=-1},

        {x=0,y=0},
        {x=1,y=0},

        {x=-1,y=1},
        {x=0,y=1},
        {x=1,y=1},
        {x=2,y=1},

        {x=-1,y=2},
        {x=-2,y=2},
        {x=2,y=2},
        {x=3,y=2},

        {x=3,y=3},
        {x=-2,y=3},
    }
    global.difficulty = {
        values = {
            period_factor = 1,
            hearts_factor = 1,
            distance_factor = 1,
            tech_rate_factor = 1,
        },
        overall = 1
    }
    global.mode = nil

    if (global.yellow_purple_order == nil) then
        if math.random() < 0.5 then
            global.yellow_purple_order = {"purple", "yellow"}
        else
            global.yellow_purple_order = {"yellow", "purple"}
        end
    end

    initGameOptions()
    initNames()
    initTechDictionary()
    initQuickStart()
end
script.on_init(initMod)

