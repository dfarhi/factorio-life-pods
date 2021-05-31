require("config")

data:extend({
    {
        type = "string-setting",
        name = "life-pods-difficulty-choice",
        setting_type = "runtime-global",
        default_value = "Normal",
        allowed_values = CONFIG.difficulty_names,
        order = "difficulty-1"
    },
    {
        type = "bool-setting",
        name = "life-pods-difficulty-scales-with-players",
        setting_type = "runtime-global",
        default_value = true,
        order = "difficulty-2"
    },
    {
        type = "string-setting",
        name = "life-pods-mode",
        setting_type = "runtime-global",
        default_value = "rocket",
        allowed_values = {"rocket", "rescue", "infinity"},
        order = "mode-1"
    },
    {
        type = "double-setting",
        name = "life-pods-rescue-time",
        setting_type = "runtime-global",
        default_value = 20,
        order = "mode-2"
    },
    {
        type = "bool-setting",
        name = "life-pods-quick-start",
        setting_type = "runtime-global",
        default_value = false,
        order = "mode-3"
    },
    {
        type = "string-setting",
        name = "life-pods-mod-compatibility-mode",
        setting_type = "startup",
        default_value = "strict",
        allowed_values = {"strict", "loose"},
        order = "Z-meta"
    },
    {
        type = "bool-setting",
        name = "life-pods-debug",
        setting_type = "startup",
        default_value = false,
        order = "Z-meta"
    },
})

