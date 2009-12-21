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

TOOL.Category		= "Wire - Render"
TOOL.Name			= "Light Cone"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if CLIENT then
    language.Add("Tool_wire_light_cone_name", "Light Cone (Wire)")
    language.Add("Tool_wire_light_cone_desc", "Spawns a light cone.")
    language.Add("Tool_wire_light_cone_0", "Primary: Create/Update light cone")
	language.Add("SBoxLimit_wire_light_cones", "Wired light cone limit reached!")
	language.Add("Undone_wire_light_cone", "Undone Wire Light Cone")
	language.Add("Cleanup_wire_light_cones", "Wire Light Cones")
	language.Add("Cleaned_wire_light_cones", "Cleaned up all Wire Light Cones")
end

if SERVER then
	CreateConVar("sbox_maxwire_light_cones", 40)
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register("wire_light_cones")

function TOOL:LeftClick(trace)
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
    
	local ply = self:GetOwner()
	
    -- Update an existing entity
	if trace.Entity:IsValid() && trace.Entity.pl == ply && 
       trace.Entity:GetClass() == "gmod_wire_light_cone" then
		trace.Entity:Setup()
		return true
	end
	
    -- Check the limit
	if !self:GetSWEP():CheckLimit("wire_light_cones") then
        return false
    end
    
	local model = self:GetClientInfo("model")
	
    -- Valid model?
	if not util.IsValidModel(model) then return false end
	if not util.IsValidProp(model) then return false end -- Ragdolls
	
    -- Re-orient the ghost
	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	local ent = MakeWireLightCone(ply, trace.HitPos, ang, model)
    if !ent then return end
	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	local const = WireLib.Weld(ent, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("wire_light_cone")
    undo.AddEntity(ent)
    undo.AddEntity(const)
    undo.SetPlayer(ply)
	undo.Finish()
	
	return true
end

if SERVER then
	function MakeWireLightCone(pl, pos, ang, model)
		if !pl:CheckLimit("wire_light_cones") then return false end

		local ent = ents.Create("gmod_wire_light_cone")
		if (!ent:IsValid()) then return false end

		ent:SetAngles(ang)
		ent:SetPos(pos)
		ent:SetModel(model)
		ent:Spawn()
		ent:SetPlayer(pl)
		ent:Setup()

		table.Merge(ent:GetTable(), {
			pl = pl,
		})

		pl:AddCount("wire_light_cones", ent)
		pl:AddCleanup("wire_light_cones", ent)

		return ent
	end

	duplicator.RegisterEntityClass("gmod_wire_light_cone",
                                   MakeWireLightCone,
                                   "Pos", "Ang", "Model")
end

function TOOL:UpdateGhostWireLightCone(ent, ply)
	if !ent then return end
	if !ent:IsValid() then return end

	local tr = utilx.GetPlayerTrace(ply, ply:GetCursorAimVector())
	local trace = util.TraceLine(tr)
	if !trace.Hit then return end

    -- There are some objects where we don't show the ghost on
	if !trace.Hit || trace.Entity:IsPlayer() || trace.Entity &&
       trace.Entity:GetClass() == "gmod_wire_light_cone" then
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

	self:UpdateGhostWireLightCone(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", {
        Text = "#Tool_wire_light_cone_name",
        Description = "#Tool_wire_light_cone_desc"
    })
    
    -- Watch Tengen Toppa Gurren Lagann & Peacemaker Kurogane!
end
