--used landfill type setting

local isLandfillPaintingLoaded = mods["LandfillPainting"]

local lanfillTypes = { "landfill" }

if (isLandfillPaintingLoaded) then
    table.insert(lanfillTypes, "landfill-dry-dirt")
    table.insert(lanfillTypes, "landfill-dirt-4")
    table.insert(lanfillTypes, "landfill-grass-1")
    table.insert(lanfillTypes, "landfill-red-desert-1")
    table.insert(lanfillTypes, "landfill-sand-3")
end


local usedLandfillType = {
    type = "string-setting",
    name = "usedLandfillType",
    setting_type = "runtime-global",
    default_value = "landfill",
    allowed_values = lanfillTypes,
}

data:extend({ usedLandfillType })