--used landfill type setting

local isLandfillPaintingLoaded = mods["LandfillPainting"]

local lanfillTypes = { "landfill" }

if (isLandfillPaintingLoaded) then
    table.insert(lanfillTypes, "dry-dirt")
    table.insert(lanfillTypes, "dirt-4")
    table.insert(lanfillTypes, "grass-1")
    table.insert(lanfillTypes, "red-desert-1")
    table.insert(lanfillTypes, "sand-3")
end


local usedLandfillType = {
    type = "string-setting",
    name = "WaterGhostUsedLandfillType",
    setting_type = "runtime-global",
    default_value = "landfill",
    allowed_values = lanfillTypes,
    localised_name = "Used Landfill Type",
    localised_description = "The type of landfill that will be placed under dummy entities"
}

data:extend({ usedLandfillType })

local WaterGhostUpdateDelay = {
    type = "int-setting",
    name = "WaterGhostUpdateDelay",
    setting_type = "runtime-global",
    default_value = 600,
    minimum_value = 1,
    maximum_value = 3600,
    localised_name  = "Update Delay",
    localised_description = "Delay between water ghost (dummy) entiy updates in ticks.\nWater ghost entitie updates are performace heavy and may cause lag spikes.\nHigher values reduce the amount of updates and reduce lag spikes.\nLower values increase the amount of updates and increase lag spikes.\nIf you experience lag spikes, increase this value to make them less frequent.",
}

data:extend({ WaterGhostUpdateDelay })