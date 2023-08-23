---------------------------------------Requires-------------------------------------------------------------
local constants = require('modules/constants')
local mask_util = require("collision-mask-util")
local util = require("util")
local Is = require('__stdlib__/stdlib/utils/is')
local table = require('__stdlib__/stdlib/utils/table')

---------------------------------------Setup-----------------------------------------------------------------
local dummyGenerator = {}
--Collsion mask that gets removed from water ghost dummy entities, things lke space may get added to this list even though they are not water
local waterCollisionMask = table.deepcopy(data.raw["tile"]["water"].collision_mask)
-- collison masks that have to be removed from the collision mask of the dummy entity but are
-- required to collide with other entites so entities can be placed on top of themselves/other entities
-- mostly for compatibility with other mods (space exploration), but also for some special vanilla cases
-- a new layer gets added to dummy entites + any original entity that has a collision mask that contains any of these layers
local specialRemovalCollsionMask = {
    ["item-layer"] = "" --necessary for rail/chain signals colliding with trees
}

--table with all entity prototypes
local entityTable = {}

local dummyEntityCreatedFor =  {}

local waterFillFound = false
---------------------------------------Dummy Generator Functions-------------------------------------------------

--todo move this to a separate file or use stdlib
--function to check if a table contains a key without using a loop
function table.contains(table, key)
    return table[key] ~= nil
end

--todo move this to a separate file or use stdlib
--function to check if a table contains a value
function table.containsValue(table, value)
    for k, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

--todo move this to a separate file or use stdlib
--function to get the index of a value in a table
function table.indexOf(table, value)
    for k, v in pairs(table) do
        if v == value then
            return k
        end
    end
    return nil
end

---Handles compatibility with other mods, specifcly cases where things need to be done in init (changes to waterCollisonMask and specialRemovalCollsionMask)
local function modSpecificCompatibility()
    --space exploration compatibility
    if (mods["space-exploration"]) then
        specialRemovalCollsionMask["object-layer"] =
        ""                                          -- collision layer for empty space, but needed for most object collisions
        specialRemovalCollsionMask["water-tile"] =
        ""                                          -- Workaround until SE adds the item-layer collision to all entities placeable in empty space

        --consider empty space as water so it also gets removed
        ---@diagnostic disable-next-line: undefined-global
        mask_util.add_layer(waterCollisionMask, empty_space_collision_layer)
    end

    --alien biomes shallow water compatibility
    if (mods["alien-biomes"]) then
        --shalloow water
        mask_util.add_layer(waterCollisionMask, "floor-layer")
        specialRemovalCollsionMask["floor-layer"] =
        ""                                         -- necessary, because it is the only common collision layer between rail/chain signals and transport belts, heat pipes
    end
end

local function addSpecialRemovalsToWaterCollisons()
    --add anything in specialRemovalCollsionMask to waterCollisionMask so it gets removed from the dummy entity
    table.each(specialRemovalCollsionMask, (function(altLayer ,layer)
        mask_util.add_layer(waterCollisionMask, layer)
    end))
end
---generate table with all entity prototypes, stored in the file scope local entityTable
local function fillEntityTable()
    for type in pairs(defines.prototypes.entity) do
        for _, prototype in pairs(data.raw[type]) do
            entityTable[prototype.name] = prototype
        end
    end
end

--Check Wheter or not Water tile is placable (=> some kind of waterfill mod installed)
local function checkWaterTileIsPlacable()
    for name, prototypeItem in pairs(data.raw["item"]) do
        if not prototypeItem.place_as_tile then
            goto nextItem
        end

        if string.sub(prototypeItem.place_as_tile.result, 1, 5)== "water" then
            return true
        end 

        ::nextItem::
    end

    return false
end 

local function init()
    modSpecificCompatibility()
    addSpecialRemovalsToWaterCollisons()
    fillEntityTable()

    --remove ground-tile from all collision masks if there is a water fill mod
    waterFillFound = checkWaterTileIsPlacable()
    if waterFillFound then
        mask_util.add_layer(waterCollisionMask, "ground-tile")
    end
end




