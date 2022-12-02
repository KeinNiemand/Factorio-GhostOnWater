---This Module is responsible for updating blueprints and repacle their contents with dummy water ghost entity_prototypes
local blueprints = {}
local constants = require('modules/constants')
local waterGhostCommon = require('modules/waterGhostCommon')
local Inventory = require('__stdlib__/stdlib/entity/inventory')
local table = require('__stdlib__/stdlib/utils/table')
local util = require('util')


blueprints.updateBlueprint = function(playerIndex, replacerFunction)
    --get the player
    local player = game.players[playerIndex]
    --check if player is holding a single blueprint or a book
    if player.cursor_stack.is_blueprint then
       blueprints.updateSingleBlueprint(player.cursor_stack, replacerFunction)
    elseif player.cursor_stack.is_blueprint_book then
       blueprints.updateBlueprintBook(player.cursor_stack, replacerFunction)
    end
    --otherwise, do nothing
end

--- Update a single blueprint, applying the replacerFunction to every entity in the blueprint.
-- @tparam LuaItemStack blueprint
-- @tparam func replacerFunction
blueprints.updateSingleBlueprint = function(blueprint, replacerFunction)
    --Safety checks: make sure stack is a blueprint and valid
   if not blueprint then return end
   if not blueprint.valid_for_read then return end
   if not blueprint.is_blueprint then return end
   if not blueprint.is_blueprint_setup() then return end

   --get blueprint entities
   local blueprintEntities = blueprint.get_blueprint_entities()
   --return if blueprintEntities is empty
   if # blueprintEntities == 0 then return end

   --replace blueprint entities with dummy entities using table.map
   local dummyEntities = table.map(blueprintEntities, replacerFunction)

   --set the blueprint entities
   blueprint.set_blueprint_entities(dummyEntities)
end

--- Update all blueprints in a book, applying the replacerFunction to every entity. Recurs into books inside.
-- @tparam LuaItemStack stack
-- @tparam func replacerFunction
blueprints.updateBlueprintBook = function(stack, replacerFunction)
    --Safety checks: make sure stack is a blueprint book and valid
   if not stack then return end
   if not stack.valid_for_read then return end
   if not stack.is_blueprint_book then return end

   -- Get the underlying inventory item
   local book = stack.get_inventory(defines.inventory.item_main)

   --Iterate through all blueprints in the book
   for i=1, #book do
      local bp = book[i]
      if bp and bp.valid and bp.valid_for_read then
         -- Update any blueprints
         if bp.is_blueprint then
            blueprints.updateSingleBlueprint(bp, replacerFunction)

         -- Update any books recursively
         elseif bp.is_blueprint_book then
            blueprints.updateBlueprintBook(bp, replacerFunction)
         end
      end
   end
end


blueprints.bpReplacerToDummy = function(entity)
    if (waterGhostCommon.dummyEntityPrototypeExists(entity.name)) then
        --replace entity with dummy entity
        entity.name = constants.dummyPrefix .. entity.name
    end
    return entity
end

blueprints.bpReplacerToOriginal = function(entity) 
    
    if (util.string_starts_with(entity.name, constants.dummyPrefix)) then
        --replace entity with original entity
        entity.name = waterGhostCommon.getOriginalEntityName(entity.name)
    end
    
    return entity
end

return blueprints