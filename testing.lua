-- usage demonstrated at the end.
--
-- fix = fixture()
--
-- test("MyCoolTest", fix, function(asserts)
--   doSomeStuff
--   asserts.expectEqual(thing1, thing2)
--   doSomeMoreStuff
--   asserts.expectNotNil(thing)
--   ...
-- end)
--
-- test("MyOtherTest", fix, function(asserts)
--   doDifferentStuff
--   asserts.expectEqual(x, y)
-- end)
--
-- fix.done()



function fixture()
    local passed_tests = {}
    local failed_tests = {}
    local lib = {}
    lib.update = function(testname, passed)
        if passed then
            table.insert(passed_tests, testname)
        else
            table.insert(failed_tests, testname)
        end
    end
    lib.done = function(errorOnFail)
        if table.isEmpty(failed_tests) then print("All tests passed!")
        else
            print("Some tests failed.")
            print(#passed_tests .. " tests passed.")
            print(#failed_tests .. " tests failed:")
            for _, testname in pairs(failed_tests) do
                print("  * " .. testname)
            end
        end
        if errorOnFail and not table.isEmpty(failed_tests) then
            error("Failed Tests: " .. table.tostring(failed_tests))
        end
    end
    return lib
end

function test(name, fixture, code)
    local passing = true
    local function fail(message)
            print("  FAILED: " .. message)
            passing = false
    end
    local expectEqual = function(a, b)
        if not (a == b) then
            fail(table.tostring(a) .. " is not equal to " .. table.tostring(b))
        end
    end
    local expectTableValuesEqualHelper
    expectTableValuesEqualHelper = function(t1, t2, path)
        local function printArgs()
            print("  1st:    " .. table.tostring(t1))
            print("  2nd:    " .. table.tostring(t2))
        end
        if type(t1) ~= "table" then
            fail("first item is not table: " .. table.tostring(t1))
            return
        end
        if type(t2) ~= "table" then
            fail("second item is not table: " .. table.tostring(t1))
            return
        end
        for key, value in pairs(t1) do
            if t2[key] == nil then
                fail("key " .. path .. "." .. tostring(key) .. " appears in first arg but not second.")
                printArgs()
            elseif type(t1[key]) ~= type(t2[key]) then
                fail("key " .. path .. "." .. tostring(key) .. " appears in first arg but not second.")
                printArgs()
            elseif type(t1[key]) == "table" then
                expectTableValuesEqualHelper(t1[key], t2[key], path .. "." .. key)
            else
                expectEqual(t1[key], t2[key])
            end
        end
        for key, value in pairs(t2) do
            if t1[key] == nil then
                fail("key " .. table.tostring(key) .. " appears in second arg but not first.")
                printArgs()
            end
        end
    end


    local asserts = {}
    asserts.expectEqual = expectEqual
    asserts.expectTrue = function(a)
        if not a then fail("ExpectTrue failed.") end
    end
    asserts.expectValueEqual = function(a, b)
        if not a.value then
            fail(table.tostring(a) .. " is not a testValue.")
        elseif not (a.value == b) then
            fail("value of " .. table.tostring(a.value) .. " is not equal to " .. table.tostring(b))
        end
    end
    asserts.expectNotNil = function(a)
        if a == nil then
            fail(table.tostring(a) .. " is nil.")
        end
    end
    asserts.expectTableValuesEqual = function(t1, t2) expectTableValuesEqualHelper(t1, t2, "") end
    asserts.expectError = function(code, verify_error)
        local status, err = pcall(code)
        if status then
            fail("No error!")
        else
            print("Caught error: " .. err)
            if verify_error and not verify_error(err) then
                fail("Error fails verification!")
            end
        end
    end
    asserts.expectAnyTypeEqual = function(a, b)
        if type(a) ~= type(b) then
            fail("Items have different types: " .. type(a) .. ", " .. type(b))
            return
        end
        if type(a) == "table" then
            asserts.expectTableValuesEqual(a, b)
        else
            asserts.expectEqual(a, b)
        end
    end
    asserts.expectTableEmpty = function(t)
        for k, v in pairs(t) do
            fail("Table contains " .. k .. ": " .. table.tostring(v))
        end
    end


    print("-------------------------")
    print("-------------------------")
    print("Testing: " .. name)
    print("-------------------------")
    print("-------------------------")
    code(asserts)
    print("-------------------------")
    if passing then print("  Test " .. name .. " passed.") end
    print("-------------------------")
    print("")
    fixture.update(name, passing)
end
fix = fixture()
test("testexpectTableValuesEqual", fix, function(asserts)
    local recipes = {
        Recipe1 = {name = "Recipe1", products = {thing1=1}},
        Recipe2 = {name = "Recipe2", products = {thing2=1}},
        Recipe3 = {name = "Recipe3", products = {thing1=1, thing2=2}},
    }
    asserts.expectTableValuesEqual({
        thing1={Recipe1=recipes.Recipe1, Recipe2=recipes.Recipe2},
        thing2={Recipe1=recipes.Recipe1, Recipe3=recipes.Recipe3}}, {
        thing1={Recipe1=recipes.Recipe1, Recipe2=recipes.Recipe2},
        thing2={Recipe1=recipes.Recipe1, Recipe3=recipes.Recipe3}})
end)
fix.done()

