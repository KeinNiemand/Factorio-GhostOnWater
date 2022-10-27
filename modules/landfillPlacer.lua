---This Module is used to place ghost landfill under dummy entity ghosts
local landfillPlacer = {}
local Geom2D = require('lib/Geom2D')
local table = require('__stdlib__/stdlib/utils/table')
local Area = require('__stdlib__/stdlib/area/area')
local Is = require('__stdlib__/stdlib/utils/is')
local waterGhostCommon = require('modules/waterGhostCommon')

local pumpLandfillOnCollisonMask = { "water-tile" }
--for space exploration compatibility


local function getLandfillTypeForCollision()
    --local emptySpaceTileCollisionLayerPrototype = game.entity_prototypes["collision-mask-empty-space-tile"]
    local landfillTpyeForCollision = {} 
    landfillTpyeForCollision["water-tile"] = settings.global.WaterGhostUsedLandfillType.value
    --landfillTpyeForCollision["player-layer"] = settings.global.WaterGhostUsedLandfillType.value
    --add empty space collison if it exists for space exploration compatibility
    if global.GhostOnWater.emptySpaceCollsion then
        landfillTpyeForCollision["object-layer"] = settings.global.WaterGhostUsedSpaceLandfillType.value
    end

    return landfillTpyeForCollision
end

local function getTilesInBoundingBox(entity)
    local tiles = {}
    local surface = entity.surface
    local boundingBox = entity.bounding_box
    
    --if (prototype.collision_mask) then
    --    collisionMask = prototype.collision_mask
    --end

    --local addColidingTile = function(tile)
    --    if table.any(collisionMask, function(_ ,collision) return tile.collides_with(collision) end) then
    --        table.insert(tiles, tile)
    --    end
    --end

    --function inside function that gets the tiles in a bounding box and adds them to the tiles table
    local addTilesFromBoundingBox = function(boundingBox)
        local tilePositions = Geom2D.get_overlapping_tiles(boundingBox)
        --tilePositions[x][y] tile position that overlap are true

        for x, yTable in pairs(tilePositions) do
            for y, overlap in pairs(yTable) do
                if overlap then
                    local tile = surface.get_tile(x, y)
                    table.insert(tiles, tile)
                end
            end
        end
    end

    --return if entity is not a valid entity
    if (not Is.valid(entity)) then
        return tiles
    end

    if entity.ghost_type == "offshore-pump" then
        local orignalName = waterGhostCommon.getOriginalEntityName(entity.ghost_name)
        local prototype = game.entity_prototypes[orignalName]
        if not prototype then return tiles end

        --if the entity has an adjacent_tile_collision_mask add it to the collision mask
        --if prototype.adjacent_tile_collision_mask then
        --    table.each(prototype.adjacent_tile_collision_mask,function(_ ,collision)
        --        table.insert(collisionMask, collision)
        --    end)
        --end

        --main bouding box contains both the part of the pump that is on land and the part that is on water
        --add tile from main bounding box if it collides with water
        if (table.any(pumpLandfillOnCollisonMask, function(mask)
            return prototype.collision_mask[mask]
        end)) then addTilesFromBoundingBox(boundingBox) end

        --add tiles from center bounding box
        --get the bounding box of the part of the pump that is on land
        table.insert(tiles, surface.get_tile(entity.position.x, entity.position.y))

        --add tiles from adjacent bounding boxe if the mask collides with water
        if (table.any(pumpLandfillOnCollisonMask, function(mask)
            return prototype.adjacent_tile_collision_mask[mask]
        end)) then
            local adjacentBoundingBox = Area.offset(prototype.adjacent_tile_collision_box, entity.position)
            addTilesFromBoundingBox(adjacentBoundingBox)
        end
    else
        addTilesFromBoundingBox(boundingBox)
    end

    --if secondary_bounding_box is not nil, get tiles in secondary_bounding_box and add them to the tiles table
    if entity.secondary_bounding_box then
        local secondaryBoundingBox = entity.secondary_bounding_box
        addTilesFromBoundingBox(secondaryBoundingBox)
        --take boundingbox.oriantation into account
        --local orientation = entity.orientation
        --get the bounding box of the secondary bounding box
        --local secondaryBoundingBox = Area.getRotatedBoundingBoxes(secondaryBoundingBox, orientation)

        --local secondaryTiles = surface.find_tiles_filtered{area = secondaryBoundingBox}
        --table.each(secondaryTiles, function(tile)
        --    table.insert(tiles, tile)
        --end)
    end

    
    return tiles
end

--function that places ghost landfill under dummy entity ghosts
landfillPlacer.placeGhostLandfill = function(dummyEntity, tiles)
    --get landfill type from settings
    local surface = dummyEntity.surface
    local tilesUnderEntity = tiles or getTilesInBoundingBox(dummyEntity)
    local landFillForCollision = getLandfillTypeForCollision()
    table.each(tilesUnderEntity, function(tile)
        --check if tile would collide with player or water-tile
        if tile.has_tile_ghost() or (not table.any(landFillForCollision, function(lanfill, collsionLayer) return tile.collides_with(collsionLayer) end)) then
            return
        end

        local usedLandfillType = table.find(landFillForCollision, function(lanfill, collsionLayer) return tile.collides_with(collsionLayer) end)

        surface.create_entity { name = "tile-ghost", position = tile.position, force = dummyEntity.force,
        raise_built = true ,inner_name = usedLandfillType }
    end)
end



return landfillPlacer