data:extend({
    {
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "repair-pack",
                100
            },
            {
                "red-wire",
                100
            },
            {
                "green-wire",
                100
            },
            {
                "medium-electric-pole",
                100
            },
            {
                "raw-fish", -- 0 sec
                10
            },
        },
        name = "life-pods-repair-module",
        result = "life-pods-repair-module",
        type = "recipe"
    },
    {
        name = "life-pods-damage-reduction-module-1",
        result = "life-pods-damage-reduction-module-1",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-repair-module",
                1
            },
            {
                "raw-fish",
                10
            },
            {
                "electronic-circuit",
                20
            }
        }
    },
    {
        name = "life-pods-damage-reduction-module-2",
        result = "life-pods-damage-reduction-module-2",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-damage-reduction-module-1",
                1
            },
            {
                "raw-fish",
                10
            },
            {
                "advanced-circuit",
                20
            },
        }
    },
    {
        name = "life-pods-damage-reduction-module-3",
        result = "life-pods-damage-reduction-module-3",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-damage-reduction-module-2",
                1
            },
            {
                "raw-fish",
                10
            },
            {
                "processing-unit",
                20
            },
        }
    },
    {
        name = "life-pods-consumption-module-1",
        result = "life-pods-consumption-module-1",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-repair-module",
                1
            },
            {
                "medium-electric-pole",
                40
            },
            {
                "repair-pack",
                40
            },
        },
    },
    {
        name = "life-pods-consumption-module-2",
        result = "life-pods-consumption-module-2",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-consumption-module-1",
                1
            },
            {
                "medium-electric-pole",
                40
            },
            {
                "repair-pack",
                40
            },
            {
                "construction-robot",
                5
            },
        },
    },
    {
        name = "life-pods-consumption-module-3",
        result = "life-pods-consumption-module-3",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-consumption-module-2",
                1
            },
            {
                "medium-electric-pole",
                40
            },
            {
                "repair-pack",
                40
            },
            {
                "construction-robot",
                5
            },
            {
                "effectivity-module-2",
                1
            }
        },
    },
    {
        name = "life-pods-science-module-1",
        result = "life-pods-science-module-1",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-repair-module",
                1
            },
            {
                "automation-science-pack",
                5
            },
            {
                "logistic-science-pack",
                5
            },
            {
                "chemical-science-pack",
                5
            },
            {
                "military-science-pack",
                5
            },
        },
    },
    {
        name = "life-pods-science-module-2",
        result = "life-pods-science-module-2",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-science-module-1",
                1
            },
            {
                "automation-science-pack",
                5
            },
            {
                "logistic-science-pack",
                5
            },
            {
                "chemical-science-pack",
                5
            },
            {
                "military-science-pack",
                5
            },
            {
                "production-science-pack",
                5
            },
        },
    },
    {
        name = "life-pods-science-module-2-y",
        result = "life-pods-science-module-2-y",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-science-module-1",
                1
            },
            {
                "automation-science-pack",
                5
            },
            {
                "logistic-science-pack",
                5
            },
            {
                "chemical-science-pack",
                5
            },
            {
                "military-science-pack",
                5
            },
            {
                "utility-science-pack",
                5
            },
        },
    },
    {
        name = "life-pods-science-module-3",
        result = "life-pods-science-module-3",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-science-module-2",
                1
            },
            {
                "automation-science-pack",
                5
            },
            {
                "logistic-science-pack",
                5
            },
            {
                "chemical-science-pack",
                5
            },
            {
                "military-science-pack",
                5
            },
            {
                "production-science-pack",
                5
            },
            {
                "utility-science-pack",
                5
            },
        },
    },
    {
        name = "life-pods-science-module-3-y",
        result = "life-pods-science-module-3",
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                "life-pods-science-module-2-y",
                1
            },
            {
                "automation-science-pack",
                5
            },
            {
                "logistic-science-pack",
                5
            },
            {
                "chemical-science-pack",
                5
            },
            {
                "military-science-pack",
                5
            },
            {
                "production-science-pack",
                5
            },
            {
                "utility-science-pack",
                5
            },
        },
    },
})