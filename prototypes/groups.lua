local constants = require('modules/constants')


local waterGhostItemGroup = {
    type = "item-group",
    name = constants.dummyPrefix,
    order = "zzz",
    inventory_order = "zzz",
    icon = "__GhostOnWater__/icons/waterGhostBlueprintUpdate.png",
    icon_size = 256,
}

data:extend({waterGhostItemGroup})