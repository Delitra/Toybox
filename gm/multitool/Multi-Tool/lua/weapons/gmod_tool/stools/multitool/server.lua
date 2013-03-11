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

include("filtering.lua")

local trueFunc = function() return true end
local falseFunc = function() return false end

function TOOL:RemoveFromSelection(ent)
    if not self.Selection then self.Selection = {} end
    if not self.Selection[ent] then return end
    
    if ValidEntity(ent) then
        local r, g, b, a = ent:GetColor()
        if 255 == r and 0 == g and 255 == b and 100 == a then
            ent:SetColor(unpack(self.Selection[ent]))
        end
    end
    
    self.Selection[ent] = nil
end

function TOOL:AddToSelection(ent)
    if not self.Selection then self.Selection = {} end
    if self.Selection[ent] then return end
    if not ValidEntity(ent) then return end
    
    self.Selection[ent] = {ent:GetColor()}
    ent:SetColor(255, 0, 255, 100)
end

function TOOL:MakeFakeTraceRes(ent)
    return {
        FractionLeftSolid = 0,
        HitNonWorld = true,
        Fraction = 0,
        Entity = ent,
        HitNoDraw = false,
        HitSky = false,
        HitPos = ent:GetPos(),
        StartSolid = true,
        HitWorld = false,
        HitGroup = 0,
        HitNormal = Vector(0, 0, 0),
        HitBox = 0,
        Normal = Vector(0, 0, 0),
        Hit = true,
        MatType = 0,
        StartPos = ent:GetPos(),
        PhysicsBone = 0,
        WorldToLocal = Vector(0, 0, 0),
    }
end

function TOOL:Apply(tool, rootEnt)
    if not self.Selection then self.Selection = {} end
    
    if not MultiToolTools[tool] then
        return false, "Unknown tool"
    end
    
    -- Get the tool
    local t = MultiToolTools[tool]
    local toolObj = self:GetOwner():GetTool(t.Tool or tool)
    if not toolObj and not t.EachFunc then
        return false, "Tool doesn't exist"
    end
    
    -- Check if we have a root
    if t.Root and not ValidEntity(rootEnt) then
        return false, "Must right click on an entity"
    end
    
    -- If we need a root, make sure that the entity we are selecting as
    -- the root isn't in the self.Selection
    if t.Root then
        self:RemoveFromSelection(rootEnt)
    end
    
    -- Check if we have any entities even selected
    if table.Count(self.Selection) == 0 then
        return false, "No entities selected"
    end
    
    -- Call a reset function of the tool if needed
    if type(t.ResetFunc) == 'string' then
        toolObj[t.ResetFunc](toolObj)
    end
    
    -- Make a fake trace for the root entity
    local rootTr
    if rootEnt and ValidEntity(rootEnt) then
        rootTr = self:MakeFakeTraceRes(rootEnt)
    end
    
    -- Override undo so that we can capture all the undo's
    local oldUndoFinish = undo.Finish
    local oldUndoCreate = undo.Create
    if not t.NoUndo then
        undo.Create("Multi-Tool")
        undo.Create = function() end
        undo.Finish = function() end
    end
    
    -- Perform
    local status, err = pcall(function()
        for ent, oldColor in pairs(self.Selection) do
            if ValidEntity(ent) and self:CanSelect(ent) then
                local targetTr = self:MakeFakeTraceRes(ent)
                
                self:RemoveFromSelection(ent)
                
                if t.EachFunc then
                    t.EachFunc(ent)
                else
                    if t.Root == MULTITOOL_ADD_LEFT then
                        toolObj:LeftClick(rootTr)
                    elseif t.Root == MULTITOOL_ADD_RIGHT then
                        toolObj:RightClick(rootTr)
                    elseif t.Root ~= nil then
                        Error("Tool " .. tool .. " has invalid ROOT")
                    end
                    
                    if t.Each == MULTITOOL_ADD_LEFT then
                        toolObj:LeftClick(targetTr)
                    elseif t.Each == MULTITOOL_ADD_RIGHT then
                        toolObj:RightClick(targetTr)
                    else
                        Error("Tool " .. tool .. " has invalid EACH")
                    end
                end
            end
        end
    end)
    
    if not t.NoUndo then
        undo.Finish = oldUndoFinish
        undo.Create = oldUndoCreate
        undo.Finish()
    end
    
    if not status then
        ErrorNoHalt("Multi-Tool: " .. err)
    end
    
    return true
