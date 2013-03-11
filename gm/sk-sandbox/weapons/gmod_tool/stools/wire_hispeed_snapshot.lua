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

TOOL.Category = "Wire - Tools"
TOOL.Name = "High Speed Snapshot"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.Tab = "Wire"

if CLIENT then
    language.Add("Tool_wire_hispeed_snapshot_name", "High Speed Snapshot")
    language.Add("Tool_wire_hispeed_snapshot_desc", "Shows a memory snapshot of a high speed component.")
    language.Add("Tool_wire_hispeed_snapshot_0", "Primary: Open snapshot tool on entity")
end

if SERVER then
    local function IsWire(entity)
        if entity.IsWire == true then return true end
        if entity.Inputs or entity.Outputs then return true end
        return false
    end
    
    function TOOL:SendSnapshot(ent, index)
        umsg.Start("WireHighspeedSnapshot", self:GetOwner())
        umsg.Entity(ent)
        umsg.Long(index)
        for i = index, index + 49 do
            umsg.Long(ent:ReadCell(i))
        end
        umsg.End()
    end

    function TOOL:LeftClick(tr)
        if not ValidEntity(tr.Entity) then return end
        if not IsWire(tr.Entity) then return end
        if not tr.Entity.ReadCell then return end
        
        self.SelEntity = tr.Entity
        self:SendSnapshot(self.SelEntity, 1)
        
        return true
    end
    
    local function PageSnapshot(ply, cmd, args)
        if not ValidEntity(ply) then return end
        local tool = ply:GetTool("wire_hispeed_snapshot")
        if not ValidEntity(tool.SelEntity) then return end
        
        local startIndex = tonumber(args[1])
        if not startIndex or startIndex < 1 then return end
        tool:SendSnapshot(tool.SelEntity, startIndex)
    end
    
    local function ClearEntity(ply, cmd, args)
        if not ValidEntity(ply) then return end
        local tool = ply:GetTool("wire_hispeed_snapshot")
        tool.SelEntity = nil
    end
    
    concommand.Add("wire_highspeed_snapshot_page", PageSnapshot)
    concommand.Add("wire_highspeed_snapshot_close", ClearEntity)
end

