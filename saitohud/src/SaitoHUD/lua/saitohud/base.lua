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

function SaitoHUD.GetRefTrace()
    return util.TraceLine(util.GetPlayerTrace(LocalPlayer()))
end

function SaitoHUD.GetRefPos()
    return LocalPlayer():GetPos()
end

function SaitoHUD.MatchPlayerString(testName)
    local possibleMatch = nil
    testName = testName:lower()
    
    for _, ply in pairs(player.GetAll()) do
        local name = ply:GetName()
        
        if name:lower() == testName:lower() then
            return ply
        else
            if name:lower():find(testName, 1, true) then
                possibleMatch = ply
            end
        end
    end
    
    if possibleMatch then
        return possibleMatch
    else
        return nil
    end
end

function SaitoHUD.GetEntityInfoLines()
    local tr = SaitoHUD.GetRefTrace()
    
    local lines = {}
    
    if ValidEntity(tr.Entity) then
        local r, g, b, a = tr.Entity:GetColor();
        
        lines = {
            "[" .. tostring(tr.HitPos:Distance(LocalPlayer():GetPos())) .. "]",
            "Hit Pos: " .. tostring(tr.HitPos),
            "Class: " .. tostring(tr.Entity:GetClass()),
            "Position: " .. tostring(tr.Entity:GetPos()),
            "Size: " .. tostring(tr.Entity:OBBMaxs()-tr.Entity:OBBMins()),
            "Angle: " .. tostring(tr.Entity:GetAngles()),
            "Color: " .. string.format("%0.2f %.2f %.2f %.2f", r, g, b, a),
            "Model: " .. tostring(tr.Entity:GetModel()),
            "Material: " .. tostring(tr.Entity:GetMaterial()),
            "Velocity: " .. tostring(tr.Entity:GetVelocity()),
            "Local: " .. tostring(tr.Entity:WorldToLocal(tr.HitPos)),
        }
    else
        if tr.Hit then
            lines = {
                "[" .. tostring(tr.HitPos:Distance(LocalPlayer():GetPos())) .. "]",
                "Hit Pos: " .. tostring(tr.HitPos),
            }
        end
    end
    
    return lines
end

function SaitoHUD.DumpEntityInfo()
    local lines = SaitoHUD.GetEntityInfoLines()
    
    if table.Count(lines) > 0 then
        for _, s in pairs(lines) do
            Msg(s .. "\n")
        end
    end
end