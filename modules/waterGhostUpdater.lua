--Module responsile for checking if real ghosts can be placed and replacing the dummy ghosts with the real ghosts
local waterGhostUpdater = {}

--require
local constants = require('modules/constants')
local util = require('util')
local table = require('__stdlib__/stdlib/utils/table')

--split function above into multiple functions to make it more readable
waterGhostUpdater.getWaterGhostEntities = function ()
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

--function to get the original entity name from the dummy entity name
local function getOriginalEntityName(dummyEntityName)
    --get the original entity name from the dummy entity name
    local originalEntityName = string.sub(dummyEntityName, string.len(constants.dummyPrefix) + 1)
    return originalEntityName
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
    return surface.can_place_entity { name = originalEntityName, position = position, direction = direction }
end

--function that replaces all dummy entity ghosts with the original entity ghosts
--use orderUpgrade to upgrade the dummy entity ghosts to the original entity ghosts
waterGhostUpdater.replaceDummyEntityGhost = function(dummyEntity)
    --get the original entity name from the dummy entity name
    local originalEntityName = getOriginalEntityName(dummyEntity.ghost_name)
    --check if the original entity can be placed in the location and with the same direction of the dummy entity
    if canPlaceOriginalEntity(originalEntityName, dummyEntity) then
        --order upgrade (force, target)
        dummyEntity.order_upgrade { force = dummyEntity.force, target = originalEntityName }
    end
end
return waterGhostUpdater