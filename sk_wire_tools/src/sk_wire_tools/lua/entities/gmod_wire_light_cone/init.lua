-- SK's Wire Tools
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

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.WireDebugName = "LightCone"

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
    
	self.R, self.G, self.B = 0, 0, 0
    self.Alpha = 255
    self.ConeLength = 300
    self.ConeWidth = 40
    
	self.Entity:SetColor(0, 0, 0, 255)
	
	self.Inputs = WireLib.CreateInputs(self.Entity, {"Red", "Green", "Blue", "RGB [VECTOR]", "Length", "Width"})
end

function ENT:Setup()
    self:CreateCone()
    
    self:UpdateOutput()
end

function ENT:CreateCone()
    local ang = self.Entity:GetAngles()
    
    self:RemoveCone()
    
    self.ConeEntity = ents.Create("point_spotlight")
    self.ConeEntity:SetPos(self.Entity:LocalToWorld(Vector(0, 0, 0)))
    self.ConeEntity:SetParent(self.Entity)
    --self.ConeEntity:SetKeyValue("HDRColorScale", 2)
    self.ConeEntity:SetKeyValue("spotlightlength", self.ConeLength / 2)
    self.ConeEntity:SetKeyValue("spotlightwidth", self.ConeWidth)
    self.ConeEntity:SetKeyValue("rendercolor", string.format("%f %f %f", self.R, self.G, self.B))
    self.ConeEntity:SetKeyValue("angles", string.format("%f %f %f", ang.p - 90, ang.y, ang.r))
    --self.ConeEntity:SetKeyValue("alpha", self.Alpha)
    self.ConeEntity:SetKeyValue("spawnflags", 3)
    self.ConeEntity:Spawn()
    self.ConeEntity:Activate() 
    self.ConeEntity:Fire("LightOn", "", 0)
end

function ENT:RemoveSpotlightEnds()
    -- This causes existing spotlights to "blink", but it does not appear
    -- to break anything. If spotlight_ends are not deleted, then they
    -- (along with their light cone) will persist on the map.
    local props = ents.FindByClass("spotlight_end")
    for _, ent in pairs(props) do
        ent:Fire("Kill", "", 0)
        ent:Remove()
    end
end

function ENT:RemoveCone()
    if ValidEntity(self.ConeEntity) then
        self.ConeEntity:Fire("Kill", "", 0)
        self.ConeEntity:Fire("LightOff", "", 0)
    end
    
    self:RemoveSpotlightEnds()
end

function ENT:OnRemove()
    self:RemoveCone()
end

function ENT:TriggerInput(iname, value)
	if iname == "Red" then
		self.R = value
	elseif iname == "Green" then
		self.G = value
	elseif iname == "Blue" then
		self.B = value
	elseif iname == "RGB" then
		self.R, self.G, self.B = value[1], value[2], value[3]
	elseif iname == "Length" then
		self.ConeLength = math.Clamp(value, 0, 10000)
        if self.ConeLength == 0 then
            self.ConeLength = 300
        end
	elseif iname == "Width" then
		self.ConeWidth = math.Clamp(value, 0, 500) -- Effective limit is about 100
        if self.ConeWidth == 0 then
            self.ConeWidth = 40
        end
    end
    
    local r, g, b, a = self.Entity:GetColor()
	self.Entity:SetColor(self.R, self.G, self.B, a)
    self.ConeEntity:SetKeyValue("spotlightlength", self.ConeLength / 2)
    self.ConeEntity:SetKeyValue("spotlightwidth", self.ConeWidth)
    self.ConeEntity:SetKeyValue("rendercolor", string.format("%f %f %f", self.R, self.G, self.B))
    
    self:RemoveSpotlightEnds() -- Must be done for a change to appear
    
    self:UpdateOutput()
end

function ENT:UpdateOutput()
    local text = "Light Cone\n" ..
                 "Color: " .. tostring(self.R) .. ", " .. tostring(self.G) .. ", " .. tostring(self.B) .. "\n" ..
                 "Width: " .. tostring(self.ConeWidth) .. "\n" ..
                 "Length: " .. tostring(self.ConeLength)
    self:SetOverlayText(text)
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
end
