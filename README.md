About this mod
============

This is a mod for the game Factorio.     
This mods makes it possible to place blueprints on water or in space(Space Exploration). Ghost Landfill/Space Scaffolding) is automatically added once a blueprint has been placed on water.
     
How to use this mod
================
1. Hold a blueprint, blueprint book or copy paste something
    Held blueprints must be stored in the players inventory, blueprints in the blueprint library will not work.
2. Press Control + W (can be changed in control settings) or click on the shortcut button to make blueprint water/space placeable, this converts everything in the blueprint to water/space placeable water ghosts.
    *    Converted Blueprints can not be used without having this mod installed, to restore the original blueprint press Control + Shift + W while holding a converted blueprint or use the shortcut button.
    *    Make sure to revert any converted blueprints you want to use without this mod.
3. Place Blueprint, this can be on water or on land.
4. Water Ghosts placed on water will automatically build ghost landfill/space scaffolding.
5. Once Landfill has been build (manually or by bots)  or if the water ghosts have been placed on land, water ghosts will turn back into regular ghosts, that can be build by bots.
       
Compatibility 
=========
 *   Supports Landfill types from Landfill Painting mod (included in seablock). You can select the used landfill type in mod settings.
*    Supports placing blueprints in Space in Space Exploration. You can select the type of platform build in space in mod settings (setting is only visable if space exploration is installed)
*    This mod should be compatible with entities from most if not all other mods.  Please report anything incompatible.

How this mod works
================
This mod adds a water placeable dummy copy of every entity in the game (including ones from other mods) when you convert a blueprints all entities in that blueprint get replaced by their water placeable counterparts, so called Water Ghost entities. When ghosts of these Water Ghost entities are on the map the mod checks if the original entity can be placed in it's location, if it can it replaces the water ghost with a ghost of the original entity that can the be build by bots. The mod also automatically adds ghost landfill under any water ghosts placed on water.
     
Bug Reports/Improvement Suggestions
===============================
Please Open an Issue on GitHub to report any issue or make suggestions for improvements.   
Feel free to Open a Pull Request if you want to contribute
     
Credits
======
 *   This Mod uses some code from (geom2d.lua) from [Kux-BlueprintExtensions](https://mods.factorio.com/mod/Kux-BlueprintExtensions). [License for used code](https://github.com/KeinNiemand/Factorio-GhostOnWater/blob/master/lib/Geom2D_LICENCE.txt)
*    GitHub Contributors: [Soggs](https://github.com/Soggs), [ChaosSaber](https://github.com/ChaosSaber)
