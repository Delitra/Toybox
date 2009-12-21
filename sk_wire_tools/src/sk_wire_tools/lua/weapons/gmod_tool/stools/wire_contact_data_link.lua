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

TOOL.Category		= "Wire - Data"
TOOL.Name			= "Contact Data Link"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if CLIENT then
    language.Add("Tool_wire_contact_data_link_name", "Contact Data Link (Wire)")
    language.Add("Tool_wire_contact_data_link_desc", "Spawns a contact data link.")
    language.Add("Tool_wire_contact_data_link_0", "Primary: Create/Update Contact Data Link")
    language.Add("Wire_contact_data_link_secure_input", "Secure input")
	language.Add("SBoxLimit_wire_contact_data_links", "Contact data link limit reached!")
	language.Add("Undone_wire_contact_data_link", "Undone Wire Contact Data Link")
	language.Add("Cleanup_wire_contact_data_links", "Wire Contact Data Links")
	language.Add("Cleaned_wire_contact_data_links", "Cleaned up all Wire Contact Data Links")
end

if SERVER then
	CreateConVar("sbox_maxwire_contact_data_links", 40)
end

TOOL.ClientConVar = {
	model = "models/hunter/plates/plate075x075.mdl",
    secure_input = "0",
    type_a = "",
    type_b = "",
    type_c = "",
    type_d = "",
    type_e = "",
    type_f = "",
    type_g = "",
    type_h = ""
}

TOOL.Model = "models/hunter/plates/plate075x075.mdl"

cleanup.Register("wire_contact_data_links")

function TOOL:LeftClick(trace)
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
    
    -- Get types
    types = {}
	for i = 1, 8 do
		types[string.char(64 + i)] = self:GetClientInfo("type_" .. string.char(96 + i))
	end
    
    -- Settings
	local secureInput = self:GetClientNumber("secure_input", "0")
	
	local ply = self:GetOwner()
	
    -- Update an existing entity
	if trace.Entity:IsValid() && trace.Entity.pl == ply && 
       trace.Entity:GetClass() == "gmod_wire_contact_data_link" then
		trace.Entity:Setup(types, secureInput)
		return true
	end
	
    -- Check the limit
	if !self:GetSWEP():CheckLimit("wire_contact_data_links") then
        return false
    end
    
	local model = self:GetClientInfo("model")
	
    -- Valid model?
	if not util.IsValidModel(model) then return false end
	if not util.IsValidProp(model) then return false end -- Ragdolls
	
    -- Re-orient the ghost
	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	local ent = MakeWireContactDataLink(ply, trace.HitPos, ang, model, types, secureInput)
    if !ent then return end
	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	local const = WireLib.Weld(ent, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("wire_contact_data_link")
    undo.AddEntity(ent)
    undo.AddEntity(const)
    undo.SetPlayer(ply)
	undo.Finish()
	
	return true
end

if SERVER then
	function MakeWireContactDataLink(pl, pos, ang, model, types, secureInput)
		if !pl:CheckLimit("wire_contact_data_links") then return false end

		local ent = ents.Create("gmod_wire_contact_data_link")
		if (!ent:IsValid()) then return false end

		ent:SetAngles(ang)
		ent:SetPos(pos)
		ent:SetModel(model)
		ent:Spawn()
		ent:SetPlayer(pl)
		ent:Setup(types, secureInput != 0)

		table.Merge(ent:GetTable(), {
			pl = pl,
            Types = types,
            SecureInput = secureInput != 0
		})

		pl:AddCount("wire_contact_data_links", ent)
		pl:AddCleanup("wire_contact_data_links", ent)

		return ent
	end

	duplicator.RegisterEntityClass("gmod_wire_contact_data_link",
                                   MakeWireContactDataLink,
                                   "Pos", "Ang", "Model", "Types", "SecureInput")
end

function TOOL:UpdateGhostWireContactDataLink(ent, ply)
	if !ent then return end
	if !ent:IsValid() then return end

	local tr = utilx.GetPlayerTrace(ply, ply:GetCursorAimVector())
	local trace = util.TraceLine(tr)
	if !trace.Hit then return end

    -- There are some objects where we don't show the ghost on
	if !trace.Hit || trace.Entity:IsPlayer() || trace.Entity &&
       trace.Entity:GetClass() == "gmod_wire_contact_data_link" then
		ent:SetNoDraw(true)
		return
	end

    -- Re-orient the ghost
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	ent:SetAngles(Ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	if !self.GhostEntity || !self.GhostEntity:IsValid() || 
       self.GhostEntity:GetModel() != self:GetClientInfo("model") then
		self:MakeGhostEntity(self:GetClientInfo("model"), Vector(0, 0, 0), Angle(0, 0, 0))
	end

	self:UpdateGhostWireContactDataLink(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", {
        Text = "#Tool_wire_contact_data_link_name",
        Description = "#Tool_wire_contact_data_link_desc"
    })
    
	for i = 1, 8 do
		panel:AddControl("TextBox", {
			Label = "Type of " .. string.char(64 + i) .. ":",
			Text = "",
			Command = "wire_contact_data_link_type_" .. string.char(96 + i),
			WaitForEnter = true,
		})
	end
	
	panel:AddControl("CheckBox", {
		Label = "#Wire_contact_data_link_secure_input",
		Command = "wire_contact_data_link_secure_input"
	})
end
