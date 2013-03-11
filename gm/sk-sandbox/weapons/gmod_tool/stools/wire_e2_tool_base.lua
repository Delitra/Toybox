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

TOOL.Category = "Wire - Tools"
TOOL.Name = "E2 Tool Base"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.Tab = "Wire"

if CLIENT then
    language.Add("Tool_wire_e2_tool_base_name", "E2 Tool Base")
    language.Add("Tool_wire_e2_tool_base_desc", "E2-powered tool.")
    language.Add("Tool_wire_e2_tool_base_0", "Press F1, go to the Knowledge Base, and read about the E2 tool base.")
end

if SERVER then
    function TOOL:RightClick(tr)
        self:GetOwner():E2ToolBaseExec("right", tr)
        return true
    end
    
    function TOOL:LeftClick(tr)
        self:GetOwner():E2ToolBaseExec("left", tr)
        return true
    end
    
    function TOOL:Reload(tr)
        self:GetOwner():E2ToolBaseExec("reload", tr)
        return true
    end
end

if CLIENT then
    function TOOL:LeftClick(tr)
        return true
    end

    function TOOL:RightClick(tr)
        return true
    end

    function TOOL:Reload(tr)
        return true
    end

    function TOOL.BuildCPanel(panel)        
        local help = panel:AddControl("DButton", {})
        help:SetText("How to Use...")
        help:SetWide(100)
        help.DoClick = function()
            SKServer.OpenMOTD("e2-tool-base")
        end
    end
end
