local dummyGenerator = require("prototypes/dummyGenerator")
local selectionPriorityFix = require("lib/SelectionPriorityFix")

dummyGenerator.GenerateDummyPrototypes()
selectionPriorityFix.FixSelectionPriority()