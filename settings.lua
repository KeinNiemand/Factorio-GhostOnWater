--used landfill type setting
local constants = require('modules/constants')
local Table = require('__stdlib__/stdlib/utils/table')
local isLandfillPaintingLoaded = mods["LandfillPainting"]
local isSpaceExplorationLoaded = mods["space-exploration"]

local lanfillTypes = { constants.vanillaLandfill }

if (isLandfillPaintingLoaded) then
    Table.each(constants.paintingWithLandfillLandfillTypes, function(landfillType)
        table.insert(lanfillTypes, landfillType)
    end)
end


local usedLandfillType = {
    type = "string-setting",
    name = "WaterGhostUsedLandfillType",
    setting_type = "runtime-global",
    default_value = constants.vanillaLandfill,
    allowed_values = lanfillTypes,
    localised_name = "Used Landfill Type",
    localised_description = "The type of landfill that will be placed under dummy entities"
}

data:extend({ usedLandfillType })

local WaterGhostUpdateDelay = {
    type                  = "int-setting",
    name                  = "WaterGhostUpdateDelay",
    setting_type          = "runtime-global",
    default_value         = constants.defaultUpdateDelay,
    minimum_value         = 1,
    maximum_value         = 3600,
    localised_name        = "Update Delay",
    localised_description = "Delay between water ghost (dummy) entiy updates in ticks (60 tick = 1 second).\nWater ghost entitie updates are performace heavy and may cause lag spikes.\nHigher values reduce the amount of updates and reduce lag spikes.\nLower values increase the amount of updates and increase lag spikes.\nIf you experience lag spikes, increase this value to make them less frequent.",
}

data:extend({ WaterGhostUpdateDelay })

data:extend({ {
    type                  = "int-setting",
    name                  = "WaterGhostMaxWaterGhostsPerUpdate",
    setting_type          = "runtime-global",
    default_value         = constants.defaultMaxWaterGhostUpdatesPerUpdate,
    minimum_value         = 1,
    maximum_value         = 10000,
    localised_name        = "Water Ghosts Per Update",
    localised_description = "The maximum amount of water ghosts that will be updated per update.\nLower value reduce performace impact, but it may take several updates to update all water ghosts.",
} })

if (isSpaceExplorationLoaded) then
    data:extend
    { {
        type = "string-setting",
        name = "WaterGhostUsedSpaceLandfillType",
        setting_type = "runtime-global",
        default_value = constants.spaceLandfillTypes[1],
        allowed_values = constants.spaceLandfillTypes,
        localised_name = "Used Space Platform",
        localised_description = "The type of space platform that will be placed under dummy entities placed on empty space"
    } }
end
