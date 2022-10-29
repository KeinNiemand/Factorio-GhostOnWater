--require
local constants = require('modules/constants')
local Event = require('__stdlib__/stdlib/event/event')
local util = require('util')
local table = require('__stdlib__/stdlib/utils/table')
local Queue = require('__stdlib__/stdlib/misc/queue')
local Is = require('__stdlib__/stdlib/utils/is')
local blueprints = require('modules/blueprints')
local waterGhostUpdater = require('modules/waterGhostUpdater')


--get all entity prototypes names whos name starts with constants.dummyPrefix
local function fillWaterGhostTypes()
    global.GhostOnWater.WaterGhostNames = table.filter(
        table.map(game.entity_prototypes, function(prototype) return prototype.name end),
        function(name) return util.string_starts_with(name, constants.dummyPrefix) end)
end

--sets event filters for the diffrent build events this needs to be done both on reInint and on load
local function setBuildEventFilters()
    local filterArray = table.map(global.GhostOnWater.WaterGhostNames,
        function(name) return { filter = 'ghost_name', name = name } end)

    script.set_event_filter(defines.events.on_built_entity, filterArray)
    script.set_event_filter(defines.events.script_raised_built, filterArray)
    script.set_event_filter(defines.events.on_entity_cloned, filterArray)
end

--re initilises data global table
local function reInitGlobalTable()
    global.GhostOnWater =
    {
        WaterGhostNames = {},
        KnownWaterGhosts = Queue()
    }

    fillWaterGhostTypes()
    setBuildEventFilters()
    --force the known water ghosts table to be updated
    waterGhostUpdater.forceUpdateKnownWaterGhosts()

    --space exploration compatibility
    --get collision for space (space exploration compatibility) to the global table if it exists
    local emptySpaceTileCollisionLayerPrototype = game.entity_prototypes["collision-mask-empty-space-tile"]
    if emptySpaceTileCollisionLayerPrototype then
        global.GhostOnWater.emptySpaceCollsion = table.first(table.keys(emptySpaceTileCollisionLayerPrototype.collision_mask))
    end


end

local function onLoad()
    Queue.load(global.GhostOnWater.KnownWaterGhosts)
    setBuildEventFilters()
end

--event handlers for everything non inilisation related

--checks if runtime mod settings that need to be applied changed and applies them
-- local function updateSettings()
--     if (settings.global["WaterGhostUpdateDelay"]) then
--         local previousUpdateRate = updateRate
-- ---@diagnostic disable-next-line: cast-local-type
--         updateRate = settings.global["WaterGhostUpdateDelay"].value
--         --don't do anything if the update rate hasn't changed
--         if (previousUpdateRate == updateRate) then return end

--         --remove the old event
--         Event.remove(previousUpdateRate * -1, waterGhostUpdater.waterGhostUpdate)
--         Event.on_nth_tick(updateRate, waterGhostUpdater.waterGhostUpdate)

--     else
--         game.print("WaterGhostUpdateRate setting not found")
--         return
--     end


-- end

--runs when user triggers a blueprint update with the shortcut or hotkey
local function onBlueprintUpdateTriggerd(event)
    local playerIndex = event.player_index
    blueprints.updateBlueprint(playerIndex, blueprints.bpReplacerToDummy)
end

local function onBlueprintRevertTriggerd(event)
    local playerIndex = event.player_index
    blueprints.updateBlueprint(playerIndex, blueprints.bpReplacerToOriginal)
end

--handles on_build_entity, on_script_raised_built and on_entity_cloned events
local function onBuildEvent(event)
    local buildEntity = event.created_entity or event.entity or event.destination
    --check if the build entity is valid
    if not buildEntity then return end

    waterGhostUpdater.addEntityToKnownWaterGhosts(buildEntity)

    if __Profiler then
        remote.call("profiler", "dump")
    end
end

--on configuration changed event
Event.on_configuration_changed(reInitGlobalTable)
Event.on_init(reInitGlobalTable)
--on load event to on_load
Event.on_load(onLoad)
--add event handler for waterGhostUpdate
Event.register(defines.events.on_tick, waterGhostUpdater.waterGhostUpdate)
--add event handler for updateSettings
--Event.on_nth_tick(constants.settingsUpdateDelay, updateSettings)
--register event handlers for on_build_entity, on_script_raised_built and on_entity_cloned

Event.register(defines.events.on_built_entity, onBuildEvent)
Event.register(defines.events.script_raised_built, onBuildEvent)
Event.register(defines.events.on_entity_cloned, onBuildEvent)
--add event handler for update blueprint shortcut using filter function
Event.register(defines.events.on_lua_shortcut, onBlueprintUpdateTriggerd, function(event, shortcut)
    return event.prototype_name == "ShortcutWaterGhostBlueprintUpdate"
end, "")
--add event handler for update blueprint hotkey
Event.register("InputWaterGhostBlueprintUpdate", onBlueprintUpdateTriggerd)
--add event handler for revert blueprint shortcut using filter function
Event.register(defines.events.on_lua_shortcut, onBlueprintRevertTriggerd, function(event, shortcut)
    return event.prototype_name == "ShortcutWaterGhostBlueprintRevert"
end, "")
Event.register("InputWaterGhostBlueprintRevert", onBlueprintRevertTriggerd)
