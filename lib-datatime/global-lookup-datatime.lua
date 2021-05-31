global_lookup_by_name = {
    recipe = function(name)
        return data.raw.recipe[name]
    end,
    technology = function(name)
        return data.raw.technology[name]
    end
}