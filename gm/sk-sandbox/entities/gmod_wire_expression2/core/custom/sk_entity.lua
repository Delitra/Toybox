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

local allowedEntities = {
    -- Special NPC class
    _npc = {
        Check = function(ply, cls)
            if not hook.Call("PlayerSpawnNPC", GAMEMODE, ply, cls, "") then
                return false
            end
        end,
        Init = function(ply, ent)
            local npcData = list.Get("NPC")[ent:GetClass()]
            
            local spawnFlags = SF_NPC_FADE_CORPSE | SF_NPC_ALWAYSTHINK
            if npcData.SpawnFlags then spawnFlags = spawnFlags | npcData.SpawnFlags end
            if npcData.TotalSpawnFlags then spawnFlags = npcData.TotalSpawnFlags end
            ent:SetKeyValue("spawnflags", spawnFlags)
        end,
        PostInit = function(ply, ent)
            gamemode.Call("PlayerSpawnedNPC", ply, ent)
        end,
        UndoID = "NPC",
        CleanupID = "npcs",
    },
    
    -- Wire
    gmod_wire_expression2 = {
        SboxLimit = "wire_expressions",
        UndoID = "wire_expression2",
        CleanupID = "wire_expressions",
        Init = function(ply, ent)
            print("preparing")
            ent:Prepare(ply)
            ent:SetPlayer(ply)
            ent.player = ply
        end,
    },
    
    -- Simple stuff
    prop_physics = { SboxLimit = "props" },
    sent_ball = { },
}

------------------------------------------------------------

E2Lib.RegisterExtension("entitycore", false)

local entitySpawnRate = CreateConVar("sbox_e2_maxentitys_persecond", "30", FCVAR_ARCHIVE)

local function GetSpawnInfo(ply, cls)
    if not ValidEntity(ply) then return false end
    
    -- Spawn rate
    if not ply.EntityCoreSpawnCount then ply.EntityCoreSpawnCount = 0 end
    if ply.EntityCoreSpawnCount >= entitySpawnRate:GetInt() then return false end
    
    local info
    
    if list.Get("NPC")[cls] then
        info = allowedEntities._npc
    elseif cls ~= "_npc" and allowedEntities[cls] then
        info = allowedEntities[cls]
    else
        return false
    end
    
    -- Check sandbox limit
    if info.SboxLimit and not ply:CheckLimit(info.SboxLimit) then
        return false
    end
    
    -- Check if the user can spawn this ent
    if info.CanSpawn then
        if info.CanSpawn(ply, cls) == false then return false end
    end
    
    return info
end

local function CreateEntity(self, cls, pos, ang, mdl, freeze)
    local cls = cls:lower()
    local pos = pos or self.entity:GetPos() + self.entity:GetUp() * 25
    local ang = ang or self.entity:GetAngles()
    
    local spawnInfo = GetSpawnInfo(self.player, cls)
    if not spawnInfo then return NULL end
    
    -- Create entity
    local ent = ents.Create(cls)
    if not ValidEntity(ent) then return NULL end
    
    self.player.EntityCoreSpawnCount = self.player.EntityCoreSpawnCount + 1
    
    ent:SetPos(pos)
    ent:SetAngles(ang)
    
    -- Set model
    if mdl then
        ent:SetModel(mdl)
    end
    
    -- Perhaps this entity has special initialization code
    if spawnInfo.Init then
        local res, err = pcall(spawnInfo.Init, self.player, ent)
        
        if not res then
            ent:Remove()
            Error(err)
        end
    end
    
    -- Sbox limit count
    if spawnInfo.SboxLimit then
		self.player:AddCount(spawnInfo.SboxLimit, ent)
    end
    
    -- Undo
    if spawnInfo.UndoID then
        undo.Create(spawnInfo.UndoID)
        undo.AddEntity(ent)
        undo.SetPlayer(self.player)
        undo.Finish()
    else
        undo.Create("e2_entitycore_spawned_entity")
        undo.AddEntity(ent)
        undo.SetPlayer(self.player)
        undo.Finish()
    end
    
    -- Cleanup
    if spawnInfo.CleanupID then
        self.player:AddCleanup(spawnInfo.CleanupID, ent)
    else
        self.player:AddCleanup("props", ent) -- What the original entity core did
    end
    
    ent:Spawn()
    ent:Activate()
    
    -- Perhaps this entity has post init code
    if spawnInfo.PostInit then
        local res, err = pcall(spawnInfo.PostInit, self.player, ent)
        
        if not res then
            ent:Remove()
            Error(err)
        end
    end
    
    -- Update physics object
    local phys = ent:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
        if freeze then
            phys:EnableMotion(false)
        end
    end
    
    return ent
end

local nextResetTime = 0

hook.Add("Think", "TempResetEntityCore", function()
    if CurTime() < nextResetTime then return end
    for _, ply in pairs(player.GetHumans()) do
        ply.EntityCoreSpawnCount = 0
    end
    nextResetTime = CurTime() + 1
end)

------------------------------------------------------------

e2function entity entitySpawn(string cls, number frozen)
    return CreateEntity(self, cls, nil, nil, nil, frozen > 0)
end

e2function entity entitySpawn(string cls, string mdl, number frozen)
    return CreateEntity(self, cls, nil, nil, mdl, frozen > 0)
end

e2function entity entitySpawn(entity template, number frozen)
    if not E2Lib.validEntity(template) then return nil end
    return CreateEntity(self, template:GetClass(), nil, nil, nil, frozen > 0)
end

e2function entity entitySpawn(string cls, vector pos, number frozen)
    return CreateEntity(self, cls, Vector(pos[1], pos[2], pos[3]), nil, nil, frozen > 0)
end

e2function entity entitySpawn(string cls, vector pos, string mdl, number frozen)
    return CreateEntity(self, cls, Vector(pos[1], pos[2], pos[3]), nil, mdl, frozen > 0)
end

e2function entity entitySpawn(entity template, vector pos, number frozen)
    if not E2Lib.validEntity(template) then return nil end
    return CreateEntity(self, template:GetClass(), pos, nil, nil, frozen > 0)
end

e2function entity entitySpawn(string cls, angle ang, number frozen)
    return CreateEntity(self, cls, nil, Angle(ang[1], ang[2], ang[3]), nil, frozen > 0)
end

e2function entity entitySpawn(entity template, angle ang, number frozen)
    if not E2Lib.validEntity(template) then return nil end
    return CreateEntity(self, template:GetClass(), nil,
                        Angle(ang[1], ang[2], ang[3]), nil, frozen > 0)
end

e2function entity entitySpawn(string cls, vector pos, angle ang, number frozen)
    return CreateEntity(self, cls, Vector(pos[1], pos[2], pos[3]),
                        Angle(ang[1], ang[2], ang[3]), nil, frozen > 0)
end

e2function entity entitySpawn(string cls, vector pos, angle ang, string mdl, number frozen)
    return CreateEntity(self, cls, Vector(pos[1], pos[2], pos[3]),
                        Angle(ang[1], ang[2], ang[3]), mdl, frozen > 0)
end

e2function entity entitySpawn(entity template, vector pos, angle ang, number frozen)
    if not E2Lib.validEntity(template) then return nil end
    return CreateEntity(self, template:GetClass(), template:GetPos(),
                        Angle(ang[1], ang[2], ang[3]), nil, frozen > 0)
end

e2function void entity:setModel(string model)
	if not E2Lib.validEntity(this) then return false end
	if not E2Lib.isOwner(self, this) then return false end
    this:SetModel(model)
end