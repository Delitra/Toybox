-- Copyright (c) 2010 sk89q <http://www.sk89q.com>
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

TOOL.Category = "Wire - Tools"
TOOL.Name = "E2 Hologram Designer"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.Tab = "Wire"

TOOL.ClientConVar["move_amt"] = "10"
TOOL.ClientConVar["rotate_amt"] = "45"
TOOL.ClientConVar["scale_amt"] = "1"

local modelList = {
    "cone",
    "cube",
    "dome",
    "dome2",
    "cylinder",
    "hqcone",
    "hqcylinder",
    "hqcylinder2",
    "hqicosphere",
    "hqicosphere2",
    "hqsphere",
    "hqsphere2",
    "hqtorus",
    "hqtorus2",
    "icosphere",
    "icosphere2",
    "icosphere3",
    "prism",
    "pyramid",
    "plane",
    "sphere",
    "sphere2",
    "sphere3",
    "tetra",
    "torus",
    "torus2",
    "torus3"
}

if CLIENT then
    language.Add("Tool_wire_holo_designer_name", "Hologram Designer")
    language.Add("Tool_wire_holo_designer_desc", "Helps position and design holograms.")
    language.Add("Tool_wire_holo_designer_0", "Primary: Click on an E2 to start editing its holograms, Wheel: Adjust value, Secondary: Select hologram (center), Reload: Clear selection")
    language.Add("Tool_wire_holo_designer_holograms", "Holograms")
end

if SERVER then
    include("wire_holo_designer/server.lua")
end

