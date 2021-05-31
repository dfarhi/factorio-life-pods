--
-- To run, get the Lua standalone interpreter, then run:
-- > lua item-values-test.lua


require "lib-interface.item-values-interface"
require "table-supplement"
require "testing"

local testRecipeImpl = {
    getIngredients = function (recipe)
        return recipe.ingredients
    end,
    getProducts = function(recipe)
        return recipe.products
    end
}
function testValue(n)
    return {value=n}
end
basicTestValues = function() return {thing1=testValue(1), thing2=testValue(2)} end
local valuesImpl = {
    combineValues = function(values, amounts)
        local total = 0
        for name, amount in pairs(amounts) do
            if values[name] ==  nil then error("Invalid combine; missing key " .. name) end
            total = total + amount * values[name].value
        end
        return testValue(total)
    end,
    splitValues = function (value, amounts)
        local each = value.value
        local result = {}
        for name, amount in pairs(amounts) do
            result[name] = testValue(each / amount)
        end
        return result
    end,
    valueBetter = function(a, b)
        return a.value <= b.value
    end,
    maxValue = testValue(50000),
}

local testTechImpl = {
    getRawLevel = function(tech)
        return tech.level
    end,
    tweakLevel = function (level, tech, recipe)
        if recipe.level then return recipe.level end
        return level
    end,
    getRecipes = function(tech)
        return tech.recipes
    end
}

function testIsValidFinalItem(item)
    return true
end

fix = fixture()
testProcessor = itemValuesProcessorInterface(testTechImpl, testRecipeImpl, valuesImpl, testIsValidFinalItem, true, false)

test("ingredientValueFromDP", fix, function(asserts)
    local env = {
        unprocessed_recipes_by_product={},
        values_table = {thing=3},
        product_stack = {}}
    local result = testProcessor.ingredientValue("thing", nil, env)
    asserts.expectEqual(result.value, 3)
end)

test("ingredientValue Not Possible", fix, function(asserts)
    local env = {
        unprocessed_recipes_by_product={},
        values_table = {other=3},
        product_stack = {},
        punt_destination = {}}
    local result = testProcessor.ingredientValue("thing", nil, env)
    asserts.expectNotNil(result.ERROR)
end)

test("totalRecipeValue basic", fix, function(asserts)
    local env = {
        unprocessed_recipes_by_product={},
        values_table = basicTestValues(),
        product_stack = {}}
    local recipe = {
        name = "rec",
        ingredients = {thing1=3, thing2=1},
        products = {}
    }
    local result = testProcessor.totalRecipeValue(recipe, env)
    asserts.expectValueEqual(result.value, 5)
end)

test("totalRecipeValue error (no ingredients)", fix, function(asserts)
    local env = {
        unprocessed_recipes_by_product={},
        values_table = basicTestValues(),
        product_stack = {},
        punt_destination = {}}
    local recipe = {
        name = "rec",
        ingredients = {},
        products = {}
    }
    local result = testProcessor.totalRecipeValue(recipe, env)
    asserts.expectNotNil(result.ERROR)
end)

test("totalRecipeValue error (can't make)", fix, function(asserts)
    local env = {
        unprocessed_recipes_by_product={},
        values_table = basicTestValues(),
        product_stack = {},
        punt_destination = {}}
    local recipe = {
        name = "rec",
        ingredients = {thing1=3, impossible=1},
        products = {}
    }
    local result = testProcessor.totalRecipeValue(recipe, env)
    asserts.expectNotNil(result.ERROR)
end)

test("productValueFromRecipe basic", fix, function(asserts)
    local env = {
        unprocessed_recipes_by_product={},
        values_table = basicTestValues(),
        product_stack = {p=true},
        punt_destination = {}}
    local recipe = {
        name = "rec",
        ingredients = {thing1=4, thing2=1},
        products = {p=3, q=1}
    }
    local result = testProcessor.productValueFromRecipe("p", recipe, env)
    asserts.expectValueEqual(result.value, 2)
end)