if CLIENT then
    local PANEL = {}

    function PANEL:Init()
        self.StartIndex = 1
        
        local frame = self
        local w = 500
        local h = 400
        frame:SetPos((ScrW() - w) / 2, (ScrH() - h) / 2)
        frame:SetSize(w, h)
        frame:SetTitle("SK's Wire High Speed Snapshot")
        frame:SetVisible(true)
        frame:SetDraggable(true)
        frame:SetSizable(true)
        frame:ShowCloseButton(true)
        frame:SetVisible(true)
        frame:MakePopup()

        local entityLabel = vgui.Create("DLabel", frame)
        self.EntityLabel = entityLabel
        entityLabel:SetText("wire_cpu (#41)")
        entityLabel:SetPos(8, 29)
        entityLabel:SizeToContents()
        entityLabel:SetSize(200, entityLabel:GetTall())

        local cellSelect = vgui.Create("DTextEntry", frame)
        self.CellSelect = cellSelect

        local prevBatch = vgui.Create("DButton", frame)
        prevBatch:SetSize(30, 20)
        prevBatch:SetText("<<")
        prevBatch.DoClick = function()
            local index = math.max(1, self.StartIndex - 50)
            if index == self.StartIndex then return end
            RunConsoleCommand("wire_highspeed_snapshot_page", index)
        end

        local nextBatch = vgui.Create("DButton", frame)
        nextBatch:SetSize(30, 20)
        nextBatch:SetText(">>")
        nextBatch.DoClick = function()
            local index = self.StartIndex + 50
            if index == self.StartIndex then return end
            RunConsoleCommand("wire_highspeed_snapshot_page", self.StartIndex + 50)
        end

        local go = vgui.Create("DButton", frame)
        go:SetSize(30, 20)
        go:SetText("Go")
        go.DoClick = function()
            local index = tonumber(cellSelect:GetValue())
            if not index or index < 1 then
                Derma_Message("Invalid cell index.", "Error", "OK")
            else
                if index == self.StartIndex then return end
                RunConsoleCommand("wire_highspeed_snapshot_page", index)
            end
        end
        go.DoRightClick = function()
            local index = tonumber(cellSelect:GetValue())
            if not index or index < 1 then
                Derma_Message("Invalid cell index.", "Error", "OK")
            else
                local index = math.max(1, index - 10)
                if index == self.StartIndex then return end
                RunConsoleCommand("wire_highspeed_snapshot_page", index)
            end
        end

        local list = vgui.Create("DListView", frame)
        self.List = list
        list:AddColumn("Cell")
        list:AddColumn("Value")
        list:AddColumn("ASCII")

        local asciiText = vgui.Create("DTextEntry", frame)
        self.ASCIIText = asciiText
        asciiText:SetMultiline(true)
        asciiText:SetEditable(false)

        local close = vgui.Create("DButton", frame)
        close:SetSize(90, 25)
        close:SetText("Close")
        close.DoClick = function(button)
            frame:Close()
        end

        local oldPerform = frame.PerformLayout
        frame.PerformLayout = function()
            oldPerform(frame)
            nextBatch:SetPos(frame:GetWide() - prevBatch:GetWide() - 8, 26)
            go:SetPos(frame:GetWide() - go:GetWide() - prevBatch:GetWide() - 12, 26)
            cellSelect:SetPos(frame:GetWide() - prevBatch:GetWide() -
                cellSelect:GetWide() - go:GetWide() - 16, 26)
            prevBatch:SetPos(frame:GetWide() - prevBatch:GetWide() - cellSelect:GetWide() -
                go:GetWide() - prevBatch:GetWide() - 20, 26)
            list:StretchToParent(8, 26 + 25, 8, 88)
            asciiText:SetPos(8, 26 + 25 + list:GetTall() + 8)
            asciiText:SetSize(frame:GetWide() - 16, 40)
            close:SetPos(frame:GetWide() - close:GetWide() - 8,
                         frame:GetTall() - close:GetTall() - 8)
        end

        local oldClose = frame.Close
        frame.Close = function()
            RunConsoleCommand("wire_highspeed_snapshot_close")
            oldClose(frame)
        end

        frame:InvalidateLayout(true, true)
    end

    function PANEL:UpdateSnapshot(ent, firstCell, data)
        self.EntityLabel:SetText(string.format("%s (#%s)", ent:GetClass(), ent:EntIndex()))
        self.List:Clear()
        
        local chars = ""
        
        for _, v in pairs(data) do
            local cell, value = unpack(v)
            local char = ""
            if value >= 32 and value <= 126 then
                char = string.char(value)
                chars = chars .. char
            else
                chars = chars .. "."
            end
            self.List:AddLine(cell, value, char)
        end
        
        self.StartIndex = firstCell
        self.CellSelect:SetText(tostring(firstCell))
        self.ASCIIText:SetText(chars)
    end

    vgui.Register("WireHighspeedSnapshot", PANEL, "DFrame")
    
    local snapshotWindow = nil
    
    function ReceiveSnapshot(um)
        local ent = um:ReadEntity()
        local startIndex = um:ReadLong()
        local data = {}
        for i = 0, 49 do
            local index = startIndex + i
            table.insert(data, {index, um:ReadLong()})
        end
        
        if not snapshotWindow or not snapshotWindow:IsValid() then
            snapshotWindow = vgui.Create("WireHighspeedSnapshot")
        end
        
        snapshotWindow:UpdateSnapshot(ent, startIndex, data)
    end
    
    usermessage.Hook("WireHighspeedSnapshot", ReceiveSnapshot)
end
