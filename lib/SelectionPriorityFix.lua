--This software is based on a part of Data Final fixes from the spidertron weapon switcher mod orignal source code:https://github.com/tburrows13/SpidertronWeaponSwitcher/blob/ecf52cbfebecb2422bece14ce4fa6c51d29dcbe2/data-final-fixes.lua
--Licence for orignal source code: SelectionPriorityFix_LICENCE.txt
--Modification to the original code are licensed under the MIT License (MIT) that can be found in the LICENSE file (in the root of the repository) 

-- The above collision mask changes make train selection priority lower than the track's
-- May not be needed as of v1.2.9
local selectionPriorityFix = {}

selectionPriorityFix.FixSelectionPriority = function()
    for _, type in pairs({"artillery-wagon", "cargo-wagon", "fluid-wagon", "locomotive", "car"}) do
        for _, prototype in pairs(data.raw[type]) do
          if not prototype.selection_priority or prototype.selection_priority == 50 then
            prototype.selection_priority = 51
          end
        end
      end
      
      -- Now that vehicles have selection_priority = 51, bump up all spidertrons to 52
      for _, type in pairs({"spider-vehicle"}) do
        for _, prototype in pairs(data.raw[type]) do
          if prototype.selection_priority and prototype.selection_priority == 51 then
            prototype.selection_priority = 52
          end
        end
      end
end

return selectionPriorityFix