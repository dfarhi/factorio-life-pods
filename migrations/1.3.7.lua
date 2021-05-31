for _, pod in pairs(game.surfaces[1].find_entities_filtered{type="life-pod-repair"}) do
    pod.health = pod.health * 2
end