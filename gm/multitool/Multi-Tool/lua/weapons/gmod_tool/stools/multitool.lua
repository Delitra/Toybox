-- Multi-Tool
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

IncludeClientFile("weapons/gmod_tool/stools/multitool/vgui/MultiToolFilterBuilder.lua")

TOOL.Category = "Construction"
TOOL.Name = "Multi-Tool"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["use_radius"] = "0"
TOOL.ClientConVar["use_constrained"] = "0"
TOOL.ClientConVar["use_filter"] = "0"
TOOL.ClientConVar["radius"] = 400
TOOL.ClientConVar["tool"] = "weld"
TOOL.ClientConVar["filter"] = ""

if CLIENT then
    language.Add("Tool_multitool_name", "Multi-Tool")
    language.Add("Tool_multitool_desc", "Uses a tool on many entities at once.")
    language.Add("Tool_multitool_0", "Primary: Select, Primary+SHIFT: De-select, Secondary: Apply, Reload: Clear selection")
    language.Add("Tool_multitool_mode", "Selection Mode")
    language.Add("Tool_multitool_use_radius", "Include Props in Radius")
    language.Add("Tool_multitool_use_constrained", "Include Constrained Props")
    language.Add("Tool_multitool_use_filter", "Apply Filter")
    language.Add("Tool_multitool_radius", "Radius")
    language.Add("Tool_multitool_tool", "Tool")
    language.Add("Undone_Multi-Tool", "Undone Multi-Tool")
end

MULTITOOL_ADD_LEFT = 0
MULTITOOL_ADD_RIGHT = 1

MultiToolTools = {
    weld = { Name = "Weld", Root = MULTITOOL_ADD_LEFT, Each = MULTITOOL_ADD_LEFT, ResetFunc = 'ClearObjects' },
    --balloon = { Name = "Balloon", Each = MULTITOOL_ADD_LEFT },
    rt_buoyancy = { Name = "Bouyancy", Each = MULTITOOL_ADD_LEFT, NoUndo = true },
    entity_surface = { Name = "Entity Surface", Each = MULTITOOL_ADD_LEFT, NoUndo = true },
    unbreakable = { Name = "Unbreakable", Each = MULTITOOL_ADD_LEFT, NoUndo = true },
    weight = { Name = "Weight", Each = MULTITOOL_ADD_LEFT, NoUndo = true },
    rt_antinoclip = { Name = "Anti-NoClip", Each = MULTITOOL_ADD_LEFT, NoUndo = true },
    magnetise = { Name = "Magnetise", Each = MULTITOOL_ADD_LEFT },
    magnetise_magnet = { Tool = "magnetise", Name = "Magnetise (Attach Magnet)", Each = MULTITOOL_ADD_RIGHT, NoUndo = true },
    nocollide = { Name = "No-Collide", Root = MULTITOOL_ADD_LEFT, Each = MULTITOOL_ADD_LEFT, ResetFunc = 'ClearObjects' },
    nocollide_all = { Tool = "nocollide", Name = "No-Collide All (Toggle)", Each = MULTITOOL_ADD_RIGHT, NoUndo = true },
    physprop = { Name = "Physical Properties", Each = MULTITOOL_ADD_LEFT, NoUndo = true, ShowCvar = "physprop_material" },
    remover = { Name = "Remove", Each = MULTITOOL_ADD_LEFT, NoUndo = true },
    colour = { Name = "Colour", Each = MULTITOOL_ADD_LEFT, NoUndo = true },
    material = { Name = "Material", Each = MULTITOOL_ADD_LEFT, NoUndo = true, ShowCvar = "material_override" },
    freeze = { Name = "Freeze", NoUndo = true,
        EachFunc = function(ent)
            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                ent:GetPhysicsObjectNum(i):EnableMotion(false)
            end
        end
    },
    unfreeze = { Name = "Unfreeze", NoUndo = true,
        EachFunc = function(ent)
            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                ent:GetPhysicsObjectNum(i):Wake()
                ent:GetPhysicsObjectNum(i):EnableMotion(true)
            end
        end
    },
    sleep = { Name = "Unfreeze", NoUndo = true,
        EachFunc = function(ent)
            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                ent:GetPhysicsObjectNum(i):Sleep()
                ent:GetPhysicsObjectNum(i):EnableMotion(true)
            end
        end
    },
    wake = { Name = "Wake", NoUndo = true,
        EachFunc = function(ent)
            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                ent:GetPhysicsObjectNum(i):Wake()
                ent:GetPhysicsObjectNum(i):EnableMotion(true)
            end
        end
    },
    deweld = { Name = "Remove Welds", NoUndo = true,
        EachFunc = function(ent)
            constraint.RemoveConstraints(ent, "Weld")
        end
    },
    deconstrain = { Name = "Remove All Constraints", NoUndo = true,
        EachFunc = function(ent)
            constraint.RemoveAll(ent)
        end
    },
}

