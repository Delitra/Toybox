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

local fileMaxSize = 1024 * 50
local fileMaxNumber = 40
local allowedExts = {"txt", "html", "bmp", "wav"}

if not file.Exists("stramwebspace") then
    file.CreateDir("stramwebspace")
end

local function GetDir(ply)
    local id = ply:SteamID()
    return "stramwebspace/" .. id:gsub("[^A-Za-z0-9]", "_")
end

local function GetFileCount(ply)
    local dir = GetDir(ply)
    local files = file.Find(dir .. "/*.txt")
    local total = 0
    for _, f in pairs(files) do
        total = total + 1
    end
    ply.WebspaceFileCount = total
    return total
end

local function CleanFilename(filename)
    local name, ext = string.match(filename, "^(.+)%.([^%.]+)$")
    if not name then return nil end
    local cleaned = name:gsub("[^A-Za-z0-9_%-]", ""):sub(1, 30)
    if cleaned ~= name then return end
    return cleaned, ext:lower()
end

__e2setcost(20)

e2function array webspaceAllowedExts()
    return table.Copy(allowedExts)
end

e2function string webspaceURL()
    return "Currently unavilable"
end

e2function number webspaceMaxFileSize()
    return fileMaxSize
end

e2function number webspaceMaxFileCount()
    return fileMaxNumber
end

__e2setcost(40)

e2function array webspaceFilesList()
    local dir = GetDir(self.player)
    local files = file.Find(dir .. "/*.txt")
    for k, v in pairs(files) do
        files[k] = v:gsub("_([^_%.]+)%.txt$", ".%1")
    end
    return files
end

__e2setcost(50)

e2function number webspaceWrite(string filename, string content)
    if self.player.WebspaceLastWrite and RealTime() - self.player.WebspaceLastWrite < 0.5 then
        return 0
    end
    
    local size = string.len(content)
    local name, ext = CleanFilename(filename:Trim())
    if not name then return 0 end
    if not table.HasValue(allowedExts, ext) then return 0 end
    if size > fileMaxSize then return 0 end
    
    local dir = GetDir(self.player)
    local path = dir .. "/" .. name .. "_" .. ext .. ".txt"
    local numFiles = GetFileCount(self.player)
    if not file.Exists(path) then numFiles = numFiles + 1 end
    if numFiles > fileMaxNumber then return 0 end
    
    if not file.Exists(dir) then file.CreateDir(dir) end
    
    file.Write(path, content)
    
    self.player.WebspaceLastWrite = RealTime()
    
    return 1
end

e2function number webspaceDelete(string filename)
    local name, ext = CleanFilename(filename:Trim())
    if not name then return 0 end
    if not table.HasValue(allowedExts, ext) then return 0 end
    
    local dir = GetDir(self.player)
    local path = dir .. "/" .. name .. "_" .. ext .. ".txt"
    
    file.Delete(path)
    
    return 1
end

e2function string webspaceRead(string filename)
    local name, ext = CleanFilename(filename:Trim())
    if not name then return "" end
    if not table.HasValue(allowedExts, ext) then return "" end
    
    local dir = GetDir(self.player)
    local path = dir .. "/" .. name .. "_" .. ext .. ".txt"
    
    return file.Read(path) or ""
end