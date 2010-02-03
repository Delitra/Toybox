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

require("image")

local useJPEG = CreateClientConVar("pano_jpeg", "0", true, false)
local prerender = CreateClientConVar("pano_prerender", "0", true, false)
local ssDelay = CreateClientConVar("pano_ss_delay", "0.1", true, false)
local useImage = CreateClientConVar("pano_gm_image", "1", true, false)

local numRTScreens = 0

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
local inPanoView = false
local panoViewAngles = {}
local paintHooks = {}
local lastWeapon = nil

-- We use render targets for prendering
local rtMat = Material("__pano__")
local rtTexture = surface.GetTextureID("__pano__")
local rtScreens = {}
for i = 1, numRTScreens do
    rtScreens[i] = GetRenderTarget("pano_" .. tostring(i), 2048, 2048, false)
end

local function RemoveHooks()
    worldPanelWasVisible = vgui.GetWorldPanel():IsVisible()
    vgui.GetWorldPanel():SetVisible(false)
    local hooks = hook.GetTable().HUDPaint
    for k, f in pairs(hooks) do
        paintHooks[k] = f
        hook.Remove("HUDPaint", k)
        hook.Add("HUDPaint", k, function() end)
    end
end

local function RestoreHooks()
    vgui.GetWorldPanel():SetVisible(worldPanelWasVisible)
    for k, f in pairs(paintHooks) do
        if hook.GetTable().HUDPaint[k] then
            hook.Remove("HUDPaint", k)
            hook.Add("HUDPaint", k, f)
            paintHooks[k] = nil
        else
            Msg("HUDPaint hook disappeared: " .. k .. "\n")
        end
    end
end

local function SwitchAwayFromGrav()
    if LocalPlayer():GetActiveWeapon() then
        lastWeapon = LocalPlayer():GetActiveWeapon():GetClass()
        
        if LocalPlayer():GetActiveWeapon():GetClass() == "weapon_physgun" then
            local weapons = LocalPlayer():GetWeapons()
            if table.Count(weapons) > 1 then
                local weaponClasses = {}
                for _, v in pairs(weapons) do
                    table.insert(weaponClasses, v:GetClass())
                end
                if table.HasValue(weaponClasses, "weapon_crowbar") then
                    RunConsoleCommand("use", "weapon_crowbar")
                elseif table.HasValue(weaponClasses, "gmod_camera") then
                    RunConsoleCommand("use", "gmod_camera")
                elseif table.HasValue(weaponClasses, "gmod_tool") then
                    RunConsoleCommand("use", "gmod_tool")
                elseif table.HasValue(weaponClasses, "weapon_physcannon") then
                    RunConsoleCommand("use", "weapon_physcannon")
                else
                    RunConsoleCommand("use", weaponClasses[1])
                end
            end
        end
    else
        lastWeapon = nil
    end
end

local function RestoreWeapon()
    if lastWeapon then
        RunConsoleCommand("use", lastWeapon)
    end
end

local function GetBaseFilePath(id, name)
    if name then
        return name .. "/"
    end
    return id .. "/" .. game.GetMap() .. "_" .. os.date("%Y%m%d%H%M%S") .. "/"
end

local function KeyPress()
    SaitoHUD.ShowHint("Panorama aborted (you pressed a button).")
    SaitoHUD.StopPanorama()
end

local function EndPanorama()
    running = false
    RestoreHooks()
    RestoreWeapon()
    hook.Remove("HUDShouldDraw", "SaitoHUD.Panorama")
    hook.Remove("HUDPaint", "SaitoHUD.Panorama")
    hook.Remove("KeyPress", "SaitoHUD.Panorama")
end

