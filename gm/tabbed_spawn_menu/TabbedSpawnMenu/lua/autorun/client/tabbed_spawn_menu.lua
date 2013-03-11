-- Tabbed Spawn Menu
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

local COL_NAME = 1
local COL_COUNT = 2

local function ParseCSV(data)
    -- Snatched from PlayX
    local lines = string.Explode("\n", data:gsub("\r", ""))
    local result = {}
    
    for i, line in pairs(lines) do
        local line = line:Trim()
        
        if line ~= "" then
            local buffer = ""
            local escaped = false
            local inQuote = false
            local fields = {}
            
            for c = 1, #line do
                local char = line:sub(c, c)
                if escaped then
                    buffer = buffer .. char
                    escaped = false
                else
                    if char == "\\" then
                        escaped = true
                    elseif char == "\"" then
                        inQuote = not inQuote
                    elseif char == "," then
                        if inQuote then
                            buffer = buffer .. char
                        else
                            table.insert(fields, buffer)
                            buffer = ""
                        end
                    else
                        buffer = buffer .. char
                    end
                end
            end
            
            table.insert(fields, buffer)
            table.insert(result, fields)
       end
    end
    
    return result
end

local function LoadAliases()
    local aliasData = file.Read("tabbed_spawnlist_groups.txt")
    local aliases = {
        Uncategorized = "Ungrouped",
    }
    
    if aliasData ~= nil then
        local lines = ParseCSV(aliasData)
        
        for _, line in pairs(lines) do
            local orig = line[1]
            local new = line[2]
            if orig and new then
                aliases[orig] = new
            end
        end
    end
    
    return aliases
end

local function LoadOrder()
    local orderData = file.Read("tabbed_spawnlist_order.txt")
    local order = {}
    
    if orderData ~= nil then
        local lines = string.Explode("\n", orderData)
        for _, line in pairs(lines) do
            local line = line:Trim()
            if line ~= "" then
                table.insert(order, line)
            end
        end
    end
    
    return order
end

local function ParseGroup(strName, aliases)
    local group = string.match(strName, "^%[([^%]]+)%]") or "Ungrouped"
    return aliases[group] and aliases[group] or group
end

local function ResetSpawnMenu()
    -- Destroy old prop lists, in case of reattach
    if g_PropSpawnController.PropLists then
        for _, panel in pairs(g_PropSpawnController.PropLists) do
            panel:Remove()
        end
    end
    
    -- Detroy old prop tabs, in case of reattach
    if g_PropSpawnController.PropTabs then
        g_PropSpawnController.PropTabs:Remove()
    end
    
    -- Kill original prop list
    if g_PropSpawnController.PropList.Remove then
        g_PropSpawnController.PropList:Remove()
    end
end