--adds alternative layer for special removal collision mask
local function addAlternativeLayerForSpeicalRemovals(entitys)
    if Is.Empty(specialRemovalCollsionMask) then return end

    table.each(specialRemovalCollsionMask, function(altLayer ,layer)
         --get unused collision layer and store it in speical removal collision mask
         if altLayer == "" then
             altLayer = mask_util.get_first_unused_layer()
             specialRemovalCollsionMask[layer] = altLayer
         end

         for _, prototype in pairs(entitys) do
            if not prototype then goto next end

            local mask = mask_util.get_mask(prototype)

            if mask_util.mask_contains_layer(mask, layer) then
                --add alt layer to entity
                mask_util.add_layer(mask, altLayer)
                prototype.collision_mask = mask
                data:extend({prototype})
            end
            ::next::
         end
    end)
 end

--checks if an entity collides with a collsion mask including the speical masks used for offshore pumps
local function entityCollidesWithMask(entity, colidesWithMask)
    --check if the entity has a collision_mask
    if entity == nil then
        return false
    end


    local mask = mask_util.get_mask(entity)
    --Offshore Pump
    local mask2 = entity.adjacent_tile_collision_mask
    local mask3 = entity.center_collision_mask
    local test = entity.fluid_box_tile_collision_test
    local test2 = entity.adjacent_tile_collision_test

    if mask then
        --check if the collision_mask contains the water layer
        --use serpent to print the table collision_mask
        if mask_util.masks_collide(mask, colidesWithMask) then
            return true
        end
    end
    if mask2 then --Offshore pumps
        if mask_util.masks_collide(mask2, colidesWithMask) then
            return true
        end
    end
    if mask3 then --Offshore pumps
        if mask_util.masks_collide(mask3, colidesWithMask) then
            return true
        end
    end
    if test then  --Offshore pumps
        if not mask_util.masks_collide(test, colidesWithMask) then
            return true
        end
    end
    if test2 then --Offshore pumps
        if not mask_util.masks_collide(test2, colidesWithMask) then
            return true
        end
    end
    return false
end

--remove everything from mask that is in maskToRemove
local function  removeCollisionMaskFromCollisonmask(mask, maskToRemove)
    for _, item in pairs(maskToRemove) do
        local index = table.indexOf(mask, item)
        if index ~= nil then
            table.remove(mask, index)
        end
    end
end


