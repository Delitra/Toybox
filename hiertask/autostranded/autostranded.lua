-- Copyright (c) 2010 sk89q <http://www.sk89q.com>
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- $Id$

include("includes/modules/hiertask.lua")
include("autostranded/lib.lua")
include("autostranded/tasks/movement.lua")
include("autostranded/tasks/say_text.lua")
include("autostranded/tasks/drinking.lua")

local root = hiertask.CreateStack()
root:Add(AutoStranded.Move(Vector(2086.4636, 326.9690, -0.9687), true))
root:Add(AutoStranded.SayText("Hi"))
root:Add(AutoStranded.Drink(Vector(1352.8901, -929.3822, -0.9688)))

local function CreateMove(usercmd)
    root:Run(root, usercmd)
end

local function HUDPaint()
    root:DrawHUDTree(100, 100)
end

hook.Add("HUDPaint", "AutoStranded", HUDPaint)
hook.Add("CreateMove", "AutoStranded", CreateMove)