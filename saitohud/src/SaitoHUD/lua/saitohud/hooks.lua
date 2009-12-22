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

--------------------------------------------------
-- Cvars
--------------------------------------------------

local drawEntityInfo = CreateClientConVar("entity_info", "1", true, false)
local drawNameTags = CreateClientConVar("name_tags", "1", true, false)
local sampleDraw = CreateClientConVar("sample_draw", "1", false, false)
local sampleResolution = CreateClientConVar("sample_resolution", "0.1", true, false)
local sampleSize = CreateClientConVar("sample_size", "100", true, false)
local sampleNodes = CreateClientConVar("sample_nodes", "1", true, false)
local sampleMultiple = CreateClientConVar("sample_multiple", "0", true, false)

SaitoHUD.sampleResolution = sampleResolution:GetFloat()
SaitoHUD.sampleSize = sampleSize:GetFloat()
SaitoHUD.drawSampleNodes = sampleNodes:GetBool()

cvars.AddChangeCallback("sample_resolution", function(cv, old, new)
	SaitoHUD.sampleResolution = sampleResolution:GetFloat()
end)

cvars.AddChangeCallback("sample_size", function(cv, old, new)
	SaitoHUD.sampleSize = sampleSize:GetFloat()
end)

cvars.AddChangeCallback("sample_nodes", function(cv, old, new)
	SaitoHUD.drawSampleNodes = sampleNodes:GetBool()
end)

--------------------------------------------------
-- Hooks
--------------------------------------------------

local lastSample = 0

hook.Add("HUDPaint", "SKHUDInfo", function()
    if drawEntityInfo:GetBool() then
        SaitoHUD.DrawEntityInfo()
    end
    SaitoHUD.DrawOverlays()
    if drawNameTags:GetBool() then
        SaitoHUD.DrawNameTags()
    end
    if CurTime() - lastSample > SaitoHUD.sampleResolution then
        SaitoHUD.LogSamples()
        lastSample = CurTime()
    end
    if sampleDraw:GetBool() then
        SaitoHUD.DrawSamples(true)
    end
end)

--------------------------------------------------
-- Commands
--------------------------------------------------

local lastTriadsFilter = nil

local function ConsoleAutocompletePlayer(cmd, args)
    local testName = args or ""
    if testName:len() > 0 then
        testName = testName:Trim()
    end
    local testNameLength = testName:len()
    local names = {}
    
    for _, ply in pairs(player.GetAll()) do
        local name = ply:GetName()
        if name:len() >= testNameLength and 
           name:sub(1, testNameLength):lower() == testName:lower() then
            if name:find(" ") or name:find("\"") then
                name = "\"" .. name:gsub("\"", "\\\"") .. "\""
            end
            table.insert(names, cmd .. " " .. name)
        end
    end
    
    return names
end

concommand.Add("triads_filter", function(ply, cmd, args)
    SaitoHUD.triadsFilter = SaitoHUD.entityFilter.Build(args, true)
end)

concommand.Add("overlay_filter", function(ply, cmd, args)
    SaitoHUD.overlayFilter = SaitoHUD.entityFilter.Build(args, true)
end)

concommand.Add("bbox_filter", function(ply, cmd, args)
    SaitoHUD.bboxFilter = SaitoHUD.entityFilter.Build(args, true)
end)

concommand.Add("toggle_triads", function(ply, cmd, args)
    if SaitoHUD.triadsFilter then
        lastTriadsFilter = SaitoHUD.triadsFilter
        SaitoHUD.triadsFilter = nil
    else
        if lastTriadsFilter then
            SaitoHUD.triadsFilter = lastTriadsFilter
        else
            SaitoHUD.triadsFilter = SaitoHUD.entityFilter.Build({"*"}, true)
        end
    end
end)

concommand.Add("sample", function(ply, cmd, args)
    if not sampleMultiple:GetBool() then
        if table.Count(SaitoHUD.samplers) > 0 then
            LocalPlayer():ChatPrint("Note: Multiple entity sampling is disabled")
        end
        SaitoHUD.samplers = {}
    end
    
    if table.Count(args) == 0 then
        local tr = SaitoHUD.GetRefTrace()
        
        if ValidEntity(tr.Entity) then
            SaitoHUD.AddSample(tr.Entity)
            LocalPlayer():ChatPrint("Sampling entity #" ..  tr.Entity:EntIndex() .. ".")
        else
            LocalPlayer():ChatPrint("Nothing was found in an eye trace!")
        end
    elseif table.Count(args) == 1 then
        local m = SaitoHUD.MatchPlayerString(args[1])
        if m then
            SaitoHUD.AddSample(m)
            LocalPlayer():ChatPrint("Sampling player named " .. m:GetName() .. ".")
        else
            LocalPlayer():ChatPrint("No player was found by that name.")
        end
    else
        Msg("Invalid number of arguments")
    end
end, ConsoleAutocompletePlayer)

concommand.Add("sample_remove", function(ply, cmd, args)
    if table.Count(args) == 0 then
        local tr = SaitoHUD.GetRefTrace()
        
        if ValidEntity(tr.Entity) then
            SaitoHUD.RemoveSample(tr.Entity)
            LocalPlayer():ChatPrint("No longer sampling entity #" ..  tr.Entity:EntIndex() .. ".")
        else
            LocalPlayer():ChatPrint("Nothing was found in an eye trace!")
        end
    elseif table.Count(args) == 1 then
        local m = SaitoHUD.MatchPlayerString(args[1])
        if m then
            SaitoHUD.RemoveSample(m)
            LocalPlayer():ChatPrint("No longer sampling player named " .. m:GetName() .. ".")
        else
            LocalPlayer():ChatPrint("No player was found by that name.")
        end
    else
        Msg("Invalid number of arguments")
    end
end, ConsoleAutocompletePlayer)

concommand.Add("sample_clear", function(ply, cmd, args)
    if table.Count(SaitoHUD.samplers) == 0 then
        LocalPlayer():ChatPrint("No samplers are active.")
    else
        LocalPlayer():ChatPrint(table.Count(SaitoHUD.samplers) .. " sampler(s) removed.")
        SaitoHUD.samplers = {}
    end
end)

concommand.Add("dump_info", function(ply, cmd, args)
    SaitoHUD.DumpEntityInfo()
end)