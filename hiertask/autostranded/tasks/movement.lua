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

local jumpCmd = false
local useCmd = false

--------------------------------------------------------
-- Smart movement
--------------------------------------------------------

local TaskClass = hiertask.CreateTaskClass("MOVE_SMART")

--- Called to initialize the task.
function TaskClass:Initialize(targetPos, doFinish)
    self.TargetPos = targetPos
    self.DoFinish = doFinish
end

--- Called to run the task.
function TaskClass:Run(parent, usercmd)
    local ply = LocalPlayer()
    local shootPos = ply:GetShootPos()
    local pos = ply:GetPos()
    
    local smallestDist = math.min(shootPos:Distance(self.TargetPos),
                                  pos:Distance(self.TargetPos))
    
    if smallestDist < 20 then
        return self.DoFinish and hiertask.TASK_FINISHED or hiertask.TASK_CONTINUE
    else
        local ang = (self.TargetPos - ply:GetShootPos()):Angle()
        
        -- Don't want to drown
        if ply:WaterLevel() > 0 then
            ang.p = -10
        end
        
        usercmd:SetViewAngles(ang)
        usercmd:SetForwardMove(math.Clamp(smallestDist * 2, 10, 1000))
        
        return hiertask.TASK_BREAK
    end
end

AutoStranded.Register("Move", TaskClass)

--------------------------------------------------------
-- Look down in the water without drowning
--------------------------------------------------------

local TaskClass = hiertask.CreateTaskClass("LOOK_DOWN_WATER")

--- Called to run the task.
function TaskClass:Run(parent, usercmd)
    local ang = usercmd:GetViewAngles()
    ang.p = 60
    usercmd:SetViewAngles(ang)
    
    -- Need to not drown
    if jumpCmd then usercmd:SetButtons(usercmd:GetButtons() | IN_JUMP) end
    jumpCmd = not jumpCmd
    
    return hiertask.TASK_CONTINUE
end

AutoStranded.Register("DownWaterLook", TaskClass)

--------------------------------------------------------
-- Look down in the water without drowning
--------------------------------------------------------

local TaskClass = hiertask.CreateTaskClass("LOOK_DOWN_WATER")

--- Called to run the task.
function TaskClass:Run(parent, usercmd)
    local ang = usercmd:GetViewAngles()
    ang.p = 60
    usercmd:SetViewAngles(ang)
    
    -- Need to not drown
    if jumpCmd then usercmd:SetButtons(usercmd:GetButtons() | IN_JUMP) end
    jumpCmd = not jumpCmd
    
    return hiertask.TASK_CONTINUE
end

AutoStranded.Register("DownWaterLook", TaskClass)

local TaskClass = hiertask.CreateTaskClass("DRINK_ACTION")

--------------------------------------------------------
-- Use
--------------------------------------------------------

local TaskClass = hiertask.CreateTaskClass("USE")

--- Called to run the task.
function TaskClass:Run(parent, usercmd)
    local ply = LocalPlayer()
    
    -- Need to use
    if useCmd then usercmd:SetButtons(usercmd:GetButtons() | IN_USE) else usercmd:SetButtons(0) end
    useCmd = not useCmd
    
    return hiertask.TASK_CONTINUE
end

AutoStranded.Register("Use", TaskClass)