test("productValueFromRecipe error", fix, function(asserts)
    local env = {
        unprocessed_recipes_by_product={},
        values_table = basicTestValues(),
        product_stack = {p=true},
        punt_destination = {}}
    local recipe = {
        name = "rec",
        ingredients = {thing1=3, impossible=1},
        products = {p=2, q=1}
    }
    local result = testProcessor.productValueFromRecipe("p", recipe, env)
    asserts.expectNotNil(result.ERROR)
end)

test("productValueFromAllRecipes", fix, function(asserts)
    local recipes = {prod = {
        FromT1 = {name = "FromT1", products = {prod=1}, ingredients = {thing1=3}},
        FromT2 = {name = "FromT2", products = {prod=2}, ingredients = {thing2=2}},
    }, ignorethis={} }
    local env = {
        unprocessed_recipes_by_product=recipes,
        values_table = basicTestValues(),
        product_stack = {prod=true},
        punt_destination = {}}
    testProcessor.productValueFromAllRecipes("prod", env)
    asserts.expectTableValuesEqual(env.values_table.prod, testValue(2))
    asserts.expectEqual(recipes.prod, nil)
end)
test("productValueFromAllRecipes punt", fix, function(asserts)
    local recipe = {name = "recipe", products = {product=1}, ingredients = {impossible=1}}
    local env = {
        unprocessed_recipes_by_product={product = {recipe = recipe}},
        values_table = basicTestValues(),
        product_stack = {product=true},
        punt_destination = {}}
    testProcessor.productValueFromAllRecipes("product", env)
    asserts.expectTableValuesEqual(env.punt_destination, {recipe=recipe})
    asserts.expectEqual(env.unprocessed_recipes_by_product.product, nil)
    asserts.expectEqual(env.values_table.product, nil)
end)
test("productValueFromAllRecipes gear", fix,  function(asserts)
    local values = {ironplate=testValue(1), copperplate=testValue(2)}
    local recipes = {gear = {gear = {name = "gear", products={gear=1}, ingredients = {ironplate=2}}} }
    local env = {
        unprocessed_recipes_by_product=recipes,
        values_table = values,
        product_stack = {gear=true},
        punt_destination = {}}
    testProcessor.productValueFromAllRecipes("gear", env)
    asserts.expectTableValuesEqual(env.values_table.gear, testValue(2))
    asserts.expectEqual(env.unprocessed_recipes_by_product.gear, nil)
end)

test("collateRecipesByProduct from scratch", fix, function(asserts)
    local recipes = {{
        Recipe1 = {name = "Recipe1", products = {thing1=1}},
        Recipe2 = {name = "Recipe2", products = {thing2=1}},
        Recipe3 = {name = "Recipe3", products = {thing1=1, thing2=2}},
    }}
    local result = {}
    local output = testProcessor.collateRecipesByProduct(recipes, result)
    print(table.tostring(output))
    asserts.expectTableValuesEqual(output, {thing1=true, thing2=true})
    local expected = {
        thing1={Recipe1=recipes[1].Recipe1, Recipe3=recipes[1].Recipe3},
        thing2={Recipe2=recipes[1].Recipe2, Recipe3=recipes[1].Recipe3}}
    asserts.expectTableValuesEqual(result, expected)
end)

test("collateRecipesByProduct with items present start", fix, function(asserts)
    local recipes = {{
        Recipe1 = {name = "Recipe1", products = {thing1=1}},
        Recipe2 = {name = "Recipe2", products = {thing2=1}},
        Recipe3 = {name = "Recipe3", products = {thing1=1, thing2=2}},
    }}
    local prior_recipe = {name = "prior", products = {thing1=1}}
    local result = {thing1={prior=prior_recipe}}
    local output = testProcessor.collateRecipesByProduct(recipes, result)
    asserts.expectTableValuesEqual(output, {thing1=true, thing2=true})
    asserts.expectTableValuesEqual(result, {
        thing1={Recipe1=recipes[1].Recipe1, Recipe3=recipes[1].Recipe3, prior=prior_recipe},
        thing2={Recipe2=recipes[1].Recipe2, Recipe3=recipes[1].Recipe3}})
end)

