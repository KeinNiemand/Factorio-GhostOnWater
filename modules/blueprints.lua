---This Module is responsible for updating blueprints and repacle their contents with dummy water ghost entity_prototypes
local blueprints = {}
local constants = require('modules/constants')
local waterGhostCommon = require('modules/waterGhostCommon')
local Inventory = require('__stdlib__/stdlib/entity/inventory')
local table = require('__stdlib__/stdlib/utils/table')


blueprints.updateBlueprint = function(playerIndex)
    --get the player
    local player = game.players[playerIndex]
    --check if the player has a blueprint selected return if not
    if not player.is_cursor_blueprint() then return end

    --check if player is really holding a blueprint item stack
    local blueprintStack = player.cursor_stack
    --Return if blueprintStack is null or not valid_for_read
    if not blueprintStack then return end
    if not blueprintStack.valid_for_read then return end
    --get blueprint entities
    local blueprintEntities = player.get_blueprint_entities()

    --replace blueprint entities with dummy entities using table.map
    local dummyEntities = table.map(blueprintEntities, function(entity)
        if (waterGhostCommon.dummyEntityPrototypeExists(entity.name)) then
            --replace entity with dummy entity
            entity.name = constants.dummyPrefix .. entity.name
        end
        return entity
    end)

    --set the blueprint entities
    local itemStack = player.cursor_stack
    local blueprint = Inventory.get_blueprint(itemStack)
    blueprint.set_blueprint_entities(dummyEntities)

end

return blueprints