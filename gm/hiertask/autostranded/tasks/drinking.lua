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

require("hiertask")

--------------------------------------------------------
-- Drink task group
--------------------------------------------------------

local TaskClass = hiertask.CreateTaskClass("DRINK")

--- Called to initialize the task.
function TaskClass:Initialize(drinkPos)
    self.DrinkPos = drinkPos
    
    self:Add(AutoStranded.CheckThirst(), 1, true)
    self:Add(AutoStranded.Move(drinkPos), 0, true)
    self:Add(AutoStranded.DownWaterLook(), 0, true)
    self:Add(AutoStranded.Use(), 0, true)
end

AutoStranded.Register("Drink", TaskClass)

--------------------------------------------------------
-- Actual drinking
--------------------------------------------------------

local TaskClass = hiertask.CreateTaskClass("CHECK_THIRST")

--- Called to run the task.
function TaskClass:Run(parent, usercmd)
    if Thirst > 900 then
        return hiertask.TASK_FINISHED_ALL
    else
        return hiertask.TASK_CONTINUE
    end
end

AutoStranded.Register("CheckThirst", TaskClass)