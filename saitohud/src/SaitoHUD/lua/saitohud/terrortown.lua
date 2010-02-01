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

local witnessesOnDeath = CreateClientConVar("ttt_witnesses_death", "0", true, false)

function SaitoHUD.GetListOfWitnesses()
    local originPos = LocalPlayer():GetPos()
    local witnesses = {}
    
    for _, ply in pairs(player.GetAll()) do
        if ply != LocalPlayer() and ply:Alive() and ply:Team() == 1 then            
            local points = {
                {Vector(0, 0, 0), Vector(0, 0, 30)},
                {Vector(0, 0, 30), Vector(0, 0, 30)},
                {Vector(0, 0, 40), Vector(0, 0, 40)},
                {Vector(0, -10, 40), Vector(0, 0, 40)},
                {Vector(0, 10, 40), Vector(0, 0, 40)},
                {Vector(0, -10, 40), Vector(0, -10, 40)},
                {Vector(0, 10, 40), Vector(0, 10, 40)},
            }
            
            for _, p in pairs(points) do
                local data = {}
                data.start = originPos + p[1]
                data.endpos = ply:GetPos() + p[2]
                data.filter = {}
                for _, ply2 in pairs(player.GetAll()) do
                    if ply2 ~= ply then
                        table.insert(data.filter, ply2)
                    end
                end
                
                local tr = util.TraceLine(data)
                if ValidEntity(tr.Entity) and tr.Entity == ply and 
                    tr.HitPos:Distance(LocalPlayer():GetPos()) < 4000 then
                    table.insert(witnesses, ply:GetName())
                    break
                end
            end
        end
    end
    
    return witnesses
end

function SayWitnesses()
    local witnesses = SaitoHUD.GetListOfWitnesses()
    
    if #witnesses == 1 then
        RunConsoleCommand("say", "I am with " .. witnesses[1])
    elseif #witnesses > 1 then
        RunConsoleCommand("say", "I am with " .. table.concat(witnesses, ", "))
    end
end
 
concommand.Add("ttt_say_witnesses", function(ply, cmd, args)
    SayWitnesses()
end)

local lastChat = ""

hook.Add("ChatTextChanged", "SaitoHUDTTTChatTextChanged", function(text)
   lastChat = text
end)

function ChatInterrupt(um)
    local ply = LocalPlayer()
    local id = um:ReadLong()
    local witnesses = SaitoHUD.GetListOfWitnesses()
    local lastSeen = IsValid(ply.last_id) and ply.last_id:EntIndex() or 0
    local lastWords = "."

    if #witnesses == 1 and witnessesOnDeath:GetBool() then
        lastWords = "I am with " .. witnesses[1]
    elseif #witnesses > 1 and witnessesOnDeath:GetBool() then
        lastWords = "I am with " .. table.concat(witnesses, ", ")
    else
        lastWords = (lastChat == "") and "." or lastChat
    end

    RunConsoleCommand("_deathrec", tostring(id), tostring(lastSeen), lastWords)
end

local function SetUp()
    usermessage.Hook("interrupt_chat", ChatInterrupt)
    timer.Simple(3, function()
        usermessage.Hook("interrupt_chat", ChatInterrupt)
    end)
end

hook.Add("Initialize", "SaitoHUD.TerrorTown.Initialize", SetUp)
SetUp()