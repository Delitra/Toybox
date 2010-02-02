-- SaitoHUD
-- Copyright (c) 2009 sk89q <http://www.sk89q.com>
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

local startCaptureTime = 0
local captured = false
local angles = {}
local angleIndex = 1
local currentAngle = nil

local function DoPanorama()
    if CurTime() - startCaptureTime > 0.1 then
        angleIndex = angleIndex + 1
        currentAngle = angles[angleIndex]
        
        if currentAngle then
            startCaptureTime = CurTime()
            captured = false
        else
            hook.Remove("HUDShouldDraw", "SaitoHUD.Panorama")
            hook.Remove("HUDPaint", "SaitoHUD.Panorama")
            return
        end
    end
    
    local offsetPos, angle, fov, name = currentAngle[1], currentAngle[2],
        currentAngle[3], currentAngle[4], currentAngle[5]
    
	local data = {}
    data.drawhud = false
    data.drawviewmodel = false
    data.fov = fov
    data.viewmodelfov = fov
	data.angles = angle
	data.origin = LocalPlayer():GetShootPos() + offsetPos
	data.x = 0
	data.y = 0
	data.w = ScrW()
	data.h = ScrH()
	render.RenderView(data)
    
    if not captured then
        RunConsoleCommand("jpeg", name)
        captured = true
    end
end

function SaitoHUD.CreateCubicPanorama()
    startCaptureTime = CurTime()
    captured = false
    
    angles = {
        {Vector(0, 0, 0), Angle(0, 0, 0), 90, "front"},
        {Vector(0, 0, 0), Angle(0, 90, 0), 90, "left"},
        {Vector(0, 0, 0), Angle(0, 180, 0), 90, "back"},
        {Vector(0, 0, 0), Angle(0, 270, 0), 90, "right",},
        {Vector(0, 0, 0), Angle(90, 0, 0), 90, "down"},
        {Vector(0, 0, 0), Angle(-90, 0, 0), 90, "up"},
    }
    angleIndex = 1
    currentAngle = angles[angleIndex]
    
    hook.Add("HUDShouldDraw", "SaitoHUD.Panorama", function(name) return name == "CHudGMod" end)
    hook.Add("HUDPaint", "SaitoHUD.Panorama", DoPanorama)
end