end

function TOOL:CanSelect(ent)
    return not ent:IsWorld() and not ent:IsPlayer() and not ent:IsNPC() and
        ent:GetModel() and ent:GetModel() ~= "" and not util.IsValidRagdoll(ent:GetModel()) and
        not ent:GetParent():IsPlayer() and 
        (self:GetClientNumber("use_filter") ~= 1 or self.Filter(ent, self:GetOwner())) and
        hook.Call("CanTool", GAMEMODE, self:GetOwner(), {Entity = ent}, "multitool") ~= false
end

function TOOL:CompileFilter()
    local filter = self:GetClientInfo("filter")
    
    
    if self.FilterText ~= filter then
        local ret, err = CompileMultiToolFilter(filter)
        
        if not ret then
            self:GetOwner():PrintMessage(HUD_PRINTTALK,
                "Multi-Tool Error: Filter failed to compile: " .. err)
            self.Filter = falseFunc
        else
            self.Filter = ret
            self.FilterText = filter
        end
    end
end

function TOOL:RightClick(tr)
    if not self.Selection then self.Selection = {} end
    
    local tool = self:GetClientInfo("tool")
    local shift = self:GetOwner():KeyDown(IN_SPEED)
    
    local status, err = self:Apply(tool, tr.Entity)
    if not status then
        self:GetOwner():PrintMessage(HUD_PRINTTALK, "Multi-Tool Error: " .. err)
    end
    
    self:SendCount()
    
    return true
end

function TOOL:LeftClick(tr)
    if not self.Selection then self.Selection = {} end
    
    local useRadius = self:GetClientNumber("use_radius") == 1
    local useConstrained = self:GetClientNumber("use_constrained") == 1
    local useFilter = self:GetClientNumber("use_filter") == 1
    local shift = self:GetOwner():KeyDown(IN_SPEED)
    
    local func = shift and self.RemoveFromSelection or
        self.AddToSelection
    
    self:CompileFilter()
    
    if ValidEntity(tr.Entity) and self:CanSelect(tr.Entity) then
        func(self, tr.Entity)
    end
    
    if useConstrained and ValidEntity(tr.Entity) then        
        local constrs = constraint.GetAllConstrainedEntities(tr.Entity)
        for _, ent in pairs(constrs) do
            if self:CanSelect(ent) then
                func(self, ent)
            end
        end
    end
    
    if useRadius then
        local radius = math.Clamp(self:GetClientNumber("radius"), 1, 10000)
        --local ents = ents.FindInSphere(tr.HitPos, radius)
        local props = g_SBoxObjects[self:GetOwner():UniqueID()] or {}
        
        for _, lst in pairs(props) do
            for _, ent in pairs(lst) do
                if ValidEntity(ent) and ent:GetPos():Distance(tr.HitPos) < radius and
                    self:CanSelect(ent) then
                    func(self, ent)
                end
            end
        end
    end
    
    self:SendCount()
    
    return true
end

function TOOL:Reload(tr)
    if not self.Selection then self.Selection = {} end
    
    for ent, oldColor in pairs(self.Selection) do
        self:RemoveFromSelection(ent)
    end
    
    self:SendCount()
    
    return true
end

function TOOL:SendCount()
    if not self.Selection then self.Selection = {} end
    
    umsg.Start("MultiToolCount", self:GetOwner())
    umsg.Short(table.Count(self.Selection))
    umsg.End()
end