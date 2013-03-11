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

local maxParticlesPerE2 = CreateConVar("wire_expression2_skfx_particles", 10)

local blockedEffects = {
    ["ptorpedoimpact"] = true,
    ["effect_explosion_scaleable"] = true,
    ["nuke_blastwave"] = true,
    ["nuke_blastwave_cheap"] = true,
    ["nuke_disintegrate"] = true,
    ["nuke_effect_air"] = true,
    ["nuke_effect_ground"] = true,
    ["nuke_vaporize"] = true,
    ["warpcore_breach"] = true,
    ["big_fireworks_explosion"] = true,
    ["fireworks_explosion"] = true,
    ["choreo_launch_rocket_jet"] = true,
}

local blockedEffectKeywords = {
}

local blockedParticles = {
    ["choreo_launch_rocket_jet"] = true,
}

local blockedParticleKeywords = {
    "portal_rift",
    "skybox_cloud",
    "skybox_fire",
    "skybox_haze",
    "skybox_flash",
    "skybox_smoke",
}

local function IsEffectAllowed(effect)
    local effect = effect:lower()
    if blockedEffects[effect] then return false end
    for _, kw in pairs(blockedEffectKeywords) do
        if string.find(effect, kw, 1, true) then return false end
    end
    return true
end

local function IsParticleAllowed(name)
    local name = name:lower()
    if blockedParticles[name] then return false end
    for _, kw in pairs(blockedParticleKeywords) do
        if string.find(name, kw, 1, true) then return false end
    end
    return true
end

local function SpawnEffect(self, effect, pos, magn, ang, pos2, scale, effectEnt)
    if not IsEffectAllowed(effect) then return end
    
    local data = self.data.skfx
    if RealTime() - data.lastFX < 0.1 then return end
    
    -- Note: We're recreating the Vector/Angle because EffectData() is not
    -- pleased with tables masquerading as Vectors or Angles
    local fxData = EffectData()
    fxData:SetOrigin(Vector(pos.x, pos.y, pos.z))
    fxData:SetMagnitude(magn)
    if pos2 then fxData:SetStart(Vector(pos2.x, pos2.y, pos2.z)) end
    if ang then fxData:SetAngle(Angle(ang.p, ang.y, ang.r)) end
    if scale then fxData:SetScale(scale) end
    if effectEnt then fxData:SetEntity(effectEnt) end
    util.Effect(effect, fxData)
    
    data.lastFX = RealTime()
end

local function SpawnParticle(self, particle, particleEnt)
    if not IsParticleAllowed(particle) then return end
    if not particleEnt then particleEnt = self.entity end
    if not E2Lib.isOwner(self, particleEnt) then return end
    
    local data = self.data.skfx
    
    if particle == "finish" then
        if data.particles[particleEnt] then
            particleEnt:StopParticles()
            data.particles[self.entity] = false
        end
    else
        local count = 0
        
        -- Unfortunately we have to check for deleted entities
        for ent, _ in pairs(data.particles) do
            if ValidEntity(ent) then
                count = count + 1
            else
                data.particles[ent] = nil
            end
        end
        
        if count >= maxParticlesPerE2:GetInt() then return end
        
        data.particles[particleEnt] = true
        ParticleEffectAttach(particle, PATTACH_ABSORIGIN_FOLLOW, particleEnt, 0)
    end
end

registerCallback("construct", function(self)
	self.data.skfx = {
        particles = {},
        lastFX = 0,
    }
end)

registerCallback("destruct", function(self)
    local data = self.data.skfx
    
    for ent, _ in pairs(data.particles) do
        if ValidEntity(ent) then
            ent:StopParticles()
        end
    end
end)

e2function void particle(string particle)
    SpawnParticle(self, particle)
end

e2function void particle(string particle, entity ent)
    SpawnParticle(self, particle, ent)
end
                
e2function void fx(string effect, vector pos, number magnitude)
    SpawnEffect(self, effect, pos, magnitude)
end

e2function void fx(string effect, vector pos, number magnitude, angle angles)
    SpawnEffect(self, effect, pos, magnitude, angles)
end

e2function void fx(string effect, vector pos, number magnitude, angle angles,
                  vector pos2)
    SpawnEffect(self, effect, pos, magnitude, angles, pos2)
end

e2function void fx(string effect, vector pos, number magnitude, angle angles,
                   vector pos2, number scale)
    SpawnEffect(self, effect, pos, magnitude, angles, pos2, scale)
end
	
e2function void fx(string effect, vector pos, number magnitude,
                   angle angles, vector pos2, number scale, entity entity)
    SpawnEffect(self, effect, pos, magnitude, angles, pos2, scale, entity)
end
