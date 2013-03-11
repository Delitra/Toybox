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

require("cryptopp")

__e2setcost(30)

e2function string md5(string s)
    if not crypto then return "<< module is missing >>" end
    if string.len(s) > 1024 * 5 then return "<< string length > 1024 * 5 >>" end
    return crypto.md5(s):lower()
end

e2function string sha1(string s)
    if not crypto then return "<< module is missing >>" end
    if string.len(s) > 1024 * 5 then return "<< string length > 1024 * 5 >>" end
    return crypto.sha1(s):lower()
end

e2function string sha256(string s)
    if not crypto then return "<< module is missing >>" end
    if string.len(s) > 1024 * 5 then return "<< string length > 1024 * 5 >>" end
    return crypto.sha256(s):lower()
end