local function createDummyEntity(originalEntity)
    local dummyEntity = table.deepcopy(originalEntity)
    --remove collision with water tile
    local originalMask = mask_util.get_mask(dummyEntity)
    if (not originalMask) then
        return nil
    end

    --handle offshore pumps specific masks and tests
    local originalMask2 = dummyEntity.adjacent_tile_collision_mask
    local originalMask3 = dummyEntity.center_collision_mask
    local originalTest = dummyEntity.fluid_box_tile_collision_test
    local originalTest2 = dummyEntity.adjacent_tile_collision_test
    if originalMask2 then
        removeCollisionMaskFromCollisonmask(dummyEntity.adjacent_tile_collision_mask, waterCollisionMask)
    end
    if originalMask3 then
        removeCollisionMaskFromCollisonmask(dummyEntity.center_collision_mask, waterCollisionMask)
    end
    if originalTest then
        if (not table.is_empty(originalTest)) and Is.Table(originalTest) then
            mask_util.add_layer(dummyEntity.fluid_box_tile_collision_test, "water-tile")
            if (waterFillFound) then
                mask_util.add_layer(dummyEntity.fluid_box_tile_collision_test, "ground-tile")
            end
        elseif Is.String(originalTest) then
            if (waterFillFound) then
                dummyEntity.fluid_box_tile_collision_test = {"water-tile", "ground-tile"}
            else 
                dummyEntity.fluid_box_tile_collision_test = {"water-tile"}
            end
        end

    end
    if originalTest2 then

        --if originalTest2 is not empty
        if not table.is_empty(originalTest2) and Is.Table(originalTest2) then
            mask_util.add_layer(dummyEntity.adjacent_tile_collision_test ,"water-tile")
            if (waterFillFound) then
                mask_util.add_layer(dummyEntity.adjacent_tile_collision_test, "ground-tile")
            end
        elseif Is.String(originalTest2) then
            if (waterFillFound) then
                dummyEntity.adjacent_tile_collision_test = {"water-tile", "ground-tile"}
            else 
                dummyEntity.adjacent_tile_collision_test = "water-tile"
            end
        end

    end

    --remove water-tile from collision mask
    dummyEntity.collision_mask = originalMask
    --remove all collsion mask items in water-tile-collsion-mask
    removeCollisionMaskFromCollisonmask(dummyEntity.collision_mask, waterCollisionMask)

    --change the name of the dummy prototype to dummyPrefix .. name
    dummyEntity.name = constants.dummyPrefix .. dummyEntity.name

    --add the hidden flag to the flags table
    if dummyEntity.flags == nil then
        dummyEntity.flags = {}
    end
    table.insert(dummyEntity.flags, "hidden")

    --remove the not-upgradable flag from the flags table
    if (table.containsValue(dummyEntity.flags, "not-upgradable")) then
        table.remove(dummyEntity.flags, table.indexOf(dummyEntity.flags, "not-upgradable"))
    end
    --table.remove(dummyEntity.flags, table.indexOf(dummyEntity.flags, "not-upgradable"))

    --check if next-upgrade exists
    --if dummyEntity.next_upgrade then
    --set the next_upgrade of the dummy prototype to dummyPrefix .. next_upgrade
   --     dummyEntity.next_upgrade = constants.dummyPrefix .. dummyEntity.next_upgrade
    --end
    dummyEntity.next_upgrade = nil

    --if the entity is minable, remove the mining result
    if dummyEntity.minable then
        dummyEntity.minable.result = nil
        dummyEntity.minable.results = nil
    end

    if dummyEntity.placeable_by then
        if dummyEntity.placeable_by.item then
            dummyEntity.placeable_by = { item = constants.dummyPrefix .. dummyEntity.placeable_by.item, count = dummyEntity.placeable_by.count }

        else
            dummyEntity.placeable_by = table.map
            (dummyEntity.placeable_by,
            function(itemToPlace)
                return { item = constants.dummyPrefix .. itemToPlace.item, count = itemToPlace.count }
            end) end
    end

    --if the entity is not in a quick replace group, add it and the original entity to the group with the name of the dummy entity
    if dummyEntity.fast_replaceable_group == nil then
        dummyEntity.fast_replaceable_group = dummyEntity.name
        originalEntity.fast_replaceable_group = dummyEntity.name
    end

    --remove any autoplace spec in the entity
    dummyEntity.autoplace = nil

    --remove existing crafting categories from the dummy entity so factory planners don't see them as valid machines
    --factorio requires the entity to have 'a' crafting category, so we replace it with a dummy category that has no recipes
    --COMMENTED OUT BECOUSE A FACTORIO UPDATE BETWEEN 1.1.81-1.1.87 BROKE THIS RECIPE IS NO LONGER PRESERVED
    --if dummyEntity.crafting_categories ~= nil then
    --    dummyEntity.crafting_categories = { constants.dummyPrefix }
    --end


    --generate localisation from the original entity
    dummyEntity.localised_name = {"", originalEntity.localised_name or {"entity-name." .. originalEntity.name}, " - ", {"dummy_name_suffix"}}

    --set the subgrouo of the dummy entity to the constants.dummyPrefix
    dummyEntity.subgroup = constants.dummyPrefix

    dummyEntityCreatedFor[originalEntity.name] = true
    --return the dummy prototype
    return dummyEntity
end

local function createDummyItem(originalItem)
    --check if the entity has a collision mask
            local dummyItem = table.deepcopy(originalItem)
            --change the name of the dummy prototype to dummyPrefix .. name
            dummyItem.name = constants.dummyPrefix .. originalItem.name

            --chagne place_result to dummyPrefix .. place_result
            if (dummyItem.place_result) then
                dummyItem.place_result = constants.dummyPrefix .. dummyItem.place_result
            end

            if (dummyItem.straight_rail)
            then
                dummyItem.straight_rail = constants.dummyPrefix .. originalItem.straight_rail
            end

            if (dummyItem.curved_rail)
            then
                dummyItem.curved_rail = constants.dummyPrefix .. originalItem.curved_rail
            end

            --set item group to dummy item group
            dummyItem.group = constants.dummyPrefix
            --set item subgroup to nil
            dummyItem.subgroup = constants.dummyPrefix
            --Compose icon
            local overlay_icon = {
                icon = "__GhostOnWater__/icons/waterGhostBlueprintUpdate.png",
                icon_size = 256,
                scale = 0.075,
                shift = {6, -6}
            }
            if dummyItem.icons == nil then
                dummyItem.icons = {
                    {
                        icon = dummyItem.icon,
                        icon_size = dummyItem.icon_size
                    },
                    overlay_icon
                }
            else
                table.insert(dummyItem.icons, overlay_icon)
            end

            if dummyItem.flags == nil then
                dummyItem.flags = {}
            end
            table.insert(dummyItem.flags, "hidden")

             --generate localisation from the original item
            dummyItem.localised_name = {"", originalItem.localised_name or {"entity-name." .. originalItem.name}, " - ", {"dummy_name_suffix"}}

            return dummyItem
