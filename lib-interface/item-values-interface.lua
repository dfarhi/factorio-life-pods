require "table-supplement"

-- Fundamental thing we pass around:
-- {value=[value], ERROR={msg=..., punt=t/f}, no_dp={item:true}}

local recipeInterface = {
    -- getIngredients is a function that takes a recipe and returns a list of {ingredient: #}
    getIngredients = nil,
    -- getProducts is a function that takes a recipe and returns a list of {product: #}
    getProducts = nil,
}

local techInterface = {
    -- getRawLevel is a function that takes a tech and returns a level.
    getRawLevel = nil,
    -- tweakLevel is a function that takes a tech level, a tech (given by getRawLevel), and a recipe and returns a final level.
    tweakLevel = nil,
    -- getRecipes takes a tech and returns {recipename: recipe}
    getRecipes = nil,
}

local valuesInterface = {
    -- combineValues is a function that takes a list of {ingredientname: value} and {ingredientname: amount} and returns a single value.
    --    "value" can be any type.
    combineValues = nil,
    -- splitValues is a function that takes a value and a list of {productname: amount} and returns {productname: value}
    splitValues = nil,
    -- valueBetter takes two values and compares them (returns true if the first is better *or equal*).
    valueBetter = nil,
    maxValue = nil,
}

local function simplifyStack(stack)
    -- stack is {item: recipe}
    -- return {item: recipename}
    local result = {}
    for itemname, details in pairs(stack) do
        if type(details) == "table" then
            result[itemname] = details.recipe.name
        end
    end
    return result
end

function itemValuesProcessorInterface(techInterface, recipeInterface, valuesInterface, isValidFinalItem, debugPrinting, detectRunawayLoops, strictMode)
    -- isValidFinalItem takes an itemname and returns whether or not it is a valid thing to demand.
    -- debugPrinting is a boolean about whether to print everything.
    -- detectRunawayLoops is whether to look out for runaway loops. This makes it much slower.
    -- strictMode is whether to error on various minor problems.
    -- An environment object is:
    -- {
    --   unprocessed_recipes_by_product={product={r1=recipe, r2=recipe, ...}, ...},
    --   values_table = {product = value, ...}; includes previous level values and this level values.
    --   product_stack = {product={recipe=recipe}, ...}
    --   punt_destination = location to append recipes that we can't make
    --   guarantee_no_breakable_loops = Are we certain there are no breakable loops, and thus all values can be stored.
    -- }

    local function strictModeError(msg)
        if strictMode then
            error(msg .. "\n\nSet the Mod Compatibility Setting to 'loose' to load anyway.")

        end
    end

    local function printTabbed(msg, stack)
        if not debugPrinting then return end
        local spaces = {}
        for _, _ in pairs(stack) do
            table.insert(spaces, " ")
        end
        print(table.concat(spaces, "") .. msg)
    end

    local lib = {}

    lib.processAllTechs = function(techs, ordered_levels, base_values)
        -- techs are {techname: tech, ...}
        -- ordered levels is a list of level names
        -- base_values is the value of raw resources {itemname: value, ...}
        -- returns {levelname: {product: value, ...}, ...}

        local working_values = table.onelevelcopy(base_values)
        local recipes_at_level = lib.splitRecipesByLevel(techs, ordered_levels)
        -- recipes_at_level is like {levelname: {recipename: recipe, ...}, ...}
        recipes_at_level["mystery"] =  {} -- One final level for things punted off the end.

        -- recipes_at_prior_levels is the same structure as recipes_at_level, just only the lower levels.
        local recipes_at_prior_levels = {}
        local final_values_by_level = {}
        local num_checked_last_level = 0 -- Are we computing too much?
        for i, levelname in ipairs(ordered_levels) do
            print("-------------------------------")
            print("Processing level: " .. levelname)
            print("-------------------------------")
            local recipes_at_this_level = recipes_at_level[levelname]
            local lower_level_recipes_to_compute
            if num_checked_last_level > 3000 then
                strictModeError("Other mods are too complex for Life Pods. (Overload mode at level " .. levelname .. ").")
                lower_level_recipes_to_compute = {}
            else
                lower_level_recipes_to_compute = recipes_at_prior_levels
            end
            local punt_level = ordered_levels[i+1]
            if i == #ordered_levels then punt_level = "mystery" end
            local punt_destination = recipes_at_level[punt_level]
            local recipes_checked
            final_values_by_level[levelname], recipes_checked = lib.processAllRecipes(lower_level_recipes_to_compute, recipes_at_this_level, working_values, punt_destination)
            num_checked_last_level = math.max(num_checked_last_level, table.sumValues(recipes_checked))
            table.insert(recipes_at_prior_levels, recipes_at_this_level)
        end
        -- error("Permanently invalid recipes: " .. table.tostring(table.keys(recipes_at_level["mystery"])))
        print("-------------------------------")
        print("Processing final level")
        print("-------------------------------")
        if num_checked_last_level < 3000 then
            final_values_by_level.final = lib.processAllRecipes({}, table.union(recipes_at_prior_levels),  table.onelevelcopy(base_values), {})
        else
            strictModeError("Other mods are too complex for Life Pods. (Overload mode at level final.")
            final_values_by_level.final = working_values
        end
        return final_values_by_level
    end

    lib.splitRecipesByLevel = function(techs, ordered_levels)
        local recipes_at_level = {}
        for i, levelname in ipairs(ordered_levels) do
            recipes_at_level[levelname] = {}
        end
        for techname, tech in pairs(techs) do
            print("Recipes from tech: " .. techname)
            local recipes = techInterface.getRecipes(tech)
            if not table.isEmpty(recipes) then
                local raw_level = techInterface.getRawLevel(tech)
                for recipename, recipe in pairs(recipes) do
                    local final_level = techInterface.tweakLevel(raw_level, tech, recipe)
                    print("  Recipe " .. recipename ..": " .. final_level)
                    recipes_at_level[final_level][recipename] = recipe
                end
            end
        end
        return recipes_at_level
    end


    local recipes_checked = {}
    lib.processAllRecipes = function(intermediate_recipes, final_product_recipes, values_table, punt_destination, error_recipes_checked)
        -- intermediate recipes are recipes usable at this level, but which we should not demand as final products.
        --   this is a list of lists; recipes from each prior level.
        -- final_product_recipes are recipes we can demand.
        -- values_table has the values from previous levels and raw materials.
        -- punt_destination is where we put recipes we can't make yet, which might become makeable at higher levels.
        -- error_recipes_checked is a stupid debugging boolean; if true, display what recipes are checked many times.
        -- Take all items produced by final_product_recipes, compute their value.
        -- If it's better than values_table (how easy it was to make before), then return it.
        -- Returns {product: value, ...}
        -- This modifies values_table in place to include the new values.

        recipes_checked = {}

        -- We're going to modify values_table, so keep a copy around for comparisons.
        local old_values_table = table.onelevelcopy(values_table)
        local recipes_by_product = {}
        -- Sort all recipes (final or intermediate) by product.
        -- Also keep a list of all final products.
        local final_products = lib.collateRecipesByProduct({final_product_recipes}, recipes_by_product)
        lib.collateRecipesByProduct(intermediate_recipes, recipes_by_product)

        -- We want to iterate the items that can be made in the most different ways first, for efficiency to do w loops
        local counts = {}
        for k, v in pairs(recipes_by_product) do
            counts[k] = table.count(v)
        end
        table.filter(counts, function(recipes) return recipes > 1 end)
        local hottest_items = table.keysSortedByValues(counts, function(x, y) return x > y end)
--        if table.count(counts) > 30 then
--            local all_recipes = {}
--            for name, count in pairs(counts) do
--                all_recipes[name .. "(" .. count .. ")"] = table.keys(recipes_by_product[name])
--            end
--            error("Hot items (" .. table.count(counts) .. "): " .. table.tostring(counts) .. "\n\n\nRecipes:  " .. table.tostring(all_recipes))
--        end
--        local num_hot = table.count(counts) -- for debugging
--        local count = 0 -- for debugging
        for _, product in ipairs(hottest_items) do
--            if num_hot > 30 and count > 2 then error(product) end
--            if product == "empty-barrel" then
--                recipes_by_product[product] = nil
--                values_table[product] = {resources = 1}
--            end
            local env = {
                unprocessed_recipes_by_product=recipes_by_product,
                values_table = values_table,
                product_stack = {[product]=true},
                punt_destination = punt_destination,
                guarantee_no_breakable_loops = false}
            lib.productValueFromAllRecipes(product, env)

            --count = count + 1
            --if num_hot > 30 then error(table.tostring(recipes_checked)) end

        end

        -- Now we have dealt with all items that can be made in multiple ways.
        -- That means there are no remaining breakable loops, since every node has only one incoming edge.
        -- recipes_by_product = {product: {recipename: recipe, ...}, ...}
        -- final_products = {product= true}
        -- error("final_products: " .. table.tostring(final_products))
        for product, _ in pairs(final_products) do
            if isValidFinalItem(product) then
                print("Beginning Computation Tree at product: " .. product)
                -- print("values_table: " .. table.tostring(values_table))
                local env = {
                    unprocessed_recipes_by_product=recipes_by_product,
                    values_table = values_table,
                    product_stack = {[product]=true},
                    punt_destination = punt_destination,
                    guarantee_no_breakable_loops = true }
                local current_value = lib.productValueFromAllRecipes(product, env).value
                if current_value and (old_values_table[product] == nil or not valuesInterface.valueBetter(old_values_table[product], current_value)) then
                    print("Final value of " .. product .. ": " .. table.tostring(current_value))
                    final_products[product] = current_value
                else
                    print("Item " .. product .. " can be built better with previous recipes!")
                    final_products[product] = nil
                end
            else
                print("Item " .. product .. " is not a valid final item!")
                final_products[product] = nil
            end
        end

        local recipes_checked_duplictes = {}
        for k, v in pairs(recipes_checked) do
            if v > 1 then recipes_checked_duplictes[k] = v end
        end
        if error_recipes_checked then error(table.sumValues(recipes_checked) .. ": " .. table.tostring(recipes_checked_duplictes)) end
        return final_products, recipes_checked
    end

    lib.collateRecipesByProduct = function(recipes, target_table)
        -- target_table should be a table of {productname: {recipename: recipe}}
        -- inserts all recipes from the recipes argument into the appropriate slot in target_table
        -- recipes is a list of lists; {{r1, r2}, {r3, r4}}
        -- Modifies target_table in place and returns a set of products touched.

        local products = {}
        for _, tab in pairs(recipes) do
        for recipenamename, recipe in pairs(tab) do
            for productname, amount in pairs(recipeInterface.getProducts(recipe)) do
                products[productname] = true
                if not target_table[productname] then target_table[productname] = {} end
                target_table[productname][recipenamename] = recipe
            end
        end
        end
        return products
    end

    lib.productValueFromAllRecipes = function(product, env)
        printTabbed("Computing value of product: " .. product .. " with stack: " .. table.tostring(env.product_stack), env.product_stack)

        --if table.count(env.product_stack) > 10 then error(table.tostring(simplifyStack(env.product_stack))) end

        if env.unprocessed_recipes_by_product[product] == nil then
            -- We've already done this one through a recursive call. No need to do it again.
            return {value=env.values_table[product]}
        end
        -- If it could already be produced or is a basic resource, it might have a value.
        local best_value = env.values_table[product]

        -- no_dp stores items which are part of a loop. If anything in here is in the call stack, we can't store results
        -- for dynamic programming, because we may have cut a loop in the wrong place.
        local no_dp = {}
        for recipename, recipe in pairs(env.unprocessed_recipes_by_product[product]) do
            --  print("Processing one recipe:")
            --  print("  unprocessed_recipes_by_product: " .. table.tostring(unprocessed_recipes_by_product[product]))
            --  print("  values_table: " .. table.tostring(values_table))
            local val_with_metadata = lib.productValueFromRecipe(product, recipe, env)
            --  print("  val: " .. table.tostring(val_with_metadata))
            if val_with_metadata.ERROR then
                printTabbed("Recipe " .. recipename .. " is invalid.", env.product_stack)
            elseif best_value == nil or valuesInterface.valueBetter(val_with_metadata.value, best_value) then
                best_value = val_with_metadata.value
            end
            if val_with_metadata.no_dp then
                for itemname, _ in pairs(val_with_metadata.no_dp) do
                    no_dp[itemname] = true
                end
            end
        end

        printTabbed("Value of product " .. product .. " is " .. table.tostring(best_value), env.product_stack)
        -- best_value might still be nil, if there was no valid recipe.
        -- The following is still correct behavior; values_table entry should not exist and item marked as processed if that's really best.

        -- We want to store the result *if* it isn't part of a loop.
        -- When we encounter a loop, we mark the loop item in the no_dp table.
        -- If anything from no_dp is in the product_stack, then we can't store this result, as it may be improvable.
        -- There's some funny off-by-one business about if the product in question is in no_dp.
        -- That's generally fine, since it means we started the search at this item.
        -- We encountered a loop but we can't do better than starting at the product itself.
        -- However, we don't want to store those results anyway, just to be safe, for the runaway detection logic.
        -- But we *do* want to store those if they are punts, since otherwise we miss punts.
        local store_result = true
        local store_punt = true
        for loop_item, _ in pairs(no_dp) do
            if env.product_stack[loop_item] then
                if product ~= loop_item then
                    store_punt = false
                end
                if product ~= loop_item or detectRunawayLoops then
                    printTabbed("Not storing due to loop: " .. loop_item, env.product_stack)
                    store_result = false
                end
            end
        end

        -- remove it from the stack.
        env.product_stack[product] = nil

        if best_value then
            if store_result then
                -- There were no loops and we got a valid value. Store the result.
                printTabbed("Storing: " .. product .. "= " .. table.tostring(best_value), env.product_stack)
                env.values_table[product] = best_value
                env.unprocessed_recipes_by_product[product] = nil
            end
            return {value=best_value, no_dp=no_dp }
        else
            if store_punt then
                -- There were no loops but we were unable to produce the product. Punt to next level
                printTabbed("Punting: " .. product .. ".", env.product_stack)
                for k,v in pairs(env.unprocessed_recipes_by_product[product]) do env.punt_destination[k] = v end
                env.unprocessed_recipes_by_product[product] = nil
            end
            return {ERROR={msg="nil value.", fatal=false}, no_dp=no_dp }
        end
    end

    lib.productValueFromRecipe = function(product, recipe, env)
        if env.product_stack[product] == nil then error("Computing something not on the stack!") end
        env.product_stack[product] = {recipe=recipe}

        -- TODO avoid repeating work by recomputing the same recipe again for each product.
        local total_value_with_metadata = lib.totalRecipeValue(recipe, env)
        -- print("Total Value: " .. table.tostring(total_value))
        if total_value_with_metadata.ERROR then return total_value_with_metadata end
        local products = recipeInterface.getProducts(recipe)
        local product_values = valuesInterface.splitValues(total_value_with_metadata.value, products)

        return {value = product_values[product], no_dp = total_value_with_metadata.no_dp}
    end

    lib.totalRecipeValue = function(recipe, env)
        if recipes_checked[recipe.name] == nil then recipes_checked[recipe.name] = 1 else recipes_checked[recipe.name] = recipes_checked[recipe.name] + 1 end
        printTabbed("Evaluating recipe: " .. recipe.name, env.product_stack)

        local ingredients = recipeInterface.getIngredients(recipe)
        if table.isEmpty(ingredients) then
            return {ERROR = {msg = "No ingredients at all in recipe: " .. recipe.name, punt=false, fatal=true}}
        end
        for ingredient, amount in pairs(ingredients) do
            if env.product_stack[ingredient] then
                -- if env.guarantee_no_breakable_loops then error("You lied!") end
                -- We are in a loop!
                printTabbed("Loop detected! Offending ingredient: " .. ingredient .. ";  Loop involves a subset of: " .. table.concat(table.keys(env.product_stack), ", "), env.product_stack)
                return  {ERROR = {msg = "Loop Detected; " .. ingredient .. " in stack.", punt=false, fatal=false},  no_dp = {[ingredient] = true}}
            end
        end

        local values = {}
        local no_dp = {}

        for itemname, _ in pairs(ingredients) do
            local value_with_metadata = lib.ingredientValue(itemname, recipe, env)

            if value_with_metadata.ERROR and value_with_metadata.ERROR.fatal then
                -- Fatal error; this recipe is total crap and should never be used.
                return value_with_metadata
            end
            if value_with_metadata.no_dp then
                for ndp_item, _ in pairs(value_with_metadata.no_dp) do
                    no_dp[ndp_item] = true
                end
            end
            if value_with_metadata.ERROR then
                -- We don't punt usually, *unless* this is the outermost call - in that case there is no recovering.
                return {ERROR={msg = "Error in ingredients.", fatal=false, punt=table.count(env.product_stack)==1}, no_dp = no_dp }
            end

            values[itemname] = value_with_metadata.value
        end

        local result = {value = valuesInterface.combineValues(values, ingredients), no_dp = no_dp }
        if valuesInterface.valueBetter(result.value, valuesInterface.maxValue) then
            return result
        else
            return {ERROR = {msg = "Recipe exceeds max value: " .. recipe.name, punt=false, fatal=true}}
        end
    end

    lib.ingredientValue = function(ingredient, for_recipe, env)
        if env.unprocessed_recipes_by_product[ingredient] then
            -- This product has recipes at this level. Better compute them first.
            printTabbed("Recursive call: processing " ..  ingredient, env.product_stack)
            env.product_stack[ingredient] = true
            return lib.productValueFromAllRecipes(ingredient, env)
        end

        if env.values_table[ingredient] then
            return {value=env.values_table[ingredient]}
        end

        return {ERROR = {msg = "Ingredient cannot be produced " .. ingredient, punt=true, fatal=true}}
    end

    return lib
end



