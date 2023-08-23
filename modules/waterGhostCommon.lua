--Module for function related to the water ghost entities used by multple different modules that won't fit in any other module
local waterGhostCommon = {}

--require
local constants = require('modules/constants')
local table = require('__stdlib__/stdlib/utils/table')

--function to check if a dummy entity prototype exists
waterGhostCommon.dummyEntityPrototypeExists = function(entityName)
    --check if the dummy entity prototype exists
    local dummyEntityPrototype = global.GhostOnWater.WaterGhostNames[constants.dummyPrefix .. entityName]
    return dummyEntityPrototype ~= nil
end

--function to get the original entity name from the dummy entity name
waterGhostCommon.getOriginalEntityName = function(dummyEntityName)
    --get the original entity name from the dummy entity name
    local originalEntityName = string.sub(dummyEntityName, string.len(constants.dummyPrefix) + 1)
    return originalEntityName
end

---Get's the first placable water tile (there should be one if there is a waterfill mod) or nil if none exists
waterGhostCommon.getPlacableWaterTile = function()
    --check if there is an item that places a water-tile and return that water tile item if it exists
    local waterTileItem = nil
    for _, item in pairs(game.item_prototypes) do
        if item.place_as_tile_result and string.sub(item.place_as_tile_result.result.name, 1, 5) == "water" then
            return item.place_as_tile_result.result
        end
    end
    return nil
end

---function to check if two collision masks collide with each other (returns true if they collide)
waterGhostCommon.maskCollidesWithMaskRuntime = function(mask1, mask2)
    return table.any(mask1, function(mask1Value, mask1) return mask2[mask1] end)
end

---calculate boudning box (collison box with respect to entity posistion and direction)
waterGhostCommon.calculateBoundingBox = function(entity_position, collision_box, direction)
    -- Step 1: Calculate unrotated bounding box relative to entity_position
    local unrotated_left_top = {
        x = entity_position.x + collision_box.left_top.x,
        y = entity_position.y + collision_box.left_top.y
    }
    local unrotated_right_bottom = {
        x = entity_position.x + collision_box.right_bottom.x,
        y = entity_position.y + collision_box.right_bottom.y
    }

    -- Step 2: Rotate bounding box
    if direction == defines.direction.east then  -- East
        return {
            left_top = {
                x = entity_position.x - collision_box.left_top.y,
                y = entity_position.y + collision_box.left_top.x
            },
            right_bottom = {
                x = entity_position.x - collision_box.right_bottom.y,
                y = entity_position.y + collision_box.right_bottom.x
            },
            orientation = 90
        }
    elseif direction == defines.direction.south then  -- South
        return {
            left_top = {
                x = entity_position.x - collision_box.left_top.x,
                y = entity_position.y - collision_box.left_top.y
            },
            right_bottom = {
                x = entity_position.x - collision_box.right_bottom.x,
                y = entity_position.y - collision_box.right_bottom.y
            },
            orientation = 180
        }
    elseif direction == defines.direction.west then  -- West
        return {
            left_top = {
                x = entity_position.x + collision_box.left_top.y,
                y = entity_position.y - collision_box.left_top.x
            },
            right_bottom = {
                x = entity_position.x + collision_box.right_bottom.y,
                y = entity_position.y - collision_box.right_bottom.x
            },
            orientation = 270
        }
    else  -- North or any other case
        return {
            left_top = unrotated_left_top,
            right_bottom = unrotated_right_bottom
        }
    end
end

return waterGhostCommon