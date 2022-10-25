--add shortcut to make blueprint water placable
data:extend{
    type = "shortcut",
    action = "lua",
    name = "ShortcutWaterGhostBlueprintUpdate",
    icon = {
        filename = "__GhostOnWater__/icons/waterGhostBlueprintUpdate.png",
        size = 16,
        scale = 1,
        flags = {"icon"}
    },
    localised_name = "Convert Blueprint to water placable"
}
--add shortcut to reverse bp
data:extend{
    type = "shortcut",
    action = "lua",
    name = "ShortcutWaterGhostBlueprintRevert",
    icon = {
        filename = "__GhostOnWater__/icons/waterGhostBlueprintUpdate.png",
        size = 16,
        scale = 1,
        flags = {"icon"}
    },
    localised_name = "Revert Water Placable Blueprint"
}

--add custom input
data:extend{
    name = "InputWaterGhostBlueprintUpdate",
    type = "custom-input",
    key_sequence = "CONTROL + W",
    consuming = "none",
    action = "lua",
    localised_name = "Convert Blueprint to water placable Hotkey"
}

data:extend{
    name = "InputWaterGhostBlueprintRevert",
    type = "custom-input",
    --control shift w
    key_sequence = "CONTROL + SHIFT + W",
    consuming = "none",
    action = "lua",
    localised_name = "Revert Water Placable Blueprint Hotkey"
}