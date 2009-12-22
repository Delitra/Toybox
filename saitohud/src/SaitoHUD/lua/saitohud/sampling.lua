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
-- Sampling context
--------------------------------------------------

local SamplingContext = {}

function SamplingContext:new(ent)
    local instance = {
        ["ent"] = ent,
        ["points"] = {},
    }
    
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function SamplingContext:Log(sampleSize)
    if not self.ent or not ValidEntity(self.ent) then
        self.Log = function() end
        self.Draw = function() end
        return false
    end
    
    table.insert(self.points, self.ent:GetPos())
    while #self.points > SaitoHUD.sampleSize do
        table.remove(self.points, 1)
    end
    
    return true
end

function SamplingContext:Draw(drawNodes)
    if not self.ent or not ValidEntity(self.ent) then
        self.Log = function() end
        self.Draw = function() end
        return false
    end
    
    local dim = 5
    local currentPos = self.ent:GetPos()
    local lastPt = nil
    
    surface.SetDrawColor(0, 255, 255, 255)
    
    for _, pt in pairs(self.points) do
        if lastPt != nil and lastPt != pt then 
            local from = lastPt:ToScreen()
            local to = pt:ToScreen()
            
            if from.visible and to.visible then
                surface.DrawLine(from.x, from.y, to.x, to.y)
                
                if SaitoHUD.drawSampleNodes then
                    surface.DrawOutlinedRect(to.x - dim / 2, to.y - dim / 2, dim, dim)
                end
            end
        end
        
        lastPt = pt
    end
    
    if lastPt != nil and lastPt != currentPos then 
        local from = lastPt:ToScreen()
        local to = currentPos:ToScreen()
        if from.visible and to.visible then
            surface.DrawLine(from.x, from.y, to.x, to.y)
        end
    end
    
    return true
end

--------------------------------------------------
-- Plug into SaitoHUD
--------------------------------------------------

SaitoHUD.samplers = {}
SaitoHUD.sampleResolution = 0.1
SaitoHUD.sampleSize = 100
SaitoHUD.drawSampleNodes = true

function SaitoHUD.RemoveSample(ent)
    for k, ctx in pairs(SaitoHUD.samplers) do
        if ctx.ent == ent then
            table.remove(SaitoHUD.samplers, k)
        end
    end
end

function SaitoHUD.AddSample(ent)
    for k, ctx in pairs(SaitoHUD.samplers) do
        if ctx.ent == ent then
            return
        end
    end
    
    local ctx = SamplingContext:new(ent)
    table.insert(SaitoHUD.samplers, ctx)
end

function SaitoHUD.SetSample(ent)
    local ctx = SamplingContext:new(ent)
    SaitoHUD.samplers = {ctx}
end

function SaitoHUD.LogSamples()
    for k, ctx in pairs(SaitoHUD.samplers) do
        if not ctx:Log() then
            table.remove(SaitoHUD.samplers, k)
        end
    end
end

function SaitoHUD.DrawSamples()
    for k, ctx in pairs(SaitoHUD.samplers) do
        if not ctx:Draw() then
            table.remove(SaitoHUD.samplers, k)
        end
    end
end