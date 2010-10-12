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

AutoStranded = {}
local AutoStranded = AutoStranded
local mt = {}

mt.__index = function(t, name)
    return t.GetClass(name)
end

setmetatable(AutoStranded, mt)

AutoStranded.TaskClasses = {}

function AutoStranded.Register(id, name)
    AutoStranded.TaskClasses[id] = name
end

function AutoStranded.GetClass(id)
    return AutoStranded.TaskClasses[id]
end

