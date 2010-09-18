-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

TOOL.Category = "Tools"
TOOL.Name = "Hands-Off"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("Tool_hands_off_name", "Hands-Off")
    language.Add("Tool_hands_off_desc", "Marks entities as no-touch.")
    language.Add("Tool_hands_off_0", "Primary: Mark hands-off, Secondary: Unmark, Reload: Unmark all")
    language.Add("Undone_Hands-Off", "Undone Hands-Off")
end

if SERVER then
    function TOOL:RightClick(tr)
        if not ValidEntity(tr.Entity) then return end
        
        tr.Entity:SetNetworkedBool("ho", false)
        tr.Entity.HandsOffBy = nil
        
        return true
    end
    
    function TOOL:LeftClick(tr)
        if not ValidEntity(tr.Entity) then return end
        
        tr.Entity:SetNetworkedBool("ho", true)
        tr.Entity.HandsOffBy = self:GetOwner()
        
        return true
    end
    
    function TOOL:Reload(tr)
        for _, ent in pairs(ents.GetAll()) do
            if ent:GetNetworkedBool("ho") and ent.HandsOffBy == self:GetOwner() then
                ent:SetNetworkedBool("ho", false)
                ent.HandsOffBy = nil
            end
        end
        
        return true
    end
    
    hook.Add("PhysgunPickup", "HandsOff", function(ply, ent)
        if ent:GetNetworkedBool("ho") then
            return false
        end
    end)
    
    hook.Add("GravGunPunt", "HandsOff", function(ply, ent)
        if ent:GetNetworkedBool("ho") then
            return false
        end
    end)
    
    hook.Add("GravGunPickupAllowed", "HandsOff", function(ply, ent)
        if ent:GetNetworkedBool("ho") then
            return false
        end
    end)
    
    hook.Add("CanTool", "HandsOff", function(ply, tr, toolMode)
        if toolMode ~= "hands_off" and ValidEntity(tr.Entity) and 
            tr.Entity:GetNetworkedBool("ho") then
            return false
        end
    end)
    
    hook.Add("EntityTakeDamage", "HandsOff", function(ent)
        if ent:GetNetworkedBool("ho") then
            return false
        end
    end)
    
    hook.Add("OnPhysgunReload", "HandsOff", function(wep, ply)
        local ent = ply:GetEyeTrace().Entity
        
        if ent:GetNetworkedBool("ho") then
            return false
        end
    end)
end

if CLIENT then
    function TOOL:LeftClick(tr)
        if not ValidEntity(tr.Entity) then return false end
        return true
    end

    function TOOL:RightClick(tr)
        if not ValidEntity(tr.Entity) then return false end
        return true
    end

    function TOOL:Reload(tr)
        return true
    end

    local function DrawHUD()
        local ent = LocalPlayer():GetEyeTrace().Entity
        if not ValidEntity(ent) then return end
        if not ent:GetNWBool("ho") then return end
        draw.SimpleText("X", "ScoreboardText", ScrW() / 2, ScrH() / 2,
            Color(255, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.WordBox(4, ScrW() / 2 + 5, ScrH() / 2 + 5, "Can't select (Hands-Off tool)", "Default",
            Color(200, 0, 0, 200), Color(255, 255, 255, 255))
    end

    hook.Add("HUDPaint", "HandsOff", DrawHUD)
    
    hook.Add("GravGunPunt", "HandsOff", function(ply, ent)
        if ent:GetNetworkedBool("ho") then
            return false
        end
    end)
end
