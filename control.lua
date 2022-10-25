local constants = require('modules/constants')
local Event = require('__stdlib__/stdlib/event/event')
local util = require('util')
local table = require('__stdlib__/stdlib/utils/table')
local blueprints = require('modules/blueprints')
local landfillPlacer = require('modules/landfillPlacer')
local waterGhostUpdater = require('modules/waterGhostUpdater')

local updateRate = constants.defaultUpdateDelay

--get all entity prototypes names whos name starts with constants.dummyPrefix
local function fillWaterGhostTypes()
    global.GhostOnWater.WaterGhostNames = table.filter(
        table.map(game.entity_prototypes ,function(prototype) return prototype.name end),
        function(name) return util.string_starts_with(name, constants.dummyPrefix) end)
end

local function onConfigurationChanged()
    global.GhostOnWater = {}
    global.GhostOnWater.WaterGhostNames = {}
    fillWaterGhostTypes()
end

--Main function that turns dummy entity ghosts into normal entity ghosts after landfill has been placed
local function waterGhostUpdate()
    --get all dummy entity ghosts
    local waterGhostEntities = waterGhostUpdater.getWaterGhostEntities()
    --loop through dummy entity ghosts
    for _, waterGhostEntity in pairs(waterGhostEntities) do
        --replace dummy entity ghost with original entity ghost
        waterGhostUpdater.replaceDummyEntityGhost(waterGhostEntity)
        --place ghost landfill under dummy entity ghost
        landfillPlacer.placeGhostLandfill(waterGhostEntity)
    end
end

local function updateSettings()
    if (settings.global["WaterGhostUpdateDelay"]) then
        local previousUpdateRate = updateRate
---@diagnostic disable-next-line: cast-local-type
        updateRate = settings.global["WaterGhostUpdateDelay"].value
        --don't do anything if the update rate hasn't changed
        if (previousUpdateRate == updateRate) then return end

        --remove the old event
        Event.remove(previousUpdateRate * -1, waterGhostUpdate)
        Event.on_nth_tick(updateRate, waterGhostUpdate)

    else
        game.print("WaterGhostUpdateRate setting not found")
        return
    end


end

local function onBlueprintUpdateTriggerd(event)
    local playerIndex = event.player_index
    blueprints.updateBlueprint(playerIndex)
end

--on configuration changed event
Event.on_configuration_changed(onConfigurationChanged)
--add event handler for waterGhostUpdate
Event.on_nth_tick(updateRate, waterGhostUpdate)
--add event handler for updateSettings
Event.on_nth_tick(constants.settingsUpdateDelay, updateSettings)
--add event handler for update blueprint shortcut using filter function
Event.register(defines.events.on_lua_shortcut, onBlueprintUpdateTriggerd, function(event, shortcut)
    return event.prototype_name == "ShortcutWaterGhostBlueprintUpdate"
end, "")
Event.register("InputWaterGhostBlueprintUpdate", onBlueprintUpdateTriggerd)
