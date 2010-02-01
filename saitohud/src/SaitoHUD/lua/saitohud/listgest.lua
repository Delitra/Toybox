-- SaitoHUD
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
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

SaitoHUD.Gesturing = false
SaitoHUD.RegisteredListGests = {}

local entries = {}
local lastIndex = 0

function StartGesture(ply, cmd, args)
	SaitoHUD.Gesturing = true
    entries = GetEntriesList()
    lastIndex = 0
	gui.EnableScreenClicker(true)
end
concommand.Add("+listgest", StartGesture)

function EndGesture(ply, cmd, args)
	SaitoHUD.Gesturing = false
	gui.EnableScreenClicker(false)
    surface.PlaySound("ui/buttonclickrelease.wav")
    
    if entries[lastIndex] then
        if type(entries[lastIndex][2]) == "function" then
            entries[lastIndex][2](entries[lastIndex][1])
        elseif type(entries[lastIndex][2]) == "string" then
            LocalPlayer():ConCommand(entries[lastIndex][2] .. "\n")
        end
    end
end
concommand.Add("-listgest", EndGesture)

function GetEntriesList()
    local entries = {}
    for _, f in pairs(SaitoHUD.RegisteredListGests) do
        table.Merge(entries, f())
    end
    table.insert(entries, 1, {"Cancel", nil})
    return entries
end

function SaitoHUD.RegisterListGest(f)
    table.insert(SaitoHUD.RegisteredListGests, f)
end

function HUDPaint()
	if not SaitoHUD.Gesturing then return end
    
    local offsetX, offsetY = ScrW() - 210, ScrH() * 0.1
    local mX, mY = gui.MousePos()
    local scX, scY = ScrW() / 2, ScrH() / 2
    local mDistance = math.max(math.abs(scY - mY) - 5, 0)
    local index = 1
    if mY > scY then
        index = math.min(math.floor(mDistance / 15) + 1, table.Count(entries))
    else
        index = table.Count(entries) - math.min(math.floor(mDistance / 15), table.Count(entries) - 1)
    end
    if index ~= lastIndex then
        surface.PlaySound("weapons/pistol/pistol_empty.wav")
    end
    lastIndex = index
    
    for i, entry in pairs(entries) do
        local text = entry[1]
        local bgColor = entry[3] and entry[3] or Color(0, 0, 0, 255)
        local x, y = offsetX, offsetY + i * 30
        
        surface.SetFont("HudHintTextLarge")
        local w, h = surface.GetTextSize(text)
        draw.RoundedBox(4, x - 3, y - h/2,
                        200 + 3, h + 12,
                        index == i and Color(255, 50, 50, 255) or bgColor)
        surface.SetTextColor(255, 255, 255, 200)
        surface.SetTextPos(x, y)
        surface.DrawText(text)
    end
end
hook.Add("HUDPaint", "SaitoHUDListGestHUDPaint", HUDPaint)