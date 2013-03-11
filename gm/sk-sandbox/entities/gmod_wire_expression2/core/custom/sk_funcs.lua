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

__e2setcost(20)

e2function number maxVelocity()
    return physenv.GetPerformanceSettings().MaxVelocity
end

e2function number maxAngularVelocity()
    return physenv.GetPerformanceSettings().MaxAngularVelocity
end

e2function number crc32(string str)
    if string.len(str) > 1024 * 100 then return 0 end
    return tonumber(util.CRC(str))
end

-- http://wiki.garrysmod.com/?title=Util.PointContents
e2function number pointContents(vector pos)
    return util.PointContents(Vector(pos.x, pos.y, pos.z))
end

e2function number entity:inWorld()
	if not E2Lib.validEntity(this) then return 0 end
    return this:IsInWorld() and 1 or 0
end

e2function number entity:onGround()
	if not E2Lib.validEntity(this) then return 0 end
    return this:OnGround() and 1 or 0
end

e2function void entity:setDrag(number enable)
	if not E2Lib.validEntity(this) then return end
    if not E2Lib.isOwner(self, this) then return end
    local physObj = this:GetPhysicsObject()
    if not physObj:IsValid() then return end
    physObj:EnableDrag(enable == 1 and 1 or 0)
end

e2function number entity:linearDamping()
	if not E2Lib.validEntity(this) then return 0 end
    local physObj = this:GetPhysicsObject()
    if not physObj:IsValid() then return 0 end
    local l, a = physObj:GetDamping()
    return l
end

e2function number entity:angularDamping()
	if not E2Lib.validEntity(this) then return 0 end
    local physObj = this:GetPhysicsObject()
    if not physObj:IsValid() then return 0 end
    local l, a = physObj:GetDamping()
    return a
end

e2function void entity:setDamping(number linear, number angular)
	if not E2Lib.validEntity(this) then return end
    if not E2Lib.isOwner(self, this) then return end
    local physObj = this:GetPhysicsObject()
    if not physObj:IsValid() then return end
    physObj:SetDamping(math.Clamp(linear, 0, 5000), math.Clamp(angular, 0, 5000))
end

e2function number entity:isPenetrating()
	if not E2Lib.validEntity(this) then return 0 end
    local physObj = this:GetPhysicsObject()
    if not physObj:IsValid() then return 0 end
    return physObj:IsPenetrating() and 1 or 0
end

e2function void entity:propSleep()
	if not E2Lib.validEntity(this) then return end
    if not E2Lib.isOwner(self, this) then return end
    local physObj = this:GetPhysicsObject()
    if not physObj:IsValid() then return end
    physObj:Sleep()
end

e2function void entity:setGravityMult(number gravity)
	if not E2Lib.validEntity(this) then return end
    if not E2Lib.isOwner(self, this) then return end
    this:SetGravity(math.Clamp(gravity, 0, 10))
end

e2function number entity:poseParam(string name)
	if not E2Lib.validEntity(this) then return 0 end
    if not E2Lib.isOwner(self, this) then return 0 end
    if name == "" then return end
    return this:GetPoseParameter(name)
end

e2function void entity:setPoseParam(string name, number value)
	if not E2Lib.validEntity(this) then return end
    if not E2Lib.isOwner(self, this) then return end
    if name == "" then return end
    this:SetPoseParameter(name, value)
end

e2function number entity:isFlashlightOn()
	if not E2Lib.validEntity(this) then return end
    if not this:IsPlayer() then return 0 end
    return this:FlashlightIsOn() and 1 or 0
end

e2function string toAnyChar(number n)
	if n < 0 then return "" end
	if n > 255 then return "" end
	return string.char(n)
end

local function BitShiftR(a, b)
    RunString(string.format("garry_sucks = %d >> %d", a, b))
    return garry_sucks
end

e2function string pack(string fmt, ...)
    local args = {...}
    local argi = 1
    local out = ""
    
    for i = 1, string.len(fmt) do
        local f = fmt:sub(i, i)
        local arg = args[argi]
        if not arg then arg = "" end
        argi = argi + 1
        
        if f == "a" then
            out = out .. arg .. string.char(0)
        elseif f == "A" then
            out = out .. arg .. " "
        elseif f == "C" or f == "c" then
            out = string.char(string.Clamp(tonumber(arg), 0, 255))
        elseif f == "n" then
            arg = tonumber(arg) or 0
            out = out .. string.char(BitShiftR(arg, 8) & 255) .. string.char(arg & 255)
        elseif f == "v" then
            arg = tonumber(arg) or 0
            out = out .. string.char(arg & 255) .. string.char(BitShiftR(arg, 8) & 255)
        elseif f == "N" then
            arg = tonumber(arg) or 0
            local a = BitShiftR(arg, 24) & 255
            local b = BitShiftR(arg, 16) & 255
            local c = BitShiftR(arg, 8) & 255
            local d = arg & 255
            out = out .. string.char(a) ..
                string.char(b) ..
                string.char(c) ..
                string.char(d)
        elseif f == "V" then
            arg = tonumber(arg) or 0
            local a = arg & 255
            local b = BitShiftR(arg, 8) & 255
            local c = BitShiftR(arg, 16) & 255
            local d = BitShiftR(arg, 24) & 255
            out = out .. string.char(a) ..
                string.char(b) ..
                string.char(c) ..
                string.char(d)
        elseif f == "x" then
            out = out .. string.char(0)
            argi = argi - 1
        else
            return "UNKNOWN FORMAT: " .. f
        end
    end
    
    return out
end