test("collateRecipesByProduct with multiple lists", fix, function(asserts)
    local recipes = {{
        Recipe1 = {name = "Recipe1", products = {thing1=1} }
    },{
        Recipe2 = {name = "Recipe2", products = {thing2=1}},
        Recipe3 = {name = "Recipe3", products = {thing1=1, thing2=2}},
    }}
    local prior_recipe = {name = "prior", products = {thing1=1}}
    local result = {thing1={prior=prior_recipe}}
    local output = testProcessor.collateRecipesByProduct(recipes, result)
    asserts.expectTableValuesEqual(output, {thing1=true, thing2=true})
    asserts.expectTableValuesEqual(result, {
        thing1={Recipe1=recipes[1].Recipe1, Recipe3=recipes[2].Recipe3, prior=prior_recipe},
        thing2={Recipe2=recipes[2].Recipe2, Recipe3=recipes[2].Recipe3}})
end)

test("processAllRecipes basic->final", fix, function(asserts)
    local basic_values = {ironplate=testValue(1), copperplate=testValue(2)}
    local final_recipes = {
        gear = {name = "gear", products={gear=1}, ingredients = {ironplate=2}},
    }
    local output = testProcessor.processAllRecipes({}, final_recipes, basic_values)
    asserts.expectTableValuesEqual(output, {
        gear=testValue(2)
        })
end)

test("processAllRecipes alternate recipes", fix, function(asserts)
    local basic_values = {ironplate=testValue(1), copperplate=testValue(2)}
    local intermediate_recipes = {{
        steel = {name = "steel", products={steel=1}, ingredients = {ironplate=5}},
    }}
    local final_recipes = {
        steelB = {name = "steelB", products={steel=1}, ingredients = {copperplate=10}},
    }
    local output = testProcessor.processAllRecipes(intermediate_recipes, final_recipes, basic_values)
    asserts.expectTableValuesEqual(output, {
        steel=testValue(5),
        })
end)

test("processAllRecipes long chain", fix, function(asserts)
    local basic_values = {ironplate=testValue(1), copperplate=testValue(2)}
    local intermediate_recipes = {{
        steel = {name = "steel", products={steel=1}, ingredients = {ironplate=5}},
        stick = {name = "stick", products={stick=2}, ingredients = {ironplate=1}},
        circuit = {name = "circuit", products={circuit=1}, ingredients = {copperwire=3, ironplate=1}},
    }}
    local final_recipes = {
        copperwire = {name = "copperwire", products={copperwire=2}, ingredients = {copperplate=1}},
        axe = {name = "axe", products={axe=1}, ingredients = {steel=8, stick=1}},
        magicaxe = {name = "magicaxe", products={magicaxe=1}, ingredients = {axe=1, circuit=5}},
    }
    local output = testProcessor.processAllRecipes(intermediate_recipes, final_recipes, basic_values)
    print(table.tostring(output))
    asserts.expectNotNil(output.magicaxe)
    asserts.expectValueEqual(output.magicaxe, 60.5)
end)

test("processAllRecipes impossible recipes", fix, function(asserts)
    local intermediate_recipes = {{
        impossible = {name = "impossible", products={impossible=1}, ingredients = {nothing=1}},
    }}
    local final_recipes = {
        StupidThing = {name = "StupidThing", products={StupidThing=1}, ingredients = {nothing=1}},
        NestedStupidThing = {name = "StupidThing", products={StupidThing=1}, ingredients = {nothing=1}},
    }
    local punted = {}
    local output = testProcessor.processAllRecipes(intermediate_recipes, final_recipes, {}, punted)
    print(table.tostring(output))
    asserts.expectTableValuesEqual(output, {})
    asserts.expectTableValuesEqual(punted, final_recipes)
end)

