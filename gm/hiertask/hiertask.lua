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

local setmetatable = setmetatable
local pairs = pairs
local table = table
local unpack = unpack
local print = print
local PrintTable = PrintTable
local Error = Error
local string = string
local tostring = tostring
local draw = draw
local Color = Color

module("hiertask")

TASK_FINISHED = 1
TASK_CONTINUE = 2
TASK_BREAK = 3
TASK_FINISHED_PREV = 4
TASK_FINISHED_ALL = 5

local function mkclass(base)
    local t = {}
    local mt = {}
    
    mt.__call = function(self, ...)
        local arg = {...}
        local inst = {}
        setmetatable(inst, {__index = t})
        if inst._Initialize then inst:_Initialize() end
        if inst.Initialize then inst:Initialize(unpack(arg)) end
        return inst
    end
    
    if base then mt.__index = base end
    
    setmetatable(t, mt)
    return t
end

BaseTask = mkclass()

function BaseTask:_Initialize()
    self.Tasks = {}
end

function BaseTask:GetName()
    return "undefined"
end

function BaseTask:Run(parent, ...)
    local arg = {...}
    return self:RunStack(unpack(arg))
end

function BaseTask:RunStack(...)
    local arg = {...}
    
    if #self.Tasks > 0 then
        local i = 1
        
        while i <= #self.Tasks do
            local item = self.Tasks[i]
            local concurrent = item.Concurrent
            local result = item.Task:Run(self, unpack(arg))
            
            item.Task._LastResult = result
            
            if result == TASK_FINISHED then -- Did the task finish?
                table.remove(self.Tasks, i)
            elseif result == TASK_FINISHED_PREV then -- Did the task finish?
                for _ = 1, i do
                    table.remove(self.Tasks, 1)
                end
                
                i = 1
                break
            elseif result == TASK_FINISHED_ALL then -- Did the task finish?
                self.Tasks = {}
                break
            elseif result == TASK_BREAK then -- Did the task want to be the last?
                break
            elseif result == TASK_CONTINUE then -- Did the task finish?
                i = i + 1
            else
                Error("Task result returned unknown status")
            end
            
            if not concurrent then
                break
            end            
        end
        
        return TASK_CONTINUE
    else
        return TASK_FINISHED -- No tasks left
    end
end

function BaseTask:Abandon()
    return true
end

function BaseTask:Add(task, priority, concurrent)
    local priority = priority or 0
    local concurrent = concurrent or false
    
    for k, t in pairs(self.Tasks) do
        if priority > t.Priority then
            table.insert(self.Tasks, k, {
                Task = task,
                Priority = priority,
                Concurrent = concurrent
            })
            return
        end
    end
    
    table.insert(self.Tasks, {
        Task = task,
        Priority = priority,
        Concurrent = concurrent
    })
end

function BaseTask:_DrawHUDTree(x, y, continue)
    local yOffset = y
    
    for i = 1, #self.Tasks do
        local item = self.Tasks[i]
        local priority = item.Priority
        local concurrent = item.Concurrent
        
        local font = "DefaultSmallDropShadow"
        local color = item.Concurrent and 
            Color(200, 200, 200, 255) or Color(255, 255, 255, 255)
        local text = string.format("- %s [%d]" , item.Task:GetName(), priority)
        
        if continue then
            font = "TabLarge"
        end
        
        draw.SimpleText(text, font, x, yOffset, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        yOffset = yOffset + 13
        yOffset = yOffset + 13 * item.Task:_DrawHUDTree(x + 10, yOffset, continue)
        
        continue = continue and item.Task._LastResult == TASK_CONTINUE and concurrent
    end
    
    return #self.Tasks
end

function BaseTask:DrawHUDTree(x, y)
    self:_DrawHUDTree(x, y, true)
end

function CreateTaskClass(name)
    local Task = mkclass(BaseTask)
    Task.GetName = function()
        return name
    end
    return Task
end

function CreateStack()
    local task = CreateTaskClass("stack")
    return task()
end