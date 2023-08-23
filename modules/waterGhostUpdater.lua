--Module responsile for checking if real ghosts can be placed and replacing the dummy ghosts with the real ghosts
local waterGhostUpdater = {}

--require
local constants = require('modules/constants')
local waterGhostCommon = require('modules/waterGhostCommon')
local landfillPlacer = require('modules/landfillPlacer')
local util = require('util')
local table = require('__stdlib__/stdlib/utils/table')
local Queue = require('__stdlib__/stdlib/misc/queue')
local Is = require('__stdlib__/stdlib/utils/is')

--searches all surfaces for water ghosts and returns a table of all the water ghosts found
--this function is very slow for large maps and should only be used to force the known water ghosts table
local getWaterGhostEntities = function ()
    --get all surfaces
    local surfaces = game.surfaces
    local ghosts = {}

    table.each(surfaces, function(surface)
        --get all ghosts on the surface
        local surfaceGhosts = surface.find_entities_filtered { type = 'entity-ghost',
            ghost_name = global.GhostOnWater.WaterGhostNames }
        --add all surface ghosts to the ghosts table no additional checks needed
        table.each(surfaceGhosts, function(ghost)
            table.insert(ghosts, ghost)
        end)
    end)

    return ghosts
end

--function that check if the original entity could be placed in the location of the dummy entity
local function canPlaceOriginalEntity(originalEntityName, dummyEntity)
    --check if the original entity can be placed in the location and with the same direction of the dummy entity
    --get surface
    local surface = dummyEntity.surface
    --get position
    local position = dummyEntity.position
    --get direction
    local direction = dummyEntity.direction
    --check if the original entity can be placed
    if dummyEntity.ghost_type == "offshore-pump" then
        --offshore pump is a special case because it can be placed on water so we use a diffrent build_check_type
        --check if the original entity can be placed on water
        --return surface.can_place_entity { name = originalEntityName, position = position, direction = direction, force = dummyEntity.force, build_check_type = defines.build_check_type.blueprint_ghost, forced = true }
        return surface.can_fast_replace { name = originalEntityName, position = position, direction = direction, force = dummyEntity.force }
    end

    return surface.can_place_entity { name = originalEntityName, position = position, direction = direction }
end

--function that replaces all dummy entity ghosts with the original entity ghosts
--use orderUpgrade to upgrade the dummy entity ghosts to the original entity ghosts
local replaceDummyEntityGhost = function(dummyEntity)
    --get the original entity name from the dummy entity name
    local originalEntityName = waterGhostCommon.getOriginalEntityName(dummyEntity.ghost_name)
    --check if the original entity can be placed in the location and with the same direction of the dummy entity
    if canPlaceOriginalEntity(originalEntityName, dummyEntity) then
        --order upgrade (force, target)
        dummyEntity.order_upgrade { force = dummyEntity.force, target = originalEntityName }
    end
end

--Main function that turns dummy entity ghosts into normal entity ghosts after landfill has been placed
waterGhostUpdater.waterGhostUpdate = function(event)
    --return if the event.tick is not a multiple of the update interval
    if event.tick % settings.global.WaterGhostUpdateDelay.value ~= 0 then return end

    --return if global table is not initialised
    if not global.GhostOnWater then return end
    --return if the known water ghosts queue is not initialised
    if not global.GhostOnWater.KnownWaterGhosts then return end
    --return if the known water ghosts queue is empty
    if #global.GhostOnWater.KnownWaterGhosts == 0 then return end


    --this should only be called once but I'm to lazy to add a callback and I can't call it directly from control since that would be a diffrent instance
    landfillPlacer:init()
    --fill available landfill types, called once per update to make sure it's up to date with settings
    --disabled since init already calls this
    --landfillPlacer:reFillActiveLandfillTypes()
    --loop trough all known water ghosts

    for i = 1, math.min(#global.GhostOnWater.KnownWaterGhosts, settings.global.WaterGhostMaxWaterGhostsPerUpdate.value) do
        local knownWaterGhostInfo = global.GhostOnWater.KnownWaterGhosts()
        local waterGhostEntity = knownWaterGhostInfo.ghost
        --go to continue if the entity is not valid
        if not Is.valid(waterGhostEntity) then goto continue end
        --replace dummy entity ghost with original entity ghost
        replaceDummyEntityGhost(waterGhostEntity)
        --go to continue if the entity is not valid or if the entity is not a dummy entity ghost
        if not Is.valid(waterGhostEntity) then goto continue end
        if not util.string_starts_with(waterGhostEntity.ghost_name, constants.dummyPrefix) then goto continue end
        --place ghost landfill under dummy entity ghost
        landfillPlacer.placeGhostLandfill(waterGhostEntity)
        
        --entity is still valid after replacing so it needs to be pushed back onto the queue
        global.GhostOnWater.KnownWaterGhosts({ghost = waterGhostEntity})

        ::continue::
    end

    if __Profiler then
        remote.call("profiler", "dump")
    end
end

--forces an update of the known water ghosts table by searching all surfaces for water ghosts. Performance Heavy
waterGhostUpdater.forceUpdateKnownWaterGhosts = function()
    --get all water ghosts
    local waterGhosts = getWaterGhostEntities()
    --update the known water ghosts table
    --set to a new empty queue
    global.GhostOnWater.KnownWaterGhosts = Queue()
    table.each(waterGhosts, function(ghost)
        --push every found water ghost onto the queue
        global.GhostOnWater.KnownWaterGhosts({ghost = ghost})
    end)
end

--adds an entity to the known waater ghosts table if it's a water ghost dummy entity
waterGhostUpdater.addEntityToKnownWaterGhosts = function(entity)
    --return if the entity is not of type entity-ghost
    --if entity.type ~= 'entity-ghost' then return end

    --check if the entity is a dummy entity
    --if util.string_starts_with(entity.ghost_name, constants.dummyPrefix) then
        --add the entity to the known water ghosts table
    global.GhostOnWater.KnownWaterGhosts({ghost = entity})
    --end
end

return waterGhostUpdater