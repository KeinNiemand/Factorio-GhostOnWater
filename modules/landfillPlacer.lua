--requires
local Geom2D = require('lib/Geom2D')
local table = require('__stdlib__/stdlib/utils/table')
local Area = require('__stdlib__/stdlib/area/area')
local Is = require('__stdlib__/stdlib/utils/is')
local waterGhostCommon = require('modules/waterGhostCommon')


---This Module is used to place ghost landfill under dummy entity ghosts
local landfillPlacer = {}

local pumpLandfillOnCollisonMask = { "water-tile" }


---sets pumpLandfillOnCollsionMask based on the global.GhostOnWater.placableWaterTile
local function setPumpLandfillOnCollisionMask()
    if global.GhostOnWater.placableWaterTile then
        pumpLandfillOnCollisonMask = { "water-tile", "ground-tile" }
    else
        pumpLandfillOnCollisonMask = { "water-tile" }
    end
end

---finds the appropiate landfill type for a given tile and entity collision mask based on avaible landfill
local function getLandfillType(tile, colision)
    --nil check guards
    if not tile then
        return 
    end

    -- get first first item that places tile
    local tileCollsion = tile.prototype.collision_mask
    
    for i, landFillType in ipairs(landfillPlacer.activeLandfillTypes) do

        --Skip if the landfill type is nil should basically never happen so this check my be uneccary
        if (not landFillType) then
            goto nextLandfillType
        end
        
        local landfillCollisionMask = landFillType.collision_mask
        local itemName = landFillType.items_to_place_this[1].name
        local itemToPlace = game.item_prototypes[itemName]
        local landfillPlaceCollisionMask = itemToPlace.place_as_tile_result.condition

        --Skip if the tile is already the same type as the landfill
        if tile.prototype.name == landFillType.name then
            goto nextLandfillType
        end

        --Skip if this landfill can't be placed on this tile
        if waterGhostCommon.maskCollidesWithMaskRuntime(tileCollsion, landfillPlaceCollisionMask) then
            goto nextLandfillType
        end

        --Skip if the entiy can't be placed on the tile
        if waterGhostCommon.maskCollidesWithMaskRuntime(colision, landfillCollisionMask) then
            goto nextLandfillType
        end


        
        do return landFillType end
        ::nextLandfillType::
    end
end





local function getTileDataForBoundingBoxes(entity)
    local tileData = {}
    local surface = entity.surface
    local boundingBox = entity.bounding_box

    --function inside function that gets the tiles in a bounding box and adds them to the tiles table
    local getTilesFromBoundingBox = function(boundingBox)
        local tilesInBox = {}
        local tilePositions = Geom2D.get_overlapping_tiles(boundingBox)
        --tilePositions[x][y] tile position that overlap are true
        for x, yTable in pairs(tilePositions) do
            for y, overlap in pairs(yTable) do
                if overlap then
                    local tile = surface.get_tile(x, y)
                    table.insert(tilesInBox, tile)
                end
            end
        end
        return tilesInBox
    end

    local getTileData = function(boundingBox, collsionMask, collisionTest)
        return {
            tiles = getTilesFromBoundingBox(boundingBox),
            collision_mask = collsionMask,
            collision_test = collisionTest
        }
    end

    --return if entity is not a valid entity
    if (not Is.valid(entity)) then
        return tileData
    end

    local orignalName = waterGhostCommon.getOriginalEntityName(entity.ghost_name)
    local prototype = game.entity_prototypes[orignalName]
    if entity.ghost_type == "offshore-pump" then

        if not prototype then return tileData end

        --main bouding box contains both the part of the pump that is on land and the part that is on water
        --add tile from main bounding box if it collides with water
        if (table.any(pumpLandfillOnCollisonMask, function(mask)
            return prototype.collision_mask[mask]
        end)) then 
            table.insert(tileData,getTileData(boundingBox,prototype.collision_mask))
         end

        --add tiles from center bounding box
        --get the bounding box of the part of the pump that is on land
        table.insert(tileData, {tiles = {surface.get_tile(entity.position.x, entity.position.y)}, collision_mask = {["water-tile"] = true}} )

        --add tiles from adjacent bounding boxe if the mask collides with water
        if (table.any(pumpLandfillOnCollisonMask, function(mask)
            return prototype.adjacent_tile_collision_mask[mask]
        end)) then

            local adjacentBoundingBox = waterGhostCommon.calculateBoundingBox(entity.position, prototype.adjacent_tile_collision_box, entity.direction)

            table.insert(tileData,getTileData(adjacentBoundingBox, prototype.adjacent_tile_collision_mask, prototype.adjacent_tile_collision_test))
        end
        
    else
        table.insert(tileData,getTileData(boundingBox, prototype.collision_mask)) 
    end

    --if secondary_bounding_box is not nil, get tiles in secondary_bounding_box and add them to the tiles table
    if entity.secondary_bounding_box then
        local secondaryBoundingBox = entity.secondary_bounding_box
        table.insert(tileData,getTileData(secondaryBoundingBox, prototype.collision_mask))
    end

    
    return tileData
end

---activleLandfillTypes is a table that contains all the landfill types that are currently active for diffrent
---replaceable floors usually water (landfill), but can also be space(scafolding) or ground(waterfill) if SE and or a waterfill mod is installed
landfillPlacer.activeLandfillTypes = 
{
    
}

---function that places ghost landfill under dummy entity ghosts
landfillPlacer.placeGhostLandfill = function(dummyEntity)
    --get landfill type from settings
    local surface = dummyEntity.surface
    local tileDataUnderEntity = getTileDataForBoundingBoxes(dummyEntity)
    table.each(tileDataUnderEntity, function(tilesData)
        if not tilesData.tiles then return end 

        table.each(tilesData.tiles, function(tile)
            --check if tile is not nil
            if (not tile) then
                return
            end
            --check if tile is valid
            if (not Is.valid(tile)) then
                return
            end
            --check if tile already has a tile ghost
            if tile.has_tile_ghost() then
                return
            end

            --check if the enity can already be placed on the current tile
            if (not waterGhostCommon.maskCollidesWithMaskRuntime(tile.prototype.collision_mask, tilesData.collision_mask)) then
                return
            end
    
            local usedLandfillType = getLandfillType(tile, tilesData.collision_mask)

            if (not usedLandfillType) then
                return
            end
    
            surface.create_entity { name = "tile-ghost", position = tile.position, force = dummyEntity.force,
            raise_built = true ,inner_name = usedLandfillType.name }
        end)
    end)
    
end

---fills the active landfill table based on configuration and active mods must be called wheaver mod settings (runtime) change 
landfillPlacer.reFillActiveLandfillTypes = function(self)
    landfillPlacer.activeLandfillTypes = {}
    table.insert(self.activeLandfillTypes, game.tile_prototypes[settings.global.WaterGhostUsedLandfillType.value])

    if global.GhostOnWater.emptySpaceCollsion then
        table.insert(self.activeLandfillTypes, game.tile_prototypes[settings.global.WaterGhostUsedSpaceLandfillType.value])
    end

    if global.GhostOnWater.placableWaterTile then
        table.insert(self.activeLandfillTypes, global.GhostOnWater.placableWaterTile)
    end

end

---fucntion to inistilise the landfillPlace, must be called at least once and after global is inistilised
landfillPlacer.init = function(self)
    setPumpLandfillOnCollisionMask()
    self:reFillActiveLandfillTypes()
end

return landfillPlacer