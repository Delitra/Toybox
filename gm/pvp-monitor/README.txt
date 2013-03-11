PVP Monitor
Copyright (c) 2010 sk89q <http://www.sk89q.com>
Licensed under the GNU General Public License v2

Introduction
------------

Every time there is a player vs. player kill or a suicide, it will be
reported to you in chat and the location of the kill will be drawn
on your HUD for a short period of time. A cyan box will be highlighted
over the player as well so you can easily spot the attacker.

This addon is meant for servers with low instances of PvP. On servers
where PvP is common, your chat will be flooded and your HUD will be
filled, and thus this addon is not very useful in those cases.

Only administrators will see the deaths.

On gamemodes that let people change their player name, you will have
to modify the Lua file (where indicated) in order to support your
gamemode, otherwise only the player's non-Steam name may be shown. If
you use DarkRP, PVP Monitor is already configured to use Steam names
provided by DarkRP.

It is recommended that administrators have some HUD addon that will
draw players' names as this addon will not do that on its own.