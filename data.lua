--add lua shortcut
local shortcut = {
    type = "shortcut",
    action = "lua",
    name = "ShortcutWaterGhostBlueprintUpdate",
    icon = {
        filename = "__GhostOnWater__/icons/waterGhostBlueprintUpdate.png",
        size = 16,
        scale = 1,
        flags = {"icon"}
    },
}

--add custom input
local customInput = {
    name = "InputWaterGhostBlueprintUpdate",
    type = "custom-input",
    key_sequence = "CONTROL + W",
    consuming = "none",
    action = "lua"
}

--add shortcut to the toolbar
data:extend{shortcut}
--add custom input
data:extend{customInput}