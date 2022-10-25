---This Module is used to place ghost landfill under dummy entity ghosts
local landfillPlacer = {}
local Geom2D = require('lib/Geom2D')
local table = require('__stdlib__/stdlib/utils/table')



local function getTilesInBoundingBox(entity)
    local tiles = {}
    local surface = entity.surface

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

    local boundingBox = entity.bounding_box
    addTilesFromBoundingBox(boundingBox)

    --local tiles = surface.find_tiles_filtered{area = boundingBox}
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
landfillPlacer.placeGhostLandfill = function(dummyEntity)
    --get landfill type from settings
    local usedLandfillType = settings.global["WaterGhostUsedLandfillType"].value
    local surface = dummyEntity.surface
    local tilesUnderEntity = getTilesInBoundingBox(dummyEntity)
    table.each(tilesUnderEntity, function(tile)
        --check if tile would collide with player
        if (not tile.collides_with("player-layer")) or tile.has_tile_ghost() then
            return
        end
        surface.create_entity { name = "tile-ghost", position = tile.position, force = dummyEntity.force,
            inner_name = usedLandfillType }
    end)
end

return landfillPlacer