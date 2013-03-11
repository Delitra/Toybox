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

if not ASWaterPos then
    ASWaterPos = Vector(-335.2284, -311.6622, -142.2241)
    ASForagePos = Vector(735.5820, -1550.5349, 64.0000)
    ASSleepPos = Vector(692.8872, -1953.6716, 64.0000)
    ASDropOffPos = Vector(1068.5643, -1121.7338, 97.1510)
    ASMinePos = Vector(1288.8809, -238.0821, 134.190)
    ASPlantPosBase = Vector(729.1457, -1593.3904, 64.0000)
end

local foodModels = {
    ['models/props/cs_italy/orange.mdl'] = true,
    ['models/props_junk/watermelon01.mdl'] = true,
    ['models/props/cs_italy/bananna_bunch.mdl'] = true,
}
local plantIDs = {
    ["Melon_Seeds"] = "melon",
    --["Orange_Seeds"] = "orange",
    --["Banana_Seeds"] = "banana",
}

local MODE_ACT = "ACT"
local MODE_DRINK = "DRINK"
local MODE_EAT = "EAT"
local MODE_SLEEP = "SLEEP"
local MODE_DROP_OFF = "DROP_OFF"

local ACT_FORAGE = "FORAGE"
local ACT_MINE = "MINE"
local ACT_FIND_FOOD = "FIND_FOOD"
local ACT_PLANT = "PLANT"

local mode = MODE_ACT
local secondaryMode = MODE_ACT
local defaultAct = ACT_MINE
local activity = ACT_MINE
local jumpCmd = false
local useCmd = false
local attackCmd = false
local eatEnt = nil
local startedSleeping = false
local startedEating = false
local lastDropOff = 0
local maxSeeds = 6
local maxPlants = 5
local plantPos = 0
local plantTime = -1
local startedPlanting = false

local function ShowMessage(msg)
    chat.AddText(Color(255, 200, 200), "[AS] " .. msg)
end

local function NumTotalResources()
    local total = 0
    for res, num in pairs(Resources) do
        total = total + num
    end
    return total
end

local function NumSeeds()
    local total = 0
    for res, num in pairs(Resources) do
        if plantIDs[res] then
            total = total + num
        end
    end
    return total
end

local function OverResourceQuota()
    return (NumTotalResources() - NumSeeds()) > 0.8 * MaxResources
end

local function NeedPlants()
    return LocalPlayer():GetNWInt("plants") < maxPlants
end

local function IsPlantNearby(pos)
    local objs = ents.FindInSphere(pos, 70)
    for _, obj in pairs(objs) do
        if obj:GetClass() == "prop_physics" or obj:GetClass() == "gms_seed" then
            return true
        end
    end
    
    return false
end

local function FindEatEntity()
    local selfPos = LocalPlayer():GetPos()
    local acceptable = {}
    
    for _, ent in pairs(ents.GetAll()) do
        if foodModels[ent:GetModel()] then
            table.insert(acceptable, ent)
        end
    end
    
    table.sort(acceptable, function(a, b)
        return a:GetPos():Distance(ASPlantPosBase) < b:GetPos():Distance(ASPlantPosBase)
    end)
    
    if #acceptable > 0 then
        return acceptable[1]
    end
end

local function IsInWater(pos)
	local trace = {}
	trace.start = pos
	trace.endpos = pos + Vector(0,0,1)
	trace.mask = MASK_WATER | MASK_SOLID

	local tr = util.TraceLine(trace)

	return tr.Hit
end

local function FindPlantPos()
    local basePos = ASPlantPosBase + Vector(0, 0, 100)
    
    for x = -2, 4 do
        for y = -2, 2 do
            pos = basePos + Vector(70 * x, 70 * y, 0)
            
            local data = {}
            data.start = pos
            data.endpos = pos - Vector(0, 0, 300)
            data.filter = LocalPlayer()
            local tr = util.TraceLine(data)
            if tr.Hit and (tr.MatType == MAT_DIRT or tr.MatType == MAT_GRASS or tr.MatType == MAT_SAND) 
                and not IsInWater(tr.HitPos) and not IsPlantNearby(tr.HitPos) then
                return tr.HitPos
            end
        end
    end
    
    return ASPlantPosBase -- Fail?
end

local function PlantAnything()
    for id, cmd in pairs(plantIDs) do
        if Resources[id] and Resources[id] > 0 then
            RunConsoleCommand("say", "!" .. cmd)
            return true
        end
    end
    
    return false
end

local function Eat()
    ShowMessage("Eating...")
    mode = MODE_EAT
    eatEnt = FindEatEntity()
    startedEating = false
end

local function Sleep()
    ShowMessage("Sleeping...")
    mode = MODE_SLEEP
    startedSleeping = false
end

local function DropOff()
    ShowMessage("Dropping off...")
    mode = MODE_DROP_OFF
end

local function FindFood()
    ShowMessage("Need to find food")
    activity = ACT_FIND_FOOD
end

