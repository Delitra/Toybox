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

__e2setcost(10)

local function CalculateDelay(len)
    return math.Clamp(5.4 * math.log(len) - 35, 3, 20)
    --return math.Clamp(20/30000 * len, 3, 20)
end

e2function number canWriteE2()
    if not self.player.NextE2Write then self.player.NextE2Write = 0 end
    return RealTime() >= self.player.NextE2Write and 1 or 0
end

e2function number writeE2WaitTime()
    if not self.player.NextE2Write then self.player.NextE2Write = 0 end
    return math.max(self.player.NextE2Write - RealTime(), 0)
end

__e2setcost(100)

e2function void entity:writeE2(string code)
	if not E2Lib.validEntity(this) then return false end
    if this:GetClass() ~= "gmod_wire_expression2" then return end
	if not E2Lib.isOwner(self, this) then return false end
    if this.player ~= self.player then
        if this.player:GetInfoNum("wire_expression2_friendwrite") ~= 0 then
            self.player:PrintMessage(HUD_PRINTCONSOLE,
                string.format("%s is writing your E2 with writeE2()", self.player:Nick()))
        else
            self.player:PrintMessage(HUD_PRINTTALK, "Target player has wire_expression2_friendwrite off")
            return
        end
    end
    if string.len(code) > 30000 then
        self.player:PrintMessage(HUD_PRINTTALK, "Code larger than 30000 bytes!")
        return
    end
    if not self.player.NextE2Write then self.player.NextE2Write = 0 end
    if RealTime() < self.player.NextE2Write then return end
    self.player.NextE2Write = RealTime() + CalculateDelay(string.len(code))
    this:Setup(code)
end