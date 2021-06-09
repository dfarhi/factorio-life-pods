data:extend(
{
    {
        type = "tips-and-tricks-item-category",
        name = "life-pods",
        order = "a-[scenario]"
    },
    {
        type = "tips-and-tricks-item",
        name = "life-pods-intro",
        order = "a",
        starting_status = "unlocked",
        category = "life-pods",
        is_title = true,
        trigger =
        {
            type = "time-elapsed",
            ticks = 60 -- 1 second
        },
    },
    {
        type = "tips-and-tricks-item",
        category = "life-pods",
        indent=1,
        name = "life-pods-humans",
        order = "b",
        tag="[virtual-signal=life-pod-alive]",
        starting_status = "unlocked",
        image = "__life-pods__/graphics/tips-and-tricks-humans-ui.png",
        trigger =
        {
            type = "time-elapsed",
            ticks = 60 -- 1 second
        },
    },
    {
        type = "tips-and-tricks-item",
        category = "life-pods",
        indent=1,
        name = "life-pods-feeding",
        tag = "[entity=life-pod-repair][fluid=pod-health]",
        order = "c",
        image = "__life-pods__/graphics/tips-and-tricks-feeding.png",
        trigger =
        {
            -- TODO: When pod lands
            type = "time-elapsed",
            ticks = 60 -- 1 second
        },
    },
    {
        type = "tips-and-tricks-item",
        category = "life-pods",
        indent=1,
        name = "life-pods-damage",
        order = "d",
        tag = "[virtual-signal=life-pod-alive][virtual-signal=life-pod-injured][virtual-signal=life-pod-dead]",
        starting_status = "unlocked",
        image = "__life-pods__/graphics/tips-and-tricks-damage.png",
        trigger =
        {
            -- TODO: When pod lands
            type = "time-elapsed",
            ticks = 60 -- 1 second
        },
    },
    {
        type = "tips-and-tricks-item",
        category = "life-pods",
        indent=1,
        name = "life-pods-radar",
        order = "e",
        starting_status = "unlocked",
        tag = "[entity=radar]",
        image = "__life-pods__/graphics/tips-and-tricks-radar.png",
        trigger =
        {
            type = "time-elapsed",
            ticks = 60 * 60 * 60 * 1 -- 1 hour
        },
    },
    {
        type = "tips-and-tricks-item",
        category = "life-pods",
        indent=1,
        name = "life-pods-h-menu",
        order = "f",
        starting_status = "unlocked",
        image = "__life-pods__/graphics/tips-and-tricks-h.png",
        trigger =
        {
            type = "time-elapsed",
            ticks = 60 * 60 * 60 * 2 -- 2 hours
        },
    },
    {
        type = "tips-and-tricks-item",
        category = "life-pods",
        indent=1,
        name = "life-pods-speedup",
        order = "g",
        starting_status = "unlocked",
        image = "__life-pods__/graphics/tips-and-tricks-speedup.png",
        tag = "[entity=assembling-machine-2]",
        trigger =
        {
            type = "research",
            technology = "automation-2"
        },
    },
    {
        type = "tips-and-tricks-item",
        category = "life-pods",
        indent=1,
        name = "life-pods-stabilization-nudge",
        order = "h1",
        starting_status = "unlocked",
        image = "__life-pods__/graphics/tips-and-tricks-stabilization-tech.png",
        tag = "[item=life-pods-repair-module]",
        trigger =
        {
            type = "time-elapsed",
            ticks = 60 * 60 * 60 * 3 -- 2 hours
        },
        skip_trigger = {
            type = "research",
            technology = "life-pods-repair-module"
        },
    },
    {
        type = "tips-and-tricks-item",
        category = "life-pods",
        indent=1,
        name = "life-pods-stabilization",
        order = "h2",
        starting_status = "unlocked",
        image = "__life-pods__/graphics/tips-and-tricks-stabilization.png",
        tag = "[item=life-pods-repair-module]",
        trigger = {
            type = "research",
            technology = "life-pods-repair-module"
        },
    },
    {
        type = "tips-and-tricks-item",
        category = "life-pods",
        indent=1,
        name = "life-pods-stabilization-advanced",
        order = "h3",
        starting_status = "unlocked",
        image = nil, --TODO
        tag = "[item=life-pods-damage-reduction-module-1][item=life-pods-consumption-module-1][item=life-pods-science-module-1]",
        trigger = {
            type = "research",
            technology = "life-pods-enhanced-modules-1"
        },
    },
    -- Maybe add:
    --   science progression of required items
    --   Rescue; endgame speedup
    --   Rocket
    --   Human dies
})
