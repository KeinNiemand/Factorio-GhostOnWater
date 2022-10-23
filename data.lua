--add lua shortcut
local shortcut = {
    type = "shortcut",
    action = "lua",
    name = "waterGhostBlueprintUpdate",
    icon = {
        filename = "__GhostOnWater__/icons/waterGhostBlueprintUpdate.png",
        size = 16,
        scale = 1,
        flags = {"icon"}
    },
}

--add shortcut to the toolbar
data:extend{shortcut}