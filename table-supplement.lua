function table.isEmpty(table)
    return table == nil or next(table) == nil
end

function table.single_element(table)
    local first = false
    for _, _ in pairs(table) do
        if first then return false end
        first = true
    end
    return true
end

function table.count(t)
    local res = 0
    for name, _ in pairs(t) do
        res  = res + 1
    end
    return res
end
function table.tostring(t)
    if type(t) ~= "table" then return tostring(t) end
    local bits = {}
    for k, v in pairs(t) do
        table.insert(bits, k .. ": " .. table.tostring(v))
    end
    return "{" .. table.concat(bits, ", ") .. "}"
end
function table.onelevelcopy(t)
    local new = {}
    for k, v in pairs(t) do
        new[k] = v
    end
    return new
end

function table.keys(t)
    local keyset={}

    for k,_ in pairs(t) do
      table.insert(keyset, k)
    end
    return keyset
end

function table.sumValues(t)
    local result = 0
    for k, v in pairs(t) do
        result = result + v
    end
    return result
end

function table.union(t)
    local result = {}
    for _, sub in pairs(t) do
        for k, v in pairs(sub) do
            result[k] = v
        end
    end
    return result
end

function table.append(base, addon)
    -- Assumes both are arrays
    for _, v in ipairs(addon) do
        table.insert(base, v)
    end
end

function table.keysSortedByValues(t, compare)
    -- compare is true if first arg is < second
    local reverse_table = {}
    for k, v in pairs(t) do
        if reverse_table[v] == nil then reverse_table[v] = {} end
        table.insert(reverse_table[v], k)
    end
    local vals_list = {}
    for val, _ in pairs(reverse_table) do
        table.insert(vals_list, val)
    end
    table.sort(vals_list, compare)

    local keysarray = {}
    for _, val in ipairs(vals_list) do
        table.append(keysarray, reverse_table[val])
    end
    return keysarray
end

function table.filter(t, func)
    for k, v in pairs(t) do
        if not func(v) then t[k] = nil end
    end
end

function table.mapField(t, f)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v[f]
    end
    return result
end

function table.choice(t)
    local array = {}
    for k, v in pairs(t) do
        table.insert(array, k)
    end
    table.sort(array)

    local idx = math.random(1, #table + 1)
    return t[array[idx]]
end