end

local function ghostOnWaterDummyItemExists(itemName)
    local dummyName = constants.dummyPrefix .. itemName
    -- Check if the item already has a dummy
    return data.raw["item"][dummyName] ~= nil
end

--Generated by GPT-4
local function findOriginalItem(itemName)
    for type in pairs(defines.prototypes.item) do
        local item = data.raw[type][itemName]
        if item then
            return item
        end
    end
    return nil
end


dummyGenerator.GenerateDummyPrototypes = function()
    --initilise the dummy generator
    init()

    --handle special removals
    addAlternativeLayerForSpeicalRemovals(entityTable)

    for name, prototypeItem in pairs(data.raw["item"]) do
        if prototypeItem.place_result then
            if entityCollidesWithMask(entityTable[prototypeItem.place_result], waterCollisionMask) then
                local dummyItem = createDummyItem(prototypeItem)
                data:extend({dummyItem})
                local dummyEntity = createDummyEntity(entityTable[prototypeItem.place_result])
                data:extend({dummyEntity})
            end
        end
    end
    
    --go trogh all rail-planners
    for name, prototypeRailPlaner in pairs(data.raw["rail-planner"]) do


        --return if this is a dummy rail-planner
        if (util.string_starts_with(name, constants.dummyPrefix)) then
            goto continue
        end

        --return if ral planer has no straight_rail
        if prototypeRailPlaner.straight_rail == nil then
            goto continue
        end

        --return if rail planer has no curved_rail
        if prototypeRailPlaner.curved_rail == nil then
            goto continue
        end

        local straightRailCollidesWithWater = entityCollidesWithMask(entityTable[prototypeRailPlaner.straight_rail], waterCollisionMask)
        local curvedRailCollidesWithWater = entityCollidesWithMask(entityTable[prototypeRailPlaner.curved_rail], waterCollisionMask)

        if straightRailCollidesWithWater or curvedRailCollidesWithWater then
            local dummyItem = createDummyItem(prototypeRailPlaner)
            data:extend({dummyItem})
        end

        if straightRailCollidesWithWater or curvedRailCollidesWithWater then
            local dummyEntity = createDummyEntity(entityTable[prototypeRailPlaner.straight_rail])
            data:extend({dummyEntity})
        end

        if straightRailCollidesWithWater or curvedRailCollidesWithWater then
            local dummyEntity = createDummyEntity(entityTable[prototypeRailPlaner.curved_rail])
            data:extend({dummyEntity})
        end

        ::continue::
    end

    for name, prototype in pairs(entityTable) do
        if prototype.placeable_by == nil then
            -- can't be placed via blueprint
            goto continue_entity
        end
        if not entityCollidesWithMask(prototype, waterCollisionMask) then
            goto continue_entity
        end
    
        -- If prototype has placeable_by items, check all of them and create missing dummy items
         -- If prototype has placeable_by items, check all of them and create missing dummy items
        local placeableByItems = (type(prototype.placeable_by) == 'table' and prototype.placeable_by.item == nil) and prototype.placeable_by or {prototype.placeable_by}

        for _, itemToPlace in ipairs(placeableByItems) do
            if not ghostOnWaterDummyItemExists(itemToPlace.item) then
                local originalItem = findOriginalItem(itemToPlace.item)
                if originalItem then
                    local dummyItem = createDummyItem(originalItem)
                    data:extend({dummyItem})
                else
                    log("Original item not found for: " .. itemToPlace.item)  -- Debug print
                end
            end
        end

    
        if dummyEntityCreatedFor[prototype.name] then
            -- ghost on water dummy already exists
            goto continue_entity
        end
    
        local dummyEntity = createDummyEntity(prototype)
        data:extend({dummyEntity})
        ::continue_entity::
    end


end

return dummyGenerator