if CLIENT then
    function TOOL:LeftClick(tr)
        if not ValidEntity(tr.Entity) or tr.Entity:GetClass() ~= "gmod_wire_expression2" then
            return false
        end
        return true
    end

    function TOOL:RightClick(tr)
        return false
    end

    function TOOL:Reload(tr)
        return false
    end
    
    local selHoloIndex = nil
    local selEntIndex = nil
    local listBox = nil
    local mode = { "move", "x" }
    
    function TOOL.BuildCPanel(panel)
        local actions = {
            { "Move", { "X", "Y", "Z" } },
            { "Rotate", { "P", "Y", "R" } },
            { "Scale", { "X", "Y", "Z", "Linked" } },
        }
        local modeBtns = {}
        
        local function DeselectModeBtns()
            for _, v in pairs(modeBtns) do
                v:SetSelected(false)
            end
        end
        
        listBox = panel:AddControl("DListView", {})
        listBox:SetTall(200)
        listBox:AddColumn("Idx"):SetFixedWidth(30)
        listBox:AddColumn("Model")
        listBox.OnRowSelected = function(panel, index)
            local line = panel:GetLine(index)
            selHoloIndex = line.HoloIndex
            selEntIndex = line.EntIndex
        end
        listBox.OnRowRightClick = function(lst, index, line)
            local menu = DermaMenu()
            menu:AddOption("Copy Position", function()
                if ValidEntity(line.HoloEntity) then
                    local pos = line.HoloEntity:GetPos()
                    SetClipboardText(Format("%g, %g, %g", pos.x, pos.y, pos.z))
                end
            end)
            menu:AddOption("Copy Angles", function()
                if ValidEntity(line.HoloEntity) then
                    local ang = line.HoloEntity:GetAngles()
                    SetClipboardText(Format("%g, %g, %g", ang.p, ang.y, ang.r))
                end
            end)
            menu:AddOption("Copy Material", function()
                if ValidEntity(line.HoloEntity) then
                    SetClipboardText(line.HoloEntity:GetMaterial())
                end
            end)
            menu:AddOption("Copy Skin", function()
                if ValidEntity(line.HoloEntity) then
                    SetClipboardText(line.HoloEntity:GetSkin())
                end
            end)
            menu:AddOption("Copy Color", function()
                if ValidEntity(line.HoloEntity) then
                    local r, g, b = line.HoloEntity:GetColor()
                    SetClipboardText(Format("%g, %g, %g", r, g, b))
                end
            end)
            menu:AddOption("Copy Alpha", function()
                if ValidEntity(line.HoloEntity) then
                    local r, g, b, a = line.HoloEntity:GetColor()
                    SetClipboardText(a)
                end
            end)
            
            menu:AddOption("Set Position...", function()
                local default = ""
                if ValidEntity(line.HoloEntity) then
                    local pos = line.HoloEntity:GetPos()
                    default = Format("%g, %g, %g", pos.x, pos.y, pos.z)
                end
                
                Derma_StringRequest("Hologram Position", "Position?",
                    default, function(text)
                        local x, y, z = text:match("([%-%.0-9]+)[^%-%.0-9]+([%-%.0-9]+)[^%-%.0-9]+([%-%.0-9]+)")
                        if z then
                            RunConsoleCommand("whd_act", line.HoloIndex, "pos", x, y, z)
                        else
                            Derma_Message("Position must be inputted as x, y, z",
                                "Error", "OK")
                        end
                    end)
            end)
            menu:AddOption("Set Angles...", function()
                local default = ""
                if ValidEntity(line.HoloEntity) then
                    local ang = line.HoloEntity:GetAngles()
                    default = Format("%g, %g, %g", ang.p, ang.y, ang.r)
                end
                
                Derma_StringRequest("Hologram Position", "Position?",
                    default, function(text)
                        local p, y, r = text:match("([%-%.0-9]+)[^%-%.0-9]+([%-%.0-9]+)[^%-%.0-9]+([%-%.0-9]+)")
                        if r then
                            RunConsoleCommand("whd_act", line.HoloIndex, "ang", p, y, r)
                        else
                            Derma_Message("Position must be inputted as p, y, r",
                                "Error", "OK")
                        end
                    end)
            end)
            menu:AddOption("Set Material...", function()
                Derma_StringRequest("Hologram Material", "Material path?",
                    "", function(text)
                        RunConsoleCommand("whd_act", line.HoloIndex, "material", text)
                    end)
            end)
            menu:AddOption("Set Skin...", function()
                Derma_StringRequest("Hologram Skin", "Skin number?",
                    "", function(text)
                        RunConsoleCommand("whd_act", line.HoloIndex, "skin", tonumber(text) or 0)
                    end)
            end)
            menu:AddOption("Set Color...", function()
                Derma_StringRequest("Hologram Color", "Color (r, g, b)?",
                    "", function(text)
                        local r, g, b = text:match("([0-9]+%.?[0-9]*)[^0-9]+([0-9]+%.?[0-9]*)[^0-9]+([0-9]+%.?[0-9]*)")
                        if b then
                            RunConsoleCommand("whd_act", line.HoloIndex, "color", r, g, b)
                        else
                            Derma_Message("Color must be inputted as r, g, b",
                                "Error", "OK")
                        end
                    end)
            end)
            menu:AddOption("Set Alpha...", function()
                Derma_StringRequest("Hologram Alpha", "Alpha (0-255)?",
                    "", function(text)
                        RunConsoleCommand("whd_act", line.HoloIndex, "alpha", tonumber(text) or 0)
                    end)
            end)
            local modelMenu = menu:AddSubMenu("Set Model...")
            for _, mdl in pairs(modelList) do
                modelMenu:AddOption(mdl, function()
                    RunConsoleCommand("whd_act", line.HoloIndex, "model", mdl)
                    line:SetColumnText(2, "models/holograms/" .. mdl .. ".mdl")
                end)
            end
            menu:AddOption("Delete", function()
                RunConsoleCommand("whd_act", line.HoloIndex, "delete")
                listBox:RemoveLine(index)
                listBox:SelectFirstItem()
            end)
            menu:Open() 
        end
        
        panel:AddControl("Button", {
            Label = "Refresh",
            Command = "wire_holo_designer_refresh",
        })
        
        panel:AddControl("Button", {
            Label = "Create Hologram",
        }).DoClick = function()
            RunConsoleCommand("whd_create")
        end
        
        panel:AddControl("Button", {
            Label = "Create Hologram (Choose Index)...",
        }).DoClick = function()
            Derma_StringRequest("Hologram Index", "Hologram index number?", "", function(text)
                local holoIndex = tonumber(text)
                if holoIndex and holoIndex >= 0 then
                    RunConsoleCommand("whd_create", holoIndex)
                end
            end)
        end
        
        for _, t in pairs(actions) do
            local l = t[1]
            local dirs = t[2]
            
            local buttonsPanel = vgui.Create("DPanelList", panel)
            buttonsPanel:EnableHorizontal(true)
            buttonsPanel:SetWide(150)
            buttonsPanel:SetSpacing(2)
            buttonsPanel.Paint = function() end
            for _, dir in pairs(dirs) do
                local btn = vgui.Create("DButton", buttonsPanel)
                btn:SetText(dir)
                btn:SetWide(string.len(dir) == 1 and 20 or 60)
                btn:SetTall(20)
                btn.DoClick = function(self)
                    DeselectModeBtns()
                    self:SetSelected(true)
                    mode[1] = l:lower()
                    mode[2] = dir:lower()
                end
                table.insert(modeBtns, btn)
                buttonsPanel:AddItem(btn)
                buttonsPanel:SetTall(btn:GetTall())
            end
            
            local lbl = vgui.Create("DLabel", panel)
            lbl:SetText(l .. ":")
            lbl:SizeToContents()
            panel:AddItem(lbl, buttonsPanel)
        end
        
        panel:AddControl("Slider", {
            Label = "Move Amount",
            Command = "wire_holo_designer_move_amt",
            min = 1,
            max = 100,
        }):SetDecimals(0)
        
        panel:AddControl("Slider", {
            Label = "Rotate Amount",
            Command = "wire_holo_designer_rotate_amt",
            min = 1,
            max = 180,
        }):SetDecimals(0)
        
        panel:AddControl("Slider", {
            Label = "Scale Amount",
            Command = "wire_holo_designer_scale_amt",
            min = 1,
            max = 20,
        }):SetDecimals(0)
        
        panel:AddControl("Button", {
            Label = "Generate E2 Code",
            Command = "wire_holo_designer_generate",
        }):SetTooltip("This will replace the code currently in your E2 editor.")
        
        modeBtns[1]:DoClick()
    end
    
    local function DrawWorldTriad(p1)
        local p2 = p1 + Vector(16, 0, 0)
        local p3 = p1 + Vector(0, 16, 0)
        local p4 = p1 + Vector(0, 0, 16)
        
        p1, p2, p3, p4 = p1:ToScreen(), p2:ToScreen(), p3:ToScreen(), p4:ToScreen()
        
        surface.SetFont("DefaultVerySmall")
        surface.SetDrawColor(255, 0, 0, 255)
        surface.SetTextColor(255, 0, 0, 255)
        surface.DrawLine(p1.x, p1.y, p2.x, p2.y) -- Forward
        surface.SetTextPos(p2.x + 1, p2.y + 1)
        surface.DrawText("X")
        surface.SetDrawColor(0, 255, 0, 255)
        surface.SetTextColor(0, 255, 0, 255)
        surface.DrawLine(p1.x, p1.y, p3.x, p3.y) -- Right
        surface.SetTextPos(p3.x + 1, p3.y + 1)
        surface.DrawText("Y")
        surface.SetDrawColor(0, 0, 255, 255)
        surface.SetTextColor(0, 0, 255, 255)
        surface.DrawLine(p1.x, p1.y, p4.x, p4.y) -- Up
        surface.SetTextPos(p4.x + 1, p4.y + 1)
        surface.DrawText("Z")
    end
    
    local function DrawTriad(p1, ang)
        local p2 = p1 + ang:Forward() * 16
        local p3 = p1 + ang:Right() * 16
        local p4 = p1 + ang:Up() * 16
        
        p1, p2, p3, p4 = p1:ToScreen(), p2:ToScreen(), p3:ToScreen(), p4:ToScreen()
        
        surface.SetFont("DefaultVerySmall")
        surface.SetDrawColor(255, 0, 0, 255)
        surface.SetTextColor(255, 0, 0, 255)
        surface.DrawLine(p1.x, p1.y, p2.x, p2.y) -- Forward
        surface.SetTextPos(p2.x + 1, p2.y + 1)
        surface.DrawText("X")
        surface.SetDrawColor(0, 255, 0, 255)
        surface.SetTextColor(0, 255, 0, 255)
        surface.DrawLine(p1.x, p1.y, p3.x, p3.y) -- Right
        surface.SetTextPos(p3.x + 1, p3.y + 1)
        surface.DrawText("Y")
        surface.SetDrawColor(0, 0, 255, 255)
        surface.SetTextColor(0, 0, 255, 255)
        surface.DrawLine(p1.x, p1.y, p4.x, p4.y) -- Up
        surface.SetTextPos(p4.x + 1, p4.y + 1)
        surface.DrawText("Z")
    end
    
    local data = {}
    function TOOL:DrawHUD()
        if not selEntIndex then return end
        local holo = Entity(selEntIndex)
        if not ValidEntity(holo) then return end
        if holo:GetClass() ~= "gmod_wire_hologram" then return end
        
        local pos = holo:GetPos()
        
        if mode[1] == "move" or mode[1] == "rotate"  then
            DrawWorldTriad(holo:GetPos())
        elseif mode[1] == "scale"then
            DrawTriad(holo:GetPos(), holo:GetAngles())
        end
    end
    
    datastream.Hook("HoloDesignerList", function(handler, id, encoded, decoded)
        selHoloIndex = nil
        selEntIndex = nil
        
        if listBox then
            listBox:Clear()
            
            for index, entIndex in pairs(decoded.holos) do
                local ent = Entity(entIndex)
                local line
                
                if ValidEntity(ent) and ent:GetClass() == "gmod_wire_hologram" then
                    line = listBox:AddLine(index, ent:GetModel())
                    line.HoloEntity = ent
                else
                    line = listBox:AddLine(index, "?")
                end
                
                line.HoloIndex = index
                line.EntIndex = entIndex
            end
            
            listBox:SelectFirstItem()
        end
        
        GAMEMODE:AddNotify("Holo Designer: Hologram list received.", NOTIFY_GENERIC, 3);
        surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
    end)
    
    usermessage.Hook("WHDHolo", function(um)
        local holoIndex = um:ReadLong()
        local entIndex = um:ReadLong()
        
        if not listBox then return end
        
        local ent = Entity(entIndex)
        local validEnt = ValidEntity(ent) and ent:GetClass() == "gmod_wire_hologram"
        
        for index, line in pairs(listBox:GetLines()) do
            if line.HoloIndex == holoIndex then
                line:SetColumnText(2, validEnt and ent:GetModel() or "?")
                listBox:ClearSelection()
                listBox:SelectItem(line)
                return
            end
        end
        
        local line
        
        if validEnt then
            line = listBox:AddLine(holoIndex, ent:GetModel())
            line.HoloEntity = ent
        else
            line = listBox:AddLine(holoIndex, "?")
        end
        
        line.HoloIndex = holoIndex
        line.EntIndex = entIndex

        listBox:ClearSelection()
        listBox:SelectItem(line)
    end)
    
    -- Borrowed from the Adv. Wire tool
    local function GetActiveTool(ply, tool)
        local active = ply:GetActiveWeapon()
        if not ValidEntity(active) then return end
        if active:GetClass() ~= "gmod_tool" then return end
        if active:GetMode() ~= tool then return end
        return active:GetToolObject(tool)
    end
    
    hook.Add("PlayerBindPress", "WireHoloDesigner", function(ply, bind, pressed)
        if not pressed then return end
        
        local tool = GetActiveTool(ply, "wire_holo_designer")
        if not tool then return end
        
        if bind:find("+attack2") then
            RunConsoleCommand("whd_sel")
            return true
        elseif bind:find("invnext") then
            if selHoloIndex then
                RunConsoleCommand("whd_b", selHoloIndex, mode[1], mode[2])
            end
            return true
        elseif bind:find("invprev") then
            if selHoloIndex then
                RunConsoleCommand("whd_f", selHoloIndex, mode[1], mode[2])
            end
            return true
        end
    end)
    
    concommand.Add("whd_s", function(ply, cmd, args)
        local entIndex = tonumber(args[1]) or 0
        local holoEnt = Entity(entIndex)
        
        if ValidEntity(holoEnt) and holoEnt:GetClass() == "gmod_wire_hologram" and listBox then
            for index, line in pairs(listBox:GetLines()) do
                if line.EntIndex == entIndex then
                    listBox:ClearSelection()
                    listBox:SelectItem(line)
                end
            end
        end
    end)
    
    concommand.Add("wire_holo_designer_clear", function(ply)
        selHoloIndex = nil
        selEntIndex = nil
        
        if listBox then
            listBox:Clear()
        end
    end)
    
    usermessage.Hook("WireHoloDesignerNoE2", function(um)
        GAMEMODE:AddNotify("Holo Designer: Click on an E2 first.", NOTIFY_ERROR, 5);
        surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
    end)
end