local function Plant()
    activity = ACT_PLANT
    plantPos = FindPlantPos()
    ShowMessage("Planting new plant at " .. tostring(plantPos))
    startedPlanting = false
    plantTime = -1
end

local function EnsureFoodSupply()
    if NumSeeds() >= maxSeeds and NeedPlants() then
        Plant()
        return true
    elseif NeedPlants() then
        FindFood()
        return true
    else
        return false
    end
end

local function MoveTo(usercmd, pos, isEyeLevel, highError)
    local ply = LocalPlayer()
    if isEyeLevel then
        distance = ply:GetShootPos():Distance(pos)
    else
        distance = math.min(ply:GetShootPos():Distance(pos), ply:GetPos():Distance(pos))
    end
    
    if distance < (highError and 200 or (isEyeLevel and 60 or 40)) then
        return true
    else
        local ang = (pos - ply:GetShootPos()):Angle()
        if ply:WaterLevel() > 0 then ang.p = -10 end
        usercmd:SetViewAngles(ang)
        usercmd:SetForwardMove(math.Clamp(distance * 2, 10, 1000))
    end
end

local function CreateMove(usercmd)
    local ply = LocalPlayer()
    local pos = ply:GetShootPos()
    
    -- if not LocalPlayer():Alive() then
        -- if attackCmd then usercmd:SetButtons(usercmd:GetButtons() | IN_ATTACK) end
        -- attackCmd = not attackCmd
        -- if jumpCmd then usercmd:SetButtons(usercmd:GetButtons() | IN_JUMP) end
        -- jumpCmd = not jumpCmd
        -- return
    -- end
    
    if mode == MODE_DRINK then
        if ply:GetPos():Distance(ASWaterPos) < 100 then
            -- Need to not drown
            if jumpCmd then usercmd:SetButtons(usercmd:GetButtons() | IN_JUMP) end
            jumpCmd = not jumpCmd
            -- Need to eat
            if useCmd then usercmd:SetButtons(IN_USE) else usercmd:SetButtons(0) end
            useCmd = not useCmd
            
            local ang = (ASWaterPos - pos):Angle()
            ang.p = 60
            usercmd:SetViewAngles(ang)
            usercmd:SetForwardMove(100)
            
            if Thirst > 900 then
                mode = MODE_ACT
            end
        else
            local ang = (ASWaterPos - pos):Angle()
            if ply:WaterLevel() > 0 then ang.p = -10 end
            usercmd:SetViewAngles(ang)
            usercmd:SetForwardMove(1000)
        end
    elseif mode == MODE_EAT then
        if ValidEntity(eatEnt) and not startedEating then
            if ply:IsFrozen() then
                startedEating = true
            else
                local targetPos = eatEnt:GetPos()
                local ang = (targetPos - pos):Angle()
                if ply:WaterLevel() > 0 then ang.p = -10 end
                usercmd:SetViewAngles(ang)
                
                if MoveTo(usercmd, targetPos) then
                    -- Need to not down
                    if jumpCmd and ply:WaterLevel() > 0 then usercmd:SetButtons(usercmd:GetButtons() | IN_JUMP) end
                    jumpCmd = not jumpCmd
                    -- Need to eat
                    if useCmd then usercmd:SetButtons(IN_USE) else usercmd:SetButtons(0) end
                    useCmd = not useCmd
                    usercmd:SetForwardMove(100)
                end
            end
        elseif not ply:IsFrozen() then
            if Hunger < 900 then
                Eat()
            else
                mode = MODE_ACT
            end
        end
    elseif mode == MODE_SLEEP then      
        if not startedSleeping or SleepFade == 255 then
            if MoveTo(usercmd, ASSleepPos) then
                RunConsoleCommand("say", "!sleep")
                startedSleeping = true
            end
        else
            mode = MODE_ACT
        end
    elseif mode == MODE_DROP_OFF then
        if NumTotalResources() - NumSeeds() ~= 0 then
            if MoveTo(usercmd, ASDropOffPos, false, true) then
                if CurTime() - lastDropOff >= 1 then
                    for res, num in pairs(Resources) do
                        if num > 0 and not plantIDs[res] then
                            RunConsoleCommand("say", "!drop " .. res:gsub(" ", "_"))
                            lastDropOff = CurTime()
                            break
                        elseif num > 0 and NumSeeds() > maxSeeds then
                            RunConsoleCommand("say", "!drop " .. 
                                res:gsub(" ", "_") .. " " ..
                                tostring(NumSeeds() - maxSeeds))
                            lastDropOff = CurTime()
                        end
                    end
                end
                
                usercmd:SetViewAngles(Angle(-20, 0, 0))
            end
        else
            mode = MODE_ACT
        end
    elseif mode == MODE_ACT then        
        if activity == ACT_FORAGE or activity == ACT_FIND_FOOD then
            if MoveTo(usercmd, ASForagePos) then
                if useCmd then usercmd:SetButtons(usercmd:GetButtons() | IN_USE) end
                useCmd = not useCmd
                usercmd:SetViewAngles(Angle(89, 0, 0))
            end
            
            if activity == ACT_FIND_FOOD and NumSeeds() >= maxSeeds then
                if not EnsureFoodSupply() then
                    activity = defaultAct
                end
            end
        elseif activity == ACT_MINE then
            if MoveTo(usercmd, ASMinePos, true) then
                if attackCmd then usercmd:SetButtons(usercmd:GetButtons() | IN_ATTACK) end
                attackCmd = not attackCmd
                
                local ang = (ASMinePos - pos):Angle()
                usercmd:SetViewAngles(ang)
            end
        elseif activity == ACT_PLANT then
            if not startedPlanting then
                if ply:IsFrozen() then
                    ShowMessage("Planting seed...")
                    startedPlanting = true
                else
                    if MoveTo(usercmd, plantPos) then
                        if plantTime == -1 then
                            plantTime = 0
                        elseif CurTime() - plantTime > 2 then
                            if not PlantAnything() then
                                if not EnsureFoodSupply() then
                                    activity = defaultAct
                                end
                            end
                            plantTime = CurTime()
                        end
                        
                        usercmd:SetViewAngles(Angle(89, 0, 0))
                    end
                end
            elseif not ply:IsFrozen() then
                ShowMessage("Done planting!")
                if NeedPlants() then
                    EnsureFoodSupply()
                else
                    activity = defaultAct
                end
            end
        end
    end
