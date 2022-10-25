--Module for function related to the water ghost entities used by multple different modules that won't fit in any other module
local waterGhostCommon = {}

--require
local constants = require('modules/constants')

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

return waterGhostCommon