local function OverrideSpawnMenu()
    local aliases = LoadAliases()
    
    ResetSpawnMenu()
    
    g_PropSpawnController.CategoryTable = {}
    g_PropSpawnController.Panels = {}
    g_PropSpawnController.PropLists = {}
    
    -- Create prop tabs property sheet
    local propTabs = vgui.Create("DPropertySheet", g_PropSpawnController)
    propTabs:SetPadding(0)
    g_PropSpawnController.PropTabs = propTabs
    g_PropSpawnController:SetTop(propTabs)
    
    -- The original spawn list used row numbers to locate categories, but
    -- as we now have multiple lists, we need to use a fake row number and
    -- translate these to the correct item.
    local fakeRowNumber = 1
    local defaultFakeRow = 1
    
    g_PropSpawnController.GetGroupForCategory = function(self, strName)
        local group = ParseGroup(strName, aliases)
        
        if not self.PropLists[group] then            
            self.PropLists[group] = vgui.Create("DListView", self)
            self.PropLists[group]:SetDataHeight(16)
            self.PropLists[group]:AddColumn("#Name")
            self.PropLists[group]:AddColumn("#Count"):SetFixedWidth(50)
            self.PropLists[group].OnRowSelected = function(propList, rowNum)
                self:ChangeRow(propList:GetLine(rowNum).FakeRowNumber)
            end
            self.PropLists[group].OnRowRightClick = function(propList, rowNum) 
                self:CategoryMenu(propList:GetLine(rowNum).FakeRowNumber)
            end
            
            propTabs:AddSheet(group, self.PropLists[group],
                "gui/silkicons/application_view_tile", false, false, nil)
        end
        
        return group, self.PropLists[group]
    end
    
    g_PropSpawnController.AddCategory = function(self, strName, existingPropPanel)
        local group, propList = self:GetGroupForCategory(strName)
        
        -- Create the prop panel
        local line = propList:AddLine(strName, 0)
        line.FakeRowNumber = fakeRowNumber
        if existingPropPanel and type(existingPropPanel) == "Panel" then
            line.PropPanel = existingPropPanel
        else
            line.PropPanel = vgui.Create("PropPanel", self)
            line.PropPanel:SetVisible(false)
            line.PropPanel:SetControllerPanel(self)
            line.PropPanel:SetCategoryName(strName)
        end
        
        -- Resort the prop list
        propList:SortByColumn(COL_NAME, false)
        
        -- Shim!
        table.insert(self.Panels, line.PropPanel)
        self.CategoryTable[strName] = line
        self.PropPanels[fakeRowNumber] = line.PropPanel
        
        if strName == "Useful Construction Props" then
            defaultFakeRow = fakeRowNumber
        end
        
        fakeRowNumber = fakeRowNumber + 1
        
        g_PropSpawnController:InvalidateLayout()

        return line
    end
    
    -- It would be better if spawnmenu.RenamePropCategory was overridden, but
    -- that increases the risk of data loss in the future
    -- local oldRename = g_PropSpawnController.RenameCategory
    -- g_PropSpawnController.RenameCategory = function(self, strOldName, strName)
        -- if not strName or strName == "" then return end
        
        -- oldRename(self, strOldName, strName)
        
        -- local oldGroup = ParseGroup(strOldName, aliases)
        
        -- if oldGroup ~= ParseGroup(strName, aliases) then
            -- local line = self:GetCategory(strName)
            -- local listView = self.PropLists[oldGroup]
            -- g_PropSpawnController.AddCategory(self, strName, line.PropPanel)
            -- PrintTable(self.PropLists)
            -- print("RENAMED", oldGroup, strName)
            -- for k, testLine in pairs(listView:GetLines()) do
                -- if testLine == line then
                    -- listView:RemoveLine(k)
                    -- break
                -- end
            -- end
        -- end
    -- end
    
    -- We are faking some methods at minimum so that categories can be
    -- emptied, renamed, deleted, and added to. Rather than merely proxying all
    -- calls to the current active prop list, we are choosing to define only
    -- some methods so as to prevent an unanticipated future conflict (a Lua
    -- error is better than a lost spawnlist).
    local lastUpdatedPropList = nil
    g_PropSpawnController.PropList = {}
    g_PropSpawnController.PropList.GetSelected = function(self)
        return propTabs:GetActiveTab():GetPanel():GetSelected()
    end
    g_PropSpawnController.PropList.RemoveLine = function(self, id)
        return propTabs:GetActiveTab():GetPanel():RemoveLine(id)
    end
    -- g_PropSpawnController.PropList.AddLine = function(self, ...)
        -- local arg = {...}
        -- local group, propList = self:GetGroupForCategory(arg[1])
        -- lastUpdatedPropList = propList
        -- return propList:AddLine(unpack(arg))
    -- end
    g_PropSpawnController.PropList.InvalidateLayout = function(self)
        if lastUpdatedPropList then
            lastUpdatedPropList:InvalidateLayout()
        end
    end
    
    -- Remove the SetTopMax stuff
    g_PropSpawnController:SetTopMax(5000) -- TODO: Make cleaner
    
    local oldPopulateFromStored = g_PropSpawnController.PopulateFromStored
    g_PropSpawnController.PopulateFromStored = function(self, ...)
        local arg = {...}
        
        -- We want to pre-populate the tabs so we can set order
        local order = LoadOrder()
        
        if #order > 0 then
            local props = spawnmenu.GetPropTable()
            local hasGroup = {}
            for cat, _ in pairs(props) do
                hasGroup[ParseGroup(cat, aliases)] = true
            end
            
            for _, group in pairs(order) do
                if hasGroup[group] then
                    self:GetGroupForCategory("[" .. group .. "]")
                end
            end
        end
        
        oldPopulateFromStored(self, unpack(arg))
    end
    
    -- Remove the SetTopMax stuff
    g_PropSpawnController.PerformLayout = function(self)
        DVerticalDivider.PerformLayout(self)
    end
    
    -- Do the actual load
    g_PropSpawnController:PopulateFromStored()
    g_PropSpawnController:UpdatePropCounts()
    
    -- Pick a row, reflow
    g_PropSpawnController:ChangeRow(defaultFakeRow)
    g_PropSpawnController:InvalidateLayout()
end

local oldPopulate = nil
local oldUpdateCounts = nil
local doOverride = true

hook.Add("PopulatePropMenu", "CreateSpawnMenuTabs", function()
    local self = g_PropSpawnController
    
    -- Make sure that we can do it!
    if not self or not self.PopulateFromStored or not self.UpdatePropCounts then
        doOverride = false
        return
    end
    
    oldPopulate = self.PopulateFromStored
    oldUpdateCounts = self.UpdatePropCounts
    -- Nuke these functions so that they don't load the props before we
    -- intervene (loading takes a while)
    self.PopulateFromStored = function() end
    self.UpdatePropCounts = function() end
    doOverride = true
end)

hook.Add("PostReloadToolsMenu", "CreateSpawnMenuTabs", function()
    local self = g_PropSpawnController
    if doOverride then
        self.PopulateFromStored = oldPopulate
        self.UpdatePropCounts = oldUpdateCounts
        if self.PropList then
            OverrideSpawnMenu()
        end
    end
end)