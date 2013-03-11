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

local PANEL = {}

function PANEL:Init()
    self:SetTitle("Filter Builder")
    self:SetSizable(false)
    self:SetSize(400, 350)
    self:ShowCloseButton(true)
    self:SetDraggable(true)
    self:Center()
    self:MakePopup()
    
    self.FilterLbl = vgui.Create("DLabel", self)
    self.FilterLbl:SetText("Filter:")
    self.FilterLbl:SizeToContents()
    self.FilterLbl:SetPos(10, 30)
    
    self.FilterEntry = vgui.Create("DTextEntry", self)
    self.FilterEntry:SetMultiline(true)
    self.FilterEntry:SetPos(60, 28)
    self.FilterEntry:SetSize(332, 50)
    self.FilterEntry:SetEnterAllowed(true)
    self.FilterEntry:SetConVar("multitool_filter")
    
    self.BookmarkBtn = vgui.Create("DButton", self)
    self.BookmarkBtn:SetText("Bookmark")
    self.BookmarkBtn:SetWide(80)
    self.BookmarkBtn:SetPos(self:GetWide() - self.BookmarkBtn:GetWide() - 8, 85)
    self.BookmarkBtn.DoClick = function() self:Bookmark() end
    
    self.CloseBtn = vgui.Create("DButton", self)
    self.CloseBtn:SetText("Close")
    self.CloseBtn:SetWide(80)
    self.CloseBtn:SetPos(self:GetWide() - self.CloseBtn:GetWide() - 8,
                         self:GetTall() - self.CloseBtn:GetTall() - 8)
    self.CloseBtn.DoClick = function() self:Close() end
    
    local lbl = vgui.Create("DLabel", self)
    lbl:SetText("Example: prop_physics and not mdl=bluebarrel")
    lbl:SizeToContents()
    lbl:SetPos(10, 85)
    
    self.Tabs = vgui.Create("DPropertySheet", self)
    self.Tabs:SetMultiline(true)
    self.Tabs:StretchToParent(10, 115, 10, 40)
    
    self.Bookmarks = vgui.Create("DListView", self)
    self.Bookmarks:AddColumn("Filter")
    self.Bookmarks.OnRowSelected = function(lst, index, line)
        RunConsoleCommand("multitool_filter", line:GetValue(1))
    end
    self.Bookmarks.OnRowRightClick = function(lst, index, line)
        local menu = DermaMenu()
        menu:AddOption("Delete", function()
            self:DeleteBookmark(line:GetValue(1))
            self.Bookmarks:RemoveLine(index)
        end)
        menu:Open() 
    end
    
    self.Tabs:AddSheet("Bookmarked", self.Bookmarks, "gui/silkicons/star", false, false)
    
    --self.FilterEntry:RequestFocus()
    
    self:RepopulateList()
end

function PANEL:RepopulateList()
    self.Bookmarks:Clear()
    
    local result = sql.Query([[SELECT filter FROM multitool_filters
                               WHERE type = 'simple' ORDER BY filter ASC]])
    
    if result then
        for id, row in pairs(result) do
            self.Bookmarks:AddLine(row.filter)
        end
    end
end

function PANEL:DeleteBookmark(filter)
    sql.Query([[DELETE FROM multitool_filters
                WHERE type = 'simple' AND filter = ]] .. sql.SQLStr(filter))
end

function PANEL:Bookmark()
    local filter = self.FilterEntry:GetValue():Trim():gsub("\n", "")
    
    if filter == "" then return end
    
    if not sql.TableExists("multitool_filters") then
        sql.Query("CREATE TABLE multitool_filters (type TEXT, filter TEXT, PRIMARY KEY(type ASC, filter ASC))")
    end
    
    local res =
    sql.Query([[INSERT OR REPLACE INTO multitool_filters
                (type, filter) VALUES ('simple', ]] .. sql.SQLStr(filter) .. [[)]])
    
    if res == false then
        Error("Failed to save filter!")
    end
    
    local lines = self.Bookmarks:GetLines()
    
    for _, line in pairs(lines) do
        if line:GetValue(1) == filter then return end
    end
    
    self.Bookmarks:AddLine(filter)
end

vgui.Register("MultiToolFilterBuilder", PANEL, "DFrame")