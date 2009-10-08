SK's HoloMinimap
Copyright (c) 2009 sk89q <http://sk89q.therisenrealm.com>
Licensed under the GNU Lesser General Public License v3

Introduction
------------

HoloMinimap is an E2 script that renders a holographic minimap of
all the props and players in the level.

- Regular mode updates every 1 second (~6% usage), while a turbo mode
  updates continuously (>= 85% usage).
- The range of detection can be adjusted so that the minimap only
  shows objects near by.
- The minimap can be attached to a moving entity (i.e. a vehicle) and
  the holograms will move with the entity, even in non-turbo mode.
- The hologram shape changes depending on the prop, based on keywords
  in the name of the prop's model.
- The minimap is drawn relative to the E2 entity, so the middle of the
  minimap is the E2.
- Prop materials and colors are copied to the hologram.
- The script checks its usage to make sure it does not go over the
  limit.
- An output shows whether the minimap has completed accounting for the
  number of props (as the rate of holograms created is throttled).
- On/off toggle, with the off mode utilizing 0 ops.
- The Z of the holograms can be shifted.

Usage
-----

Input:
- On
- Range
- SizeScale (value is <= 1 for a "mini" map)
- PositionScale (value is <= 1 for a "mini" map)
- TurboMode
- ShiftZ
- ExcludeSelf
- ExcludeEntities:array
 
Output:
- Ready

Known Issues
------------

- The hologram tends to flicker occasionally, especially if a lot of
  objects are being created or destroyed.