local function DoPanorama()
    if CurTime() - startCaptureTime > ssDelay:GetFloat() then
        angleIndex = angleIndex + 1
        currentAngle = angles[angleIndex]
        
        if currentAngle then
            startCaptureTime = CurTime()
            captured = false
        else
            EndPanorama()
            return
        end
    end
    
    local offsetPos, angle, fov, name, rt = currentAngle[1], currentAngle[2],
        currentAngle[3], currentAngle[4], currentAngle[5], currentAngle[6]
    
    surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, ScrW(), ScrH())
    
    if rt then
        local old = rtMat:GetMaterialTexture("$basetexture")
        rtMat:SetMaterialTexture("$basetexture", rt)
        surface.SetTexture(rtTexture)
        surface.DrawPoly({
            {x = 0, y = 0, u = 0, v = 0},
            {x = 2048, y = 0, u = 1, v = 0},
            {x = 2048, y = 2048, u = 1, v = 1},
            {x = 0, y = 2048, u = 0, v = 1}
        })
        rtMat:SetMaterialTexture("$basetexture", old)
    else
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
    end
    
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetFont("ScoreboardText")
    surface.SetTextPos(ScrH() + 5, 0)
    surface.DrawText("Panorama in Progress")
    surface.SetTextPos(ScrH() + 5, 15)
    surface.DrawText("TRIM OFF BLACK")
    surface.SetTextPos(ScrH() + 5, 30)
    surface.DrawText("Face: " .. name)
    surface.SetTextPos(ScrH() + 5, 45)
    surface.DrawText(string.format("%d/%d (%d%%)", angleIndex,
                                   anglesCount, angleIndex / anglesCount * 100))
    surface.SetTextPos(ScrH() + 5, 60)
    surface.DrawText("Loc: " .. baseFilePath)
    
    if not captured then
        RunConsoleCommand(useJPEG:GetBool() and "jpeg" or "screenshot", baseFilePath .. name)
        captured = true
        
        Msg(string.format("Captured %s -> %s\n", name,
                          "garrysmod/screenshots/" .. baseFilePath .. name))
    end
end

local function DoImmediatePanorama()
    Msg("Rendering all panorama views to image files immediately...\n")
    
    for i, current in pairs(angles) do
        local offsetPos, angle, fov, name = current[1], current[2],
            current[3], current[4], current[5]
        
        render.Clear(0, 0, 0, 255, true)
        
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
        
        local im = image.CreateImage(ScrH(), ScrH())
        im:CopyRT(0, 0, ScrH(), ScrH())
        im:Save("garrysmod/screenshots/" .. baseFilePath .. name .. ".bmp")
        
        Msg(string.format("Rendered %s -> %s\n", name,
                          "garrysmod/screenshots/" .. baseFilePath .. name))
    end
    
    EndPanorama()
end

local function StartPanorama(id, name)
    running = true
    startCaptureTime = CurTime()
    captured = false
    baseFilePath = GetBaseFilePath(id, name)
    viewPos = LocalPlayer():GetShootPos()
    viewAng = Angle(0, LocalPlayer():EyeAngles().y, 0)
    
    angleIndex = 1
    currentAngle = angles[angleIndex]
    anglesCount = table.Count(angles)
    
    Msg(string.format("%d panorama views to render\n", anglesCount))
    Msg("Panorama output folder: " .. baseFilePath .. "\n")
    
    if useImage:GetBool() and image then
        SwitchAwayFromGrav()
        RemoveHooks()
        hook.Add("HUDShouldDraw", "SaitoHUD.Panorama", function(name) return name == "CHudGMod" end)
        
        -- We need to create the folder
        RunConsoleCommand(useJPEG:GetBool() and "jpeg" or "screenshot", baseFilePath .. "screen")
        
        timer.Simple(ssDelay:GetFloat(), DoImmediatePanorama)
    else
        if anglesCount <= numRTScreens and prerender:GetBool() then
            -- We can render all of them to render targets instantly
            Msg("Rendering all panorama views simultaneously...\n")
            chat.AddText(Color(255, 255, 0, 255), "Pre-rendering panorama views. Your game may freeze momentarily.")
            
            for i, current in pairs(angles) do
                local offsetPos, angle, fov, name = current[1], current[2],
                    current[3], current[4], current[5]
                
                
                local oldRT = render.GetRenderTarget()
                render.SetRenderTarget(rtScreens[i])
                render.Clear(0, 0, 0, 255, true)
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
                render.SetRenderTarget(oldRT)
                
                table.insert(current, rtScreens[i])
                
                Msg(string.format("Pre-rendered %s -> %d\n", name, i))
            end
        else
            Msg("Not pre-renderingg panaroma views\n")
        end
        
        SwitchAwayFromGrav()
        RemoveHooks()
        hook.Add("HUDShouldDraw", "SaitoHUD.Panorama", function(name) return name == "CHudGMod" end)
        hook.Add("HUDPaint", "SaitoHUD.Panorama", DoPanorama)
        hook.Add("KeyPress", "SaitoHUD.Panorama", KeyPress)
    end
end

