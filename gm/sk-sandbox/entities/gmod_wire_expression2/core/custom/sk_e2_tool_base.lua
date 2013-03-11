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

local ranger
local clk = 0
local event
local run = 0
local walk = 0

function _R.Player.E2ToolBaseExec(self, evt, tr)
    if not self.E2ToolBaseE2s then return end
    
    for v, _ in pairs(self.E2ToolBaseE2s) do
        if ValidEntity(v) then
            tr.RealStartPos = self:GetShootPos()
            ranger = tr
            event = evt
            clk = 1
            run = self:KeyDown(IN_SPEED) and 1 or 0
            walk = self:KeyDown(IN_WALK) and 1 or 0
            
            v:Execute()
            
            ranger = nil
            event = nil
            clk = 0
            run = 0
            walk = 0
        end
    end
end

registerCallback("destruct", function(self)
	if self.player.E2ToolBaseE2s then
        self.player.E2ToolBaseE2s[self.entity] = nil
    end
end)

e2function ranger runOnTool(number a)
    if not self.player.E2ToolBaseE2s then
        self.player.E2ToolBaseE2s = {}
    end
    if a ~= 0 then
        self.player.E2ToolBaseE2s[self.entity] = true
    else
        self.player.E2ToolBaseE2s[self.entity] = nil
    end
end

e2function ranger toolRanger()
    return ranger
end

e2function number toolClk(string evt)
    return event == evt and 1 or 0
end

e2function number toolClk()
    return clk
end

e2function string toolEvent()
    return event
end

e2function ranger toolShift()
    return run
end

e2function ranger toolAlt()
    return walk
end