local constants = require('modules/constants')
local Event = require('__stdlib__/stdlib/event/event')
local util = require('util')
local table = require('__stdlib__/stdlib/utils/table')

--split function above into multiple functions to make it more readable
function getWaterGhostEntities()
    --get all ghosts
    local ghosts = game.surfaces[1].find_entities_filtered{type = "entity-ghost" }
    --loop through ghosts

    --use table.filter to filter the ghosts table
    local foundWaterGhostEntities = table.filter(ghosts, function(ghost)
        local entityName = ghost.ghost_name
        return util.string_starts_with(entityName , constants.dummyPrefix)
    end)

    return foundWaterGhostEntities
end

--function to get the original entity name from the dummy entity name
function getOriginalEntityName(dummyEntityName)
    --get the original entity name from the dummy entity name
    local originalEntityName = string.sub(dummyEntityName, string.len(constants.dummyPrefix) + 1)
    return originalEntityName
end

--function that check if the original entity could be placed in the location of the dummy entity
function canPlaceOriginalEntity(originalEntityName, dummyEntity)
    --print the original entity name
    game.print("Checking entity: " .. originalEntityName)


    --check if the original entity can be placed in the location and with the same direction of the dummy entity
    --get surface
    local surface = dummyEntity.surface
    --get position
    local position = dummyEntity.position
    --get direction
    local direction = dummyEntity.direction
    --check if the original entity can be placed
    local canPlace = surface.can_place_entity{name = originalEntityName, position = position, direction = direction}


    game.print("Can place: " .. tostring(canPlace))
    return canPlace
end

--function that replaces all dummy entity ghosts with the original entity ghosts
--use orderUpgrade to upgrade the dummy entity ghosts to the original entity ghosts
function replaceDummyEntityGhost(dummyEntity)
    --get the original entity name from the dummy entity name
    local originalEntityName = getOriginalEntityName(dummyEntity.ghost_name)
    --check if the original entity can be placed in the location and with the same direction of the dummy entity
    if canPlaceOriginalEntity(originalEntityName, dummyEntity) then
        --order upgrade (force, target)
        dummyEntity.order_upgrade{force = dummyEntity.force, target = originalEntityName}
    end
end

--Main function that turns dummy entity ghosts into normal entity ghosts after landfill has been placed
function waterGhostUpdate() 
    --get all dummy entity ghosts
    local waterGhostEntities = getWaterGhostEntities()
    --loop through dummy entity ghosts
    for _, waterGhostEntity in pairs(waterGhostEntities) do
        --replace dummy entity ghost with original entity ghost
        replaceDummyEntityGhost(waterGhostEntity)
    end
end

--add event handler for on_tick
Event.on_nth_tick(60, waterGhostUpdate)