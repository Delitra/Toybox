-- PVP Monitor
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

if SERVER then
    AddCSLuaFile("autorun/pvp_monitor.lua")
    
    -- NOTE:
    -- Change this function in order to support different gamemodes
    -- if your gamemode lets players change their name.
    local function GetActualName(ply)
        -- This is for DarkRP support
        if ply.SteamName then
            return ply:SteamName()
        else
            return ply:Nick()
        end
    end
    
    hook.Add("PlayerDeath", "PVPMonitor", function(victim, inflictor, killer)
        -- Detect vehicles
        if inflictor:IsVehicle() and inflictor:GetDriver():IsPlayer() then
            killer = inflictor:GetDriver()
        end
        
        -- Get weapon
        if inflictor:IsPlayer() and ValidEntity(inflictor:GetActiveWeapon()) then
            inflictor = inflictor:GetActiveWeapon()
        end
        
        if not inflictor:IsPlayer() and killer == inflictor and inflictor.CPPIGetOwner then
            local owner = inflictor:CPPIGetOwner()
            if ValidEntity(owner) then
                killer = owner
            end
        end
        
        local hasAdmins = false
        
        local filter = RecipientFilter()
        for k, v in pairs(player.GetAll()) do
            if v:IsAdmin() or v:IsSuperAdmin() then
                filter:AddPlayer(v)
                hasAdmins = true
            end
        end
        
        if not hasAdmins then return end
        
        umsg.Start("PVPMonDeath", filter)
        umsg.Entity(victim)
        umsg.Vector(victim:GetPos())
        umsg.String(GetActualName(victim))
        
        umsg.String(inflictor:GetClass())
        
        umsg.Entity(killer)
        umsg.String(killer:GetClass())
        umsg.Vector(killer:GetPos())
        umsg.String(killer:IsPlayer() and GetActualName(killer) or "")
        umsg.End()
    end)
end

if CLIENT then
    local recentPvPDeaths = {}

    local function GetPlayerInfoText(nick, name, steamID)
        if nick == name then
            return steamID
        else
            return name .. " [" .. steamID .. "]"
        end
    end

    usermessage.Hook("PVPMonDeath", function(um)
        local victim = um:ReadEntity()
        local victimPos = um:ReadVector()
        local victimSteamName = um:ReadString()
        
        local inflictorClass = um:ReadString()
        
        local killer = um:ReadEntity()
        local killerIsPlayer = ValidEntity(killer) and killer:IsPlayer()
        local killerClass = um:ReadString()
        local killerPos = um:ReadVector()
        local killerSteamName = um:ReadString()
        
        if killer == victim then
            chat.AddText(Color(255, 255, 255, 255), "Suicide: ",
                         victim:Nick())
        elseif ValidEntity(killer) and killer:IsPlayer() then
            chat.AddText(Color(255, 0, 0, 255), "PvP: ",
                         Color(0, 255, 255, 255), killer:Nick(),
                         Color(100, 100, 100, 255), " (", GetPlayerInfoText(killer:Nick(), killerSteamName, killer:SteamID()), ")",
                         Color(255, 255, 255, 255), " killed ",
                         Color(0, 255, 255, 255), victim:Nick(),
                         Color(100, 100, 100, 255), " (", GetPlayerInfoText(victim:Nick(), victimSteamName, victim:SteamID()), ")",
                         Color(255, 255, 255, 255), " with ",
                         Color(255, 255, 0, 255), inflictorClass)
            
            table.insert(recentPvPDeaths, { victim:Nick(), victimPos, killer, killer:Nick(), killerPos, inflictorClass, RealTime() })
        else
            chat.AddText(Color(255, 255, 255, 255), "Killed: ",
                         Color(0, 255, 255, 255), victim:Nick(),
                         Color(100, 100, 100, 255), " (", GetPlayerInfoText(victim:Nick(), victimSteamName, victim:SteamID()), ")",
                         Color(255, 255, 255, 255), " killed by ",
                         Color(0, 255, 255, 255), killerClass,
                         Color(255, 255, 255, 255), " with ",
                         Color(255, 255, 0, 255), inflictorClass)
        end
    end)

    hook.Add("HUDPaint", "PVPMonitor", function()
        local i = 1
        while i <= #recentPvPDeaths do
            local vNick, vPos, killer, kNick, kPos, infClass, addedTime = unpack(recentPvPDeaths[i])
            -- The following line is wrong
            local alpha = math.Clamp((40 - (RealTime() - addedTime + 5)) * 255, 0, 255)
            if alpha <= 0 then
                table.remove(recentPvPDeaths, i)
            else
                local vPosS = vPos:ToScreen()
                local font = "UiBold"
                if vPosS.visible then
                    surface.SetDrawColor(255, 0, 0, alpha)
                    surface.DrawOutlinedRect(vPosS.x + 1 - 5, vPosS.y + 1 - 5, 10, 10)
                    surface.SetDrawColor(255, 255, 0, alpha)
                    surface.DrawOutlinedRect(vPosS.x - 5, vPosS.y - 5, 10, 10)
                    draw.SimpleText(vNick, font, vPosS.x, vPosS.y + 7,
                        Color(255, 0, 0, alpha),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                local kPosS = kPos:ToScreen()
                if kPosS.visible then
                    surface.SetDrawColor(255, 0, 255, alpha)
                    surface.DrawOutlinedRect(kPosS.x + 1 - 2, kPosS.y + 1 - 2, 5, 5)
                    draw.SimpleText(kNick, font, kPosS.x, kPosS.y - 7,
                        Color(255, 0, 255, alpha),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                if vPosS.visible and kPosS.visible then
                    surface.SetDrawColor(255, 0, 255, alpha)
                    surface.DrawLine(vPosS.x, vPosS.y, kPosS.x, kPosS.y)
                end
                if ValidEntity(killer) and killer ~= LocalPlayer() then
                    local p = killer:GetShootPos():ToScreen()
                    surface.SetDrawColor(255, 255, 255, alpha)
                    surface.DrawOutlinedRect(p.x - 5, p.y - 10, 10, 20)
                end
                i = i + 1
            end
        end
    end)
end