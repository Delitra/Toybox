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

local TaskClass = hiertask.CreateTaskClass("SAY_TEXT")

--- Called to initialize the task.
function TaskClass:Initialize(text)
    self.Text = text
end

--- Called to run the task.
function TaskClass:Run(parent, usercmd)
    RunConsoleCommand("say", self.Text)
    
    return hiertask.TASK_FINISHED
end

AutoStranded.Register("SayText", TaskClass)