test("processAllRecipes overwrite raw material", fix, function(asserts)
    local basic_values = {ironplate=testValue(1), copperplate=testValue(2)}
    local final_recipes = {
        betterironplate = {name = "betterironplate", products={ironplate=4}, ingredients = {copperplate=1}},
        steel = {name = "steel", products={steel=1}, ingredients = {ironplate=5}},
    }
    local output = testProcessor.processAllRecipes({}, final_recipes, basic_values)
    asserts.expectTableValuesEqual(output, {
        ironplate=testValue(0.5),
        steel=testValue(2.5),
    })
end)

test("processAllRecipes don't overwrite raw material if worse", fix, function(asserts)
    local basic_values = {ironplate=testValue(1), copperplate=testValue(2)}
    local final_recipes = {
        worseironplate = {name = "worseironplate",products={ironplate=1}, ingredients = {copperplate=1}},
        steel = {name = "steel", products={steel=1}, ingredients = {ironplate=5}},
    }
    local output = testProcessor.processAllRecipes({}, final_recipes, basic_values)
    asserts.expectTableValuesEqual(output, {
        steel=testValue(5),
    })
end)


test("processAllRecipes integration", fix, function(asserts)
    local StupidThingRec = {name = "StupidThing", products={StupidThing=1}, ingredients = {nothing=1} }
    local NestedStupidThing = {name = "StupidThing", products={StupidThing=1}, ingredients = {nothing=1}}
    local basic_values = {ironplate=testValue(1), copperplate=testValue(2)}
    local intermediate_recipes = {{
        steel = {name = "steel", products={steel=1}, ingredients = {ironplate=5} }
        },
        {
        stick = {name = "stick", products={stick=2}, ingredients = {ironplate=1}},
        impossible = {name = "impossible", products={impossible=1}, ingredients = {nothing=1}},
    }}
    local final_recipes = {
        -- Tests basic->final
        gear = {name = "gear", products={gear=1}, ingredients = {ironplate=2}},
        -- Tests comparing alternate recipes, ensure steel is in final products list.
        steelB = {name = "steelB", products={steel=1}, ingredients = {copperplate=10}},
        -- Tests basic->intermediate->final
        axe = {name = "axe", products={axe=1}, ingredients = {steel=8, stick=1}},
        -- Tests recipe you can't make.
        StupidThing = StupidThingRec,
        -- Tests recursive can't make.
        NestedStupidThing = NestedStupidThing,
    }
    local punted = {}
    local output = testProcessor.processAllRecipes(intermediate_recipes, final_recipes, basic_values, punted)
    asserts.expectTableValuesEqual(output, {
        gear=testValue(2),
        steel=testValue(5),
        axe=testValue(40.5),
        })
    asserts.expectTableValuesEqual(punted, {StupidThing = StupidThingRec, NestedStupidThing = NestedStupidThing})
end)

test("processAllRecipes breakable-loop", fix, function(asserts)
    local basic_values = {ironplate=testValue(1), water=testValue(1)}
    local final_recipes = {
        makeemptybarrel = {name = "makeemptybarrel", products={emptybarrel=1}, ingredients = {ironplate=1}},
        emptybarrel = {name = "emptybarrel", products={emptybarrel=1, water=10}, ingredients = {fullbarrel=1}},
        fillbarrel = {name = "fillbarrel", products={fullbarrel=1}, ingredients = {emptybarrel=1, water=10}},
    }
    local punted = {}
    local output = testProcessor.processAllRecipes({}, final_recipes, basic_values, punted)
    asserts.expectTableValuesEqual(output, {
        emptybarrel=testValue(1),
        fullbarrel=testValue(11),
        })
    asserts.expectTableEmpty(punted)
end)

test("processAllRecipes unbreakable-loop", fix, function(asserts)
    local basic_values = {ironplate=testValue(1), water=testValue(1)}
    local final_recipes = {
        emptybarrel = {name = "emptybarrel", products={emptybarrel=1, water=10}, ingredients = {fullbarrel=1}},
        fillbarrel = {name = "fillbarrel", products={fullbarrel=1}, ingredients = {emptybarrel=1, water=10}},
    }
    local punted = {}
    local output = testProcessor.processAllRecipes({}, final_recipes, basic_values, punted)
    asserts.expectTableValuesEqual(output, {})
    asserts.expectTableValuesEqual(punted, final_recipes)
end)

