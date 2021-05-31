require "lifepods-utils"

local ALL_NAMES = {
    --Book Characters
    "Wiggin",
    "Vorkosigan",
    "Dent",  --Hitchiker's Guide
    "Chanur",
    "Cameron",
    "Lambert",
    "Atreides",
    "Nuwen",
    "Arroway", -- Contact
    "Gobuchul", -- Culture Series I guess.
    "Watney", -- Martian
    "Creideiki", -- Uplift braindead guy
    "Perceval", -- Dust??
    "Calvin", -- I, Robot

    --Book Planets
    "Trantor",
    "Anarres", -- Le Guin something.

    --Movies/Show Characters
    "Skywalker",
    "Kirk",
    "Picard",
    "Reynolds",
    "Sheridan",
    "Roslin",
    "Cooper",

    --Movie/Show Planets
    "Gallifrey",

    -- Real People
    "Armstrong",
    "Aldrin",
    "Gagarin",

    -- Real Planets
    "Earth",
    "Mars",
    "Centauri",
}

local SUFFIXES = {"", " Jr", " III", " IV"}
local function suffixFromEpoch(epoch)
    if epoch <= #SUFFIXES then return SUFFIXES[epoch] end
    return " " .. epoch
end

function initNames()
    global.podNames = shuffle(ALL_NAMES)
    global.podEpoch = 1
end

function getNextPodName()
    global.nextLifePod.name = global.podNames[#global.podNames] .. suffixFromEpoch(global.podEpoch)
    global.podNames[#global.podNames] = nil
    if #global.podNames == 0 then
        --debugPrint("Recycling names")
        global.podNames = shuffle(ALL_NAMES)
        global.podEpoch = global.podEpoch + 1
    end
end

