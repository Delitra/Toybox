Tabbed Spawn Menu
Copyright (c) 2010 sk89q <http://www.sk89q.com>
Licensed under the GNU General Public License v2

Introduction
------------

This addon further divides the props in the spawn menu into tabs based
on their "group." Groups are taken from square brackets ([]) that are 
in front of category names.

To create a new tab (group), just make a new category starting with "[" and "]"
and the group name in the middle.

Note that renaming an existing category will not create a new tab at the
present time. You can force a reload with the spawnmenu_reload concmd.

Ordering Groups
---------------

There is currently an inelegant way of ordering groups. Create the
"tabbed_spawnlist_order.txt" file in your Gmod data folder and list each group
on its own line. The top most group will be shown first. Any groups that
are not listed in this file will appear at the end in an undefined order.

Aliases and Combining Groups
----------------------------

Make a file named "tabbed_spawnlist_groups.txt" in your Gmod data folder and
in it put the name of the group and the alias in CSV format with each entry
on its own new line. For example, if you want to combine the groups "A" and
"B" into one group named "C", you would put the following in the file:

A,C
B,C

If you need to use a comma in the group name or alias, surround the field in
double quotation marks ("). The following is an example of aliases for some
Spacebuild-related groups.

SBMP,Spacebuild
ModBr,Spacebuild
Cerus,Spacebuild
