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

local function DrawTriad(p1, ang)
    local p2 = p1 + ang:Forward() * 16
    local p3 = p1 - ang:Right() * 16
    local p4 = p1 + ang:Up() * 16
    
    p1, p2, p3, p4 = p1:ToScreen(), p2:ToScreen(), p3:ToScreen(), p4:ToScreen()
    
    surface.SetDrawColor(255, 0, 0, 255)
    surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
    surface.SetDrawColor(0, 255, 0, 255)
    surface.DrawLine(p1.x, p1.y, p3.x, p3.y)
    surface.SetDrawColor(0, 0, 255, 255)
    surface.DrawLine(p1.x, p1.y, p4.x, p4.y)
end

SaitoHUD.triadsFilter = nil
SaitoHUD.overlayFilter = nil
SaitoHUD.bboxFilter = nil

function SaitoHUD.DrawEntityInfo()
    local lines = SaitoHUD.GetEntityInfoLines()
    
    if table.Count(lines) > 0 then
        local color = Color(255, 255, 255, 255)
        
        local yOffset = ScrH() * 0.3
        for _, s in pairs(lines) do
            draw.SimpleText(s, "TabLarge", ScrW() - 16, yOffset, color, 2, ALIGN_TOP)
            yOffset = yOffset + 14
        end
    end
end

function SaitoHUD.DrawOverlays()
    if not SaitoHUD.triadsFilter and not SaitoHUD.overlayFilter and
       not SaitoHUD.bboxFilter then
        return
    end
    
    local refPos = SaitoHUD.GetRefPos()
    
    for _, ent in pairs(ents.GetAll()) do
        local cls = ent:GetClass()
        if cls == "" or not cls then
            cls = "<?>"
        end
        local pos = ent:GetPos()
        
        if cls:sub(1, 7) != "weapon_" and cls != "viewmodel" and 
           cls != "player" and cls != "physgun_beam" and cls != "gmod_tool" and
           cls != "gmod_camera" and cls != "worldspawn" then
            if SaitoHUD.triadsFilter and SaitoHUD.triadsFilter.f(ent, refPos) then
                DrawTriad(pos, ent:GetAngles())
            end
            
            if SaitoHUD.overlayFilter and SaitoHUD.overlayFilter.f(ent, refPos) then
                local screenPos = pos:ToScreen()
                
                draw.SimpleText(cls, "TabLarge", screenPos.x, screenPos.y,
                                Color(255, 255, 255, 255), 1, ALIGN_TOP) 
            end
            
            if SaitoHUD.bboxFilter and SaitoHUD.bboxFilter.f(ent, refPos) then
                local obbMin = ent:OBBMins()
                local obbMax = ent:OBBMaxs()
                
                local p = {
                    ent:LocalToWorld(Vector(obbMin.x, obbMin.y, obbMin.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMin.x, obbMax.y, obbMin.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMax.x, obbMax.y, obbMin.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMax.x, obbMin.y, obbMin.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMin.x, obbMin.y, obbMax.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMin.x, obbMax.y, obbMax.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMax.x, obbMax.y, obbMax.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMax.x, obbMin.y, obbMax.z)):ToScreen(),
                }
                
                local visible = true
                for i = 1, 8 do
                    if not p[i].visible then
                        visible = false
                        break
                    end
                end
                
                if visible then
                    surface.SetDrawColor(255, 0, 0, 255)
                    -- Bottom
                    surface.DrawLine(p[1].x, p[1].y, p[2].x, p[2].y)
                    surface.DrawLine(p[2].x, p[2].y, p[3].x, p[3].y)
                    surface.DrawLine(p[3].x, p[3].y, p[4].x, p[4].y)
                    surface.DrawLine(p[4].x, p[4].y, p[1].x, p[1].y)
                    -- Top
                    surface.DrawLine(p[5].x, p[5].y, p[6].x, p[6].y)
                    surface.DrawLine(p[6].x, p[6].y, p[7].x, p[7].y)
                    surface.DrawLine(p[7].x, p[7].y, p[8].x, p[8].y)
                    surface.DrawLine(p[8].x, p[8].y, p[5].x, p[5].y)
                    -- Sides
                    surface.DrawLine(p[1].x, p[1].y, p[5].x, p[5].y)
                    surface.DrawLine(p[2].x, p[2].y, p[6].x, p[6].y)
                    surface.DrawLine(p[3].x, p[3].y, p[7].x, p[7].y)
                    surface.DrawLine(p[4].x, p[4].y, p[8].x, p[8].y)
                    -- Bottom
                    --surface.DrawLine(p[1].x, p[1].y, p[3].x, p[3].y)
                end
             end
        end
    end
end

function SaitoHUD.DrawNameTags()
    local refPos = SaitoHUD.GetRefPos()
    
    for _, ply in pairs(player.GetAll()) do
        local name = ply:GetName()
        local color = Color(255, 255, 255, 255)
        
        if name:find("sk89q") then
            color = HSVToColor(math.sin(CurTime() * 360 / 500) * 360, 1, 1)
        end
        
        local screenPos = (ply:GetPos() + Vector(0, 0, 50)):ToScreen()
        local distance = math.Round(ply:GetPos():Distance(refPos))
        
        draw.SimpleTextOutlined(string.format("%s [%s]", name, distance),
                                "DefaultSmall", screenPos.x, screenPos.y,
                                color, 1, ALIGN_TOP, 1, Color(0, 0, 0, 255))
    end
end