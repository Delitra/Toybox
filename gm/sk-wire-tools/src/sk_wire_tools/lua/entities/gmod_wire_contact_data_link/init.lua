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

ENT.WireDebugName = "ContactDataLink"

local allowedTypes = {NORMAL="N", STRING="S", VECTOR2="2", VECTOR="V",
                      VECTOR4="4", ANGLE="A", COLOR="C", ENTITY="E",
                      TABLE="T", ARRAY="R", ANY="*", WIRELINK="W"}

local nilTypeValues = {NORMAL=0,
                       STRING="",
                       VECTOR2={0, 0},
                       VECTOR=Vector(0, 0, 0),
                       VECTOR4={0, 0, 0, 0},
                       ANGLE=Angle(0, 0, 0),
                       COLOR=Color(0, 0, 0),
                       ENTITY=NULL,
                       TABLE={},
                       ARRAY={},
                       ANY=0,
                       WIRELINK=NULL}

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	--self.Inputs = Wire_CreateInputs(self.Entity, {"A", "B", "C", "D", "E", "F", "G", "H"})
	--self.Outputs = Wire_CreateOutputs(self.Entity, {"A", "B", "C", "D", "E", "F", "G", "H", "Connected"})
    
    self.TypeSignature = ""
    self.TypeString = ""
    self.Touching = {}
    self.SecureInput = false
end

function ENT:Setup(types, secureInput)
    self.TypeSignature = ""
    self.TypeString = ""
    self.SecureInput = secureInput
    
    local inputNames = {}
    local inputTypes = {}
    local outputNames = {}
    local outputTypes = {}
    
	for i = 1, 8 do
        local id = string.char(64 + i)
		local tp = string.upper(types[id])
        if not allowedTypes[tp] then
            tp = "NORMAL"
        end
        table.insert(inputNames, id)
        table.insert(inputTypes, tp)
        table.insert(outputNames, id)
        table.insert(outputTypes, tp)
        
        self.TypeSignature = self.TypeSignature .. tp .. "|"
        self.TypeString = self.TypeString .. allowedTypes[tp] .. ""
	end

    table.insert(outputNames, "Connected")
    table.insert(outputTypes, "NORMAL")
    table.insert(outputNames, "TypeString")
    table.insert(outputTypes, "STRING")
    
	self.Inputs = WireLib.CreateSpecialInputs(self.Entity, inputNames, inputTypes)
	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, outputNames, outputTypes)
    
	Wire_TriggerOutput(self.Entity, "TypeString", self.TypeString)
    
    self:UpdateOutput()
end

function ENT:OnRemove()
	self.BaseClass.Think(self)
end

function ENT:TriggerInput(iname, value)
    for ent, _ in pairs(self.Touching) do
        if ent.Entity.TypeSignature == self.TypeSignature and 
           (!ent.Entity.SecureInput or self.pl:SteamID() == ent.pl:SteamID()) then
            Wire_TriggerOutput(ent.Entity, iname, value)
        end
    end
    self:UpdateOutput()
end

function ENT:TypeCompatibleCount()
    local count = 0
    for ent, _ in pairs(self.Touching) do
        if ent.Entity.TypeSignature == self.TypeSignature and 
           (!ent.Entity.SecureInput or self.pl:SteamID() == ent.pl:SteamID()) then
            count = count + 1
        end
    end
    return count
end

function ENT:StartTouch(ent)
	if ent:GetClass() == "gmod_wire_contact_data_link" then
		self.Touching[ent] = true
        for _, input in pairs(self.Inputs) do
            if ent.Entity.TypeSignature == self.TypeSignature and 
               (!ent.Entity.SecureInput or self.pl:SteamID() == ent.pl:SteamID()) then
                Wire_TriggerOutput(ent.Entity, input.Name, input.Value)
            end
        end
	end
	Wire_TriggerOutput(self.Entity, "Connected", self:TypeCompatibleCount())
    self:UpdateOutput()
end

function ENT:EndTouch(ent)
	if ent:GetClass() == "gmod_wire_contact_data_link" then
		self.Touching[ent] = nil
        ent.Entity:ClearTouching()
	end
    self:ClearTouching()
	Wire_TriggerOutput(self.Entity, "Connected", self:TypeCompatibleCount())
    self:UpdateOutput()
end

function ENT:ClearTouching()
    if self:TypeCompatibleCount() == 0 then
        for _, output in pairs(self.Outputs) do
            Wire_TriggerOutput(self.Entity, output.Name, nilTypeValues[output.Type])
        end
    end
end

-- function ENT:ReadCell(addr)
	-- if addr >= 0 && addr < 8 then
        -- local id = string.char(65 + addr)
        -- if self.Inputs[id].Type == "NORMAL" then
            -- return tonumber(self.Outputs[string.char(65 + addr)].Value)
        -- end
        -- return nil
	-- else
		-- return nil
	-- end
-- end

-- function ENT:WriteCell(addr, value)
	-- if addr >= 0 && addr < 8 then
        -- local id = string.char(65 + addr)
        -- if self.Inputs[id].Type == "NORMAL" then
            -- self.Inputs[id].Value = value
            -- self:TriggerInput(id, value)
            -- return true
        -- end
		-- return false
	-- else
		-- return false
	-- end
-- end

function ENT:UpdateOutput()
    local text = "Contact Data Link"
    text = text .. "\nType signature: " .. self.TypeString
    text = text .. "\nConnected (compatible): " .. self:TypeCompatibleCount()
    text = text .. "\nConnected (incompatible): " .. (table.Count(self.Touching) - self:TypeCompatibleCount())
    if self.SecureInput then
        text = text .. "\n*SECURE*"
    end
    self:SetOverlayText(text)
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
end