end

local function CheckState()
    if LocalPlayer():Alive() and LocalPlayer():Health() <= 0 then
        RunConsoleCommand("kill")
        return
    end
    
    if mode > MODE_ACT and mode <= MODE_SLEEP then return end
    if Thirst < 400 then
        secondaryMode = mode
        mode = MODE_DRINK
    elseif Hunger < 400 then
        secondaryMode = mode
        Eat()
    elseif Sleepiness < 400 then
        secondaryMode = mode
        Sleep()
    elseif OverResourceQuota() then
        if mode ~= MODE_DROP_OFF then DropOff() end
    elseif NeedPlants() then
        if activity ~= ACT_FIND_FOOD and activity ~= ACT_PLANT then EnsureFoodSupply() end
    end
end

local function SetLoc(ply, cmd, args)
    local pos = LocalPlayer():GetEyeTrace().HitPos
    local id = args[1] and args[1]:Trim():lower() or ""
    
    if id == "water" then
        ASWaterPos = pos
        ShowMessage("Water pos:" .. tostring(pos))
    elseif id == "forage" then
        ASForagePos = pos
        ShowMessage("Forage pos:" .. tostring(pos))
    elseif id == "sleep" then
        ASSleepPos = pos
        ShowMessage("Sleep pos:" .. tostring(pos))
    elseif id == "dropoff" then
        ASDropOffPos = pos
        ShowMessage("Drop off pos:" .. tostring(pos))
    elseif id == "mine" then
        ASMinePos = pos
        ShowMessage("Mine pos:" .. tostring(pos))
    elseif id == "plant" then
        ASPlantPosBase = pos
        ShowMessage("Planting pos:" .. tostring(pos))
    else
        ShowMessage("Unknown ID")
    end
end

local function DrawLoc(pos, text, c)
    local pos = pos:ToScreen()
    surface.SetDrawColor(c.r, c.g, c.b, c.a)
    surface.DrawLine(pos.x - 5, pos.y - 5,
                     pos.x + 5, pos.y + 5)
    surface.DrawLine(pos.x - 5, pos.y + 5,
                     pos.x + 5, pos.y - 5)
    draw.SimpleText(text, "DefaultSmallDropShadow", pos.x, pos.y,
        c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function HUDPaint()    
    DrawLoc(ASWaterPos, "water", Color(0, 255, 255, 255))
    DrawLoc(ASForagePos, "forage", Color(0, 255, 0, 255))
    DrawLoc(ASSleepPos, "sleep", Color(255, 255, 0, 255))
    DrawLoc(ASMinePos, "mine", Color(255, 0, 0, 255))
    DrawLoc(ASPlantPosBase, "plant", Color(255, 0, 0, 255))
    DrawLoc(ASDropOffPos, "dropoff", Color(255, 255, 255, 255))
    
    local lines = {
        "Mode: " .. mode,
        "Act: " .. activity,
    }
    for k, line in pairs(lines) do
        draw.SimpleText(line, "TabLarge", ScrW() - 150, 20 + 13 * k,
            Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end

local function Start()
    hook.Add("CreateMove", "AutoStranded", CreateMove)
    timer.Create("AutoStrandedState", 1, 0, CheckState)
    CheckState()
end

local function Stop()
    hook.Remove("CreateMove", "AutoStranded")
    timer.Destroy("AutoStrandedState")
end

defaultAct = ACT_MINE
activity = defaultAct

hook.Add("HUDPaint", "AutoStranded", HUDPaint)
concommand.Add("as_set", SetLoc)
concommand.Add("as_start", function() Start() end)
concommand.Add("as_stop", function() Stop() end)
Start()