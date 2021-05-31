--
-- For general infra things not related to actual gameplay.

local setupCommands, setMode, setDifficulty, setRescue, setInfinityMode, tweakDifficulty

function initGameOptions()
    setupCommands()
    setMode()
    setDifficulty()
end

setupCommands = function()
    if remote.interfaces["lifepods settings"] then return end
    remote.add_interface("lifepods settings", {
        recalculate = setup,
        get = function ()
            printAllPlayers("Mode: " .. global.mode)
            printAllPlayers("Difficulty: " .. global.difficulty.overall)
            for name, value in pairs(global.difficulty.values) do
                debugPrint(name .. ": " .. value)
            end
        end,
        tweak = function(name, value)
            tweakDifficulty(name, value)
        end
    })
end
script.on_load(function(event)
    setupCommands()
end)

setDifficulty = function()
    local difficulty_string = settings.global["life-pods-difficulty-choice"].value
    global.difficulty.overall = CONFIG.difficulty_values[difficulty_string]
    if #game.connected_players > 1 and settings.global["life-pods-difficulty-scales-with-players"].value then
        global.difficulty.overall = global.difficulty.overall + #game.connected_players
    end
    printAllPlayers({"lifepods.setting-difficulty", global.difficulty.overall})
    for name, _ in pairs(global.difficulty.values) do
        global.difficulty.values[name] = CONFIG.difficulty[name]^(global.difficulty.overall)
    end

end
script.on_event(defines.events.on_player_joined_game, function(event) setDifficulty() end)
script.on_event(defines.events.on_player_left_game, function(event) setDifficulty() end)

local tweakDifficulty = function(type, value)
    global.difficulty.values[type] = value
end

setMode = function()
    local setting = settings.global["life-pods-mode"].value
    printAllPlayers({"lifepods.setting-mode", settings.global["life-pods-mode"].value})
    if (setting == "rocket") then
        setRocketMode()  -- TODO: This doesn't need its own function anymore.
    elseif (setting == "infinity") then
        setInfinityMode()
    elseif (setting == "rescue") then
        setRescue(settings.global["life-pods-rescue-time"].value)
    end
end
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if (event.setting == "life-pods-mode" or event.setting == "life-pods-rescue-time") then
        setMode()
    end
    if (event.setting == "life-pods-difficulty-choice" or event.setting == "life-pods-difficulty-scales-with-players") then
        setDifficulty()
    end
end)
setRescue = function(hours)
    global.mode = "rescue"
    global.rescueTick = hours * TICKS_PER_HOUR
    displayGlobalPop()
end
setRocketMode = function()
    global.rescueTick = nil
    global.mode = "rocket"
    for _, player in pairs(game.players) do
        if top_ui(player).rescue then
            top_ui(player).rescue.caption = ""
        end
    end
    displayGlobalPop()
end
setInfinityMode = function()
    global.rescueTick = nil
    global.mode = "infinity"
    for _, player in pairs(game.players) do
        if top_ui(player).rescue then
            top_ui(player).rescue.caption = ""
        end
    end
    displayGlobalPop()
end

