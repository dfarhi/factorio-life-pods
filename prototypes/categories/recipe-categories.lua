require "config"
require "lifepods-utils"

for _, level in pairs(CONFIG.levels) do
  data:extend(
  {
    {
      type = "recipe-category",
      name = recipeCategoryFromLevel(level)
    },
  })
end

data:extend(
{
  {
    type = "recipe-category",
    name = "life-pod-final"
  },
})