local function DoPanoramaView()
    local width = ScrW()
    local height = ScrH()
    local extendWidth = false
    
    if width/height > 3/2 then
       width = height * 3/2
       extendWidth = true
    else
       height = width * 2/3
    end
    
    local windowWidth = math.floor(width / 3)
    local windowHeight = windowWidth
    
    surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, ScrW(), ScrH())
    
    for i, angle in pairs(panoViewAngles) do
        local data = {}
        data.drawhud = false
        data.drawviewmodel = false
        data.fov = 90
        data.angles = Angle(0, LocalPlayer():EyeAngles().y, 0) + angle
        data.origin = LocalPlayer():GetShootPos()
        data.x = (i - 1) % 3 * windowWidth
        data.y = math.floor((i - 1) / 3) * windowHeight
        data.w = windowWidth
        data.h = windowHeight
        render.RenderView(data)
    end
    
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetFont("ScoreboardText")
    if extendWidth then
        surface.SetTextPos(windowWidth * 3 + 5, 5)
        surface.DrawText("Panorama View in Progress")
        surface.SetTextPos(windowWidth * 3 + 5, 20)
        surface.DrawText("pano_stop in console to end")
    else
        surface.SetTextPos(5, windowHeight * 2 + 5)
        surface.DrawText("Panorama View in Progress")
        surface.SetTextPos(5, windowHeight * 2 + 5 + 15)
        surface.DrawText("pano_stop in console to end")
    end
end

local function StartPanoramaView(angles)
    panoViewAngles = angles
    
    inPanoView = true
    
    SwitchAwayFromGrav()
    RemoveHooks()
    hook.Add("HUDShouldDraw", "SaitoHUD.Panorama", function(name) return name == "CHudGMod" end)
    hook.Add("HUDPaint", "SaitoHUD.Panorama", DoPanoramaView)
end

local function EndPanoramaView()
    inPanoView = false
    RestoreHooks()
    RestoreWeapon()
    hook.Remove("HUDShouldDraw", "SaitoHUD.Panorama")
    hook.Remove("HUDPaint", "SaitoHUD.Panorama")
end

function SaitoHUD.StopPanorama()
    if running then
        EndPanorama()
    elseif inPanoView then
        EndPanoramaView()
    else
        Msg("Panorama routine not running\n")
    end
end

function SaitoHUD.ShowCubicPanoramaView()
    if running or inPanoView then
        Msg("Panorama routine already running\n")
        return false
    end
    
    StartPanoramaView({
        Angle(0, 0, 0), Angle(0, 270, 0), Angle(0, 180, 0), 
        Angle(0, 90, 0), Angle(-90, 0, 0), Angle(90, 0, 0),
    })
    
    return true
end

function SaitoHUD.ShowAltCubicPanoramaView()
    if running or inPanoView then
        Msg("Panorama routine already running\n")
        return false
    end
    
    StartPanoramaView({
        Angle(0, 90, 0), Angle(0, 0, 0), Angle(0, 270, 0),
        Angle(0, 180, 0), Angle(-90, 0, 0), Angle(90, 0, 0),
    })
    
    return true
end

function SaitoHUD.CreateCubicPanorama(name)
    if running or inPanoView then
        Msg("Panorama routine already running\n")
        return false
    end
    
    angles = {
        {Vector(0, 0, 0), Angle(0, 0, 0), 90, "front"},
        {Vector(0, 0, 0), Angle(0, 90, 0), 90, "left"},
        {Vector(0, 0, 0), Angle(0, 180, 0), 90, "back"},
        {Vector(0, 0, 0), Angle(0, 270, 0), 90, "right",},
        {Vector(0, 0, 0), Angle(90, 0, 0), 90, "down"},
        {Vector(0, 0, 0), Angle(-90, 0, 0), 90, "up"},
    }
    
    StartPanorama("cubic", name)
    return true
end

function SaitoHUD.CreateRectilinearPanorama(degrees, fov, name)
    if running or inPanoView then
        Msg("Panorama routine already running\n")
        return false
    end
    
    if not degrees then degrees = 30 end
    if not fov then fov = 90 end
    
    angles = {}
    
    for i = 0, 360 - degrees, degrees do
        table.insert(angles, {Vector(0, 0, 0), Angle(0, i, 0), fov, tostring(i)})
    end
    
    StartPanorama("rectilinear", name)
    return true
end

function SaitoHUD.CreateStitchablePanorama(hDegrees, vDegrees, fov, name)
    if running or inPanoView then
        Msg("Panorama routine already running\n")
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
    
    StartPanorama("stitchable", name)
    return true
end

concommand.Add("pano_cubic_view", function(ply, cmd, args)
    if not inPanoView then 
        SaitoHUD.ShowCubicPanoramaView()
    else
        EndPanoramaView()
    end
end)

concommand.Add("pano_alt_cubic_view", function(ply, cmd, args)
    if not inPanoView then 
        SaitoHUD.ShowAltCubicPanoramaView()
    else
        EndPanoramaView()
    end
end)

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

concommand.Add("pano_stop", function(ply, cmd, args)
    SaitoHUD.StopPanorama()
end)