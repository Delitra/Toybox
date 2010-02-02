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

local useJPEG = CreateClientConVar("pano_jpeg", "0", true, false)
local ssDelay = CreateClientConVar("pano_ss_delay", "0.1", true, false)

local running = false
local startCaptureTime = 0
local captured = false
local baseFilePath = nil
local viewPos = nil
local viewAng = nil
local angles = {}
local anglesCount = 0
local angleIndex = 1
local currentAngle = nil
local paintHooks = {}

local function RemoveHooks()
    local hooks = hook.GetTable().HUDPaint
    for k, f in pairs(hooks) do
        paintHooks[k] = f
        hook.Remove("HUDPaint", k)
    end
end

local function RestoreHooks()
    for k, f in pairs(paintHooks) do
        hook.Add("HUDPaint", k, f)
        paintHooks[k] = nil
    end
end

local function GetBaseFilePath(id, name)
    if name then
        return name .. "/"
    end
    return id .. "/" .. game.GetMap() .. "_" .. os.date("%Y%m%d%H%M%S") .. "/"
end

local function DoPanorama()
    if CurTime() - startCaptureTime > ssDelay:GetFloat() then
        angleIndex = angleIndex + 1
        currentAngle = angles[angleIndex]
        
        if currentAngle then
            startCaptureTime = CurTime()
            captured = false
        else
            running = false
            RestoreHooks()
            hook.Remove("HUDShouldDraw", "SaitoHUD.Panorama")
            hook.Remove("HUDPaint", "SaitoHUD.Panorama")
            hook.Remove("KeyPress", "SaitoHUD.Panorama")
            return
        end
    end
    
    local offsetPos, angle, fov, name = currentAngle[1], currentAngle[2],
        currentAngle[3], currentAngle[4], currentAngle[5]
    
    surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, ScrW(), ScrH())
    
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetFont("ScoreboardText")
    surface.SetTextPos(ScrH() + 5, 0)
    surface.DrawText("Panorama In Progress")
    surface.SetTextPos(ScrH() + 5, 15)
    surface.DrawText("TRIM OFF BLACK")
    surface.SetTextPos(ScrH() + 5, 30)
    surface.DrawText("Face: " .. name)
    surface.SetTextPos(ScrH() + 5, 45)
    surface.DrawText(string.format("%d/%d (%d%%)", angleIndex,
                                   anglesCount, angleIndex / anglesCount * 100))
    surface.SetTextPos(ScrH() + 5, 60)
    surface.DrawText("Loc: " .. baseFilePath)
    
    local data = {}
    data.drawhud = false
    data.drawviewmodel = false
    data.fov = fov
    data.angles = viewAng + angle
    data.origin = viewPos + offsetPos
    data.x = 0
    data.y = 0
    data.w = ScrH()
    data.h = ScrH()
    render.RenderView(data)
    
    if not captured then
        RunConsoleCommand(useJPEG:GetBool() and "jpeg" or "screenshot", baseFilePath .. name)
        captured = true
    end
end

local function KeyPress()
    SaitoHUD.ShowHint("Panorama aborted (you pressed a button).")
    SaitoHUD.StopPanorama()
end

local function PreparePano(id, name)
    running = true
    startCaptureTime = CurTime()
    captured = false
    baseFilePath = GetBaseFilePath(id, name)
    viewPos = LocalPlayer():GetShootPos()
    viewAng = Angle(0, LocalPlayer():EyeAngles().y, 0)
    
    angleIndex = 1
    anglesCount = table.Count(angles)
    currentAngle = angles[angleIndex]
    
    RemoveHooks()
    hook.Add("HUDShouldDraw", "SaitoHUD.Panorama", function(name) return name == "CHudGMod" end)
    hook.Add("HUDPaint", "SaitoHUD.Panorama", DoPanorama)
    hook.Add("KeyPress", "SaitoHUD.Panorama", KeyPress)
    
    Msg("Panorama output folder: " .. baseFilePath .. "\n")
end

function SaitoHUD.StopPanorama()
    if not running then
        Msg("Panorama routine not running")
        return
    end

    running = false
    RestoreHooks()
    hook.Remove("HUDShouldDraw", "SaitoHUD.Panorama")
    hook.Remove("HUDPaint", "SaitoHUD.Panorama")
    hook.Remove("KeyPress", "SaitoHUD.Panorama")
end

function SaitoHUD.CreateCubicPanorama(name)
    if running then
        Msg("Panorama routine already running")
        return true
    end
    
    angles = {
        {Vector(0, 0, 0), Angle(0, 0, 0), 90, "front"},
        {Vector(0, 0, 0), Angle(0, 90, 0), 90, "left"},
        {Vector(0, 0, 0), Angle(0, 180, 0), 90, "back"},
        {Vector(0, 0, 0), Angle(0, 270, 0), 90, "right",},
        {Vector(0, 0, 0), Angle(90, 0, 0), 90, "down"},
        {Vector(0, 0, 0), Angle(-90, 0, 0), 90, "up"},
    }
    
    PreparePano("cubic", name)
    return true
end

function SaitoHUD.CreateRectilinearPanorama(degrees, fov, name)
    if running then
        Msg("Panorama routine already running")
        return false
    end
    
    if not degrees then degrees = 30 end
    if not fov then fov = 90 end
    
    angles = {}
    
    for i = 0, 360 - degrees, degrees do
        table.insert(angles, {Vector(0, 0, 0), Angle(0, i, 0), fov, tostring(i)})
    end
    
    PreparePano("rectilinear", name)
    return true
end

function SaitoHUD.CreateStitchablePanorama(hDegrees, vDegrees, fov, name)
    if running then
        Msg("Panorama routine already running")
        return false
    end
    
    if not hDegrees then hDegrees = 30 end
    if not vDegrees then vDegrees = 30 end
    if not fov then fov = 90 end
    
    angles = {}
    
    for k = -90 + vDegrees, 90 - vDegrees, vDegrees do
        for i = 0, 360 - hDegrees, hDegrees do
            table.insert(angles, {Vector(0, 0, 0), Angle(k, i, 0), fov, tostring(k) .. "," .. tostring(i)})
        end
    end
    
    table.insert(angles, {Vector(0, 0, 0), Angle(-90, 0, 0), 110, "up"})
    table.insert(angles, {Vector(0, 0, 0), Angle(90, 0, 0), 110, "down"})
    
    PreparePano("stitchable", name)
    return true
end

concommand.Add("pano_cubic", function(ply, cmd, args)
    local name = (args[1] and args[1]:Trim() ~= "") and args[1] or nil
    SaitoHUD.CreateCubicPanorama(name)
end)

concommand.Add("pano_rectilinear", function(ply, cmd, args)
    local name = (args[1] and args[1]:Trim() ~= "") and args[1] or nil
    SaitoHUD.CreateRectilinearPanorama(nil, nil, name)
end)

concommand.Add("pano_stitchable", function(ply, cmd, args)
    local name = (args[1] and args[1]:Trim() ~= "") and args[1] or nil
    SaitoHUD.CreateStitchablePanorama(nil, nil, nil, name)
end)