if SERVER then
    include("multitool/server.lua")
end

if CLIENT then
    local selectedCount = 0
    
    for k, v in pairs(MultiToolTools) do
        language.Add("Tool_multitool_tools_" .. k, v.Name)
    end

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
    
    function TOOL:DrawHUD()
        local toolID = self:GetClientInfo("tool")
        local radius = self:GetClientInfo("radius")
        local useRadius = self:GetClientNumber("use_radius") == 1
        local useFilter = self:GetClientNumber("use_filter") == 1
        local useConstrained = self:GetClientNumber("use_constrained") == 1
        local tool = MultiToolTools[toolID]
        
        if tool then
            local val
            if tool.ShowCvar then
                val = GetConVar(tool.ShowCvar):GetString()
            end
            
            if toolID == "remover" then
                draw.WordBox(4, ScrW() / 2 + 5, ScrH() / 2 + -28, "Multi-Tool: " .. tool.Name, "Default",
                    Color(math.sin(CurTime() * 10) * 50 + 100, 0, 0, 200), Color(255, 255, 255, 255))
            else
                draw.WordBox(4, ScrW() / 2 + 5, ScrH() / 2 + -28,
                    "Multi-Tool: " .. tool.Name .. (val and " (" .. val .. ")" or ""),
                    "Default", Color(100, 0, 100, 200), Color(255, 255, 255, 255))
            end
        end
        
        if useFilter then
            local filter = self:GetClientInfo("filter")
        
            draw.WordBox(4, ScrW() / 2 + 5, ScrH() / 2 + -50,
                "[" .. selectedCount .. "] Filter enabled: " .. (string.len(filter) > 30 and filter:sub(1, 30) .. "..." or filter),
                "Default", Color(255, 255, 255, 100), Color(255, 255, 255, 255))
        else
            draw.WordBox(4, ScrW() / 2 + 5, ScrH() / 2 + -50,
                selectedCount .. " selected",
                "Default", Color(255, 255, 255, 100), Color(0, 0, 0, 255))
        end
        
        if useRadius then
            local tr = LocalPlayer():GetEyeTrace()
            
            if tr.Hit then
                surface.SetDrawColor(255, 0, 255, 255)
                
                local sin = math.sin
                local cos = math.cos
                local firstPt
                local lastPt
                
                for a = 0, 2 * math.pi, math.pi / 10 do
                    local pt = tr.HitPos + Vector(radius * cos(a), radius * sin(a), 0)
                    
                    if lastPt then
                        local a = lastPt:ToScreen()
                        local b = pt:ToScreen()
                        surface.DrawLine(a.x, a.y, b.x, b.y)
                    end
                    
                    if not firstPt then firstPt = pt end
                    lastPt = pt
                end
                
                local a = lastPt:ToScreen()
                local b = firstPt:ToScreen()
                surface.DrawLine(a.x, a.y, b.x, b.y)
            end
        end
    end

    function TOOL.BuildCPanel(panel)        
        panel:AddControl("CheckBox", {
            Label = "#Tool_multitool_use_constrained",
            Command = "multitool_use_constrained",
        })
        
        panel:AddControl("CheckBox", {
            Label = "#Tool_multitool_use_radius",
            Command = "multitool_use_radius",
        })
        
        panel:AddControl("Slider", {
            Label = "#Tool_multitool_radius",
            Command = "multitool_radius",
            min = 1,
            max = 1000,
        })
        
        panel:AddControl("CheckBox", {
            Label = "#Tool_multitool_use_filter",
            Command = "multitool_use_filter",
        })
        
        panel:AddControl("Button", {
            Label = "Open Filter Builder",
            Command = "multitool_filter_builder",
        })
        
        local options = {}
        
        for id, info in pairs(MultiToolTools) do
            options["#Tool_multitool_tools_" .. id] = { multitool_tool = id }
        end
        
        panel:AddControl("ListBox", {
            Label = "#Tool_multitool_tool",
            Height = 200,
            Options = options,
        })
    end
    
    concommand.Add("multitool_filter_builder", function()
        vgui.Create("MultiToolFilterBuilder")
    end)
    
    usermessage.Hook("MultiToolCount", function(um)
        selectedCount = um:ReadShort()
    end)
end
