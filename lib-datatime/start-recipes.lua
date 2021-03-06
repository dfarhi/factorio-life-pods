require "config"
require "table-supplement"
require "tech-level-datatime"

local function recipeStartsActive(recipe)
    return (recipe.enabled == nil or recipe.enabled == "true" or recipe.enabled == true) and not recipe.hidden
end

local start_recipes = {}
for name, recipe in pairs(data.raw.recipe) do
    if recipe.normal then recipe = recipe.normal end
    if recipeStartsActive(recipe) then
        start_recipes[name] = recipe
    end
end

local raw_material_dummy_recipes = {} -- {lvl: recipe}

local function add_base_value(item, value, mining_time, level, fluid_input)
    if raw_material_dummy_recipes[level] == nil then raw_material_dummy_recipes[level] = {} end
    raw_material_dummy_recipes[level][item] = {
        name = "RAW-"..item,
        ingredients = {{name="raw-value", amount=value}, fluid_input},
        energy_required = mining_time,
        result = item,
        result_count = 1
    }
end

local function getMinRecipeTechLevel(recipes_set)
    for name, _ in pairs(recipes_set) do
        if data.raw.recipe[name] and recipeStartsActive(data.raw.recipe[name]) then
            return "start"
        end
    end
    local level
    -- Assume the recipe to make the miner is named the same as the miner itself.
    -- TODO scan items, then recipes, to find the one corresponding to this entity.
    for _, tech in pairs(data.raw.technology) do
        if tech.effects then
            for _, eff in pairs(tech.effects) do
                if eff.type == "unlock-recipe" and recipes_set[eff.recipe] then
                    local new_level = getTechLevel(tech)
                    if level == nil then
                        level = new_level
                    else
                        level = techLevelMin(level, getTechLevel(tech))
                    end
                end
            end
        end
    end
    return level
end

local function getResourceTechLevel(resource)
    local category = resource.category or "basic-solid"
    local mines = {}
    for _, miner in pairs(data.raw["mining-drill"]) do
        for _, minable_cat in pairs(miner.resource_categories) do
            if minable_cat == category then
                mines[miner.name] = true
            end
        end
    end
    local level = getMinRecipeTechLevel(mines)
    if level == nil then
        if settings.startup["life-pods-debug"].value == "strict" then
            error("Can't figure out how you mine: " .. resource.name .. "\n\n" .. "Set the Mod Compatibility Setting to 'loose' to continue despite this error." .. "\n\nDebug:\n".. table.tostring(resource))
        end
        return nil
    end

    -- Resources you don't start with can't come too early.
    if resource.name == 'crude-oil' then level = techLevelMax(level, "green") end
    if resource.name == 'uranium-ore' then level = techLevelMax(level, "blue") end
    if level then return level end
end

for name, pump in pairs(data.raw["offshore-pump"]) do
    local level = getMinRecipeTechLevel({[name]=true})
    if level then
        add_base_value("water", CONFIG.RAW_ITEM_VALUES["water"], 1/ (TICKS_PER_SECOND * pump.pumping_speed), level)
    end
end

for name, resource in pairs(data.raw.resource) do
    if resource.minable and resource.autoplace then

        -- Formula from https://wiki.factorio.com/Mining#Mining_Speed_Formula
        -- based on electric mining drill's 3 mining power and 0.5 mining speed
        local time = resource.minable.mining_time
        -- Assign level based on when we can make an entity that can produce it.
        local fluid_inputs
        local value = CONFIG.RAW_ITEM_VALUES[name] or 1
        local level = getResourceTechLevel(resource)
        if level then
            if resource.minable.required_fluid then
                -- fluid_amount is the amount needed to mine 10 units.
                fluid_inputs = {name=resource.minable.required_fluid, amount=resource.minable.fluid_amount / 10}
            end
            if resource.minable.result then
                add_base_value(resource.minable.result, value, time, level, fluid_inputs)
            elseif resource.minable.results then
                for _, item in pairs(resource.minable.results) do
                    local amount = 1
                    if item.amount_max then
                        amount = (item.amount_max + item.amount_min) / 2
                    end
                    add_base_value(item.name, value/amount, time, level, fluid_inputs)
                end
            end
        end
    end
end
--error(table.tostring(raw_material_dummy_recipes))

function addStartRecipes(techs)
    -- Create a dummy tech to unlock all basic recipes at level "start"
    techs["dummy_start_tech"] = {
        name = "dummy_start_tech",
        dummy_tech_level = "start",
        unit = {ingredients = {}},
        effects = {}
    }
    for name, recipe in pairs(start_recipes) do
        techs["dummy_start_tech"].effects[name] = {
            type = "unlock-recipe",
            recipe = name
        }
    end

    for level, raw_recipes in pairs(raw_material_dummy_recipes) do
        local tech_name = "dummy_resource_tech-"..level
        techs[tech_name] = {
            name = tech_name,
            dummy_tech_level = level,
            unit = {ingredients = {}},
            dummy_recipes = raw_recipes
        }
    end
end