test("processAllRecipes runaway value", fix, function(asserts)
    local basic_values = {ironplate=testValue(1), water=testValue(1)}
    local final_recipes = {
        makeemptybarrel = {name = "makeemptybarrel", products={emptybarrel=1}, ingredients = {ironplate=1}},
        emptybarrel = {name = "emptybarrel", products={emptybarrel=1, water=20}, ingredients = {fullbarrel=1}},
        fillbarrel = {name = "fillbarrel", products={fullbarrel=1}, ingredients = {emptybarrel=1, water=10}},
    }
    asserts.expectError(
        function ()
            testProcessor.processAllRecipes({}, final_recipes, basic_values)
        end,
        -- Error verification:
        function(err) return string.match(err, "runaway value problem") end
    )
end)

--test("processAllRecipes decoy runaway value", fix, function(asserts)
--    local basic_values = {ironplate=testValue(1), water=testValue(1)}
--    local final_recipes = {
--        makeemptybarrel = {name = "makeemptybarrel", products={emptybarrel=1}, ingredients = {ironplate=1}},
--        emptybarrel = {name = "emptybarrel", products={emptybarrel=1, water=20}, ingredients = {fullbarrel=1}},
--        halffillbarrel = {name = "halffillbarrel", products={halffullbarrel=1}, ingredients = {emptybarrel=1, water=10}},
--        fillbarrel = {name = "fillbarrel", products={fullbarrel=1}, ingredients = {halffullbarrel=1, water=10}},
--    }
--    local output = testProcessor.processAllRecipes({}, final_recipes, basic_values)
--    -- TODO expect error
--end)

test("splitRecipesByLevel", fix, function(asserts)
    local r1, r2, r3, r4 = {name="r1"}, {name="r2"}, {name="r3", level=2}, {name="r4"}
    local levels = {1, 2}
    local techs = {
        t1a = {level = 1, recipes = {r1=r1, r2=r2} },
        t1b = {level = 1, recipes = {r3=r3}}, --testTweakLevel looks at the level entry.
        t1c = {level = 1, recipes = {} },
        t2a = {level = 2, recipes = {r4=r4}}
    }
    local result = testProcessor.splitRecipesByLevel(techs, {1, 2})
    asserts.expectTableValuesEqual(result,
        {
            [1]= {r1=r1, r2=r2},
            [2]= {r3=r3, r4=r4}
        }
    )
end)

test("processAllTechs unit test", fix, function(asserts)
    local basic_values = {ironplate=testValue(1), water=testValue(1)}
    local Rgear = {name = "gear", products={gear=1}, ingredients = {ironplate=2} }
    local Rsteel = {name = "steel", products={steel=1}, ingredients = {ironplate=5} }
    local levels = {1, 2}
    local techs = {
        t1a = {level = 1, recipes = {gear=Rgear} },
        t2a = {level = 2, recipes = {steel=Rsteel}}
    }
    local result = testProcessor.processAllTechs(techs, levels, basic_values)
    print(table.tostring(result))
    asserts.expectTableValuesEqual(result,
        {
            [1]= {gear=testValue(2)},
            [2]= {steel=testValue(5)},
            final = {gear=testValue(2), steel=testValue(5)}
        }
    )
end)

function integrationTest(name, techs, basic_values, ordered_levels, results)
    -- techs is a list of techs
    -- results is a list of {product=name, level=name, value=val, message=msg} which must be present and match.
    -- msg is printed if it fails.
    -- Does not object to extra stuff being present, unless results has a value=nil entry for it.

    test(name, fix, function(asserts)
        print("!!Integation Test!!")
        local result = testProcessor.processAllTechs(techs, ordered_levels, basic_values)
        print("===Ugly Result===")
        print(table.tostring(result))
        print("=================")
        for _, item in pairs(results) do
            if item.msg then print(item.msg) end
            if item.value then
                asserts.expectNotNil(result[item.level])
                asserts.expectNotNil(result[item.level][item.product])
            end
            asserts.expectAnyTypeEqual(result[item.level][item.product], item.value)
        end
    end)
end

integrationTest("Oil (item with value at level 1 and level 2)",
    -- oil can be made cheaper at level 2 than level 1.
    -- plastic comes from oil, and final1 and final2 fom plastic, checking that level2 products are using the cheaper value for oil in a large chain.
    -- fuel comes from oil at level 2, and checks that new things use the new value.
    {
        t1 = {level = 1, recipes = {basic = {name="basic", products={oil=1}, ingredients={ironplate=1}},
                                    plastic = {name="plastic", products={plastic=1}, ingredients={oil=2}}}},
        t2 = {level = 2, recipes = {advanced = {name="advanced", products={oil=2}, ingredients={ironplate=1}},
                                    fuel = {name="fuel", products={fuel=1}, ingredients={oil=1}}}},
        t4 = {level = 1, recipes = {final1 = {name="final1", products={final1=1}, ingredients={plastic=1}}}} ,
        t5 = {level = 2, recipes = {final2 = {name="final2", products={final2=1}, ingredients={plastic=1}}}} ,
    },
    {ironplate=testValue(1) },
    {1, 2},
    {
        {product="oil", level=1, value=testValue(1), msg="lvl 1 oil uses lvl 1 recipe:"},
        {product="oil", level=2, value=testValue(0.5), msg="lvl 2 oil uses lvl 2 recipe:" },
        {product="fuel", level=2, value=testValue(0.5), msg="lvl 2 new things use new value."},
        {product="final1", level=1, value=testValue(2), msg="lvl 1 subsequent intermediate product uses lvl 1 recipe." },
        {product="final2", level=2, value=testValue(1), msg="lvl 2 subsequent intermediate product upgrades to new recipe."},
    }
)

integrationTest("Ingredient not available till higher level.",
    -- barrel can be filled at level 1.
    -- oil only exists at level 2.
    {
        t1 = {level = 1, recipes = {fill = {name="fill", products={fullbarrel=1}, ingredients={emptybarrel=1, oil=100}}}},
        t2 = {level = 2, recipes = {oil = {name="oil", products={oil=2}, ingredients={ironplate=1}}}},
    },
    {ironplate=testValue(1), emptybarrel=testValue(2) },
    {1, 2},
    {
        {product="fullbarrel", level=1, value=nil, msg="fullbarrel can't be made at level 1" },
        {product="fullbarrel", level=2, value=testValue(52), msg="fullbarrel punted to level 2" },
    }
)

integrationTest("Ingredient not produceable till higher level.",
    -- rawwood cannot be produced.
    -- wood is made from rawwood at level 1.
    -- chest is made from wood at level 1.
    -- wood is made from oil at level 2
    {
        t1 = {level = 1, recipes = {woodfromraw = {name="woodfromraw", products={wood=1}, ingredients={rawwood=1}},
                                    chest = {name="chest", products={chest=1}, ingredients={wood=1}}}},
        t2 = {level = 2, recipes = {woodfromoil = {name="woodfromoil", products={wood=1}, ingredients={oil=1}}}},
    },
    {oil=testValue(1)},
    {1, 2},
    {
        {product="wood", level=1, value=nil, msg="Can't make wood at lvl 1" },
        {product="chest", level=1, value=nil, msg="Can't make chest at lvl 1" },
        {product="wood", level=2, value=testValue(1), msg="Wood becomes available at level 2" },
        {product="chest", level=2, value=testValue(1), msg="Punted product becomes available at level 2" },
    }
)

integrationTest("Worse recipe at higher level",
    {
        t1 = {level = 1, recipes = {steel = {name="steel", products={steel=1}, ingredients={ironplate=1}}}},
        t2 = {level = 2, recipes = {worsesteel = {name="worsesteel", products={steel=1}, ingredients={ironplate=2}}}},
    },
    {ironplate=testValue(1)},
    {1, 2},
    {
        {product="steel", level=2, value=nil, msg="Don't request item from worse formula" },
    }
)


-- Loops

fix.done()