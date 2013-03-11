-- Multi-Tool
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
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

-- NOTE:
-- The following code is terrible. Don't re-use it. You should rewrite it
-- as a proper parser.

local directives = {
    ["mindist"] = 1,
    ["maxdist"] = 1,
    ["model"] = 1,
    ["material"] = 1,
    ["class"] = 1,
    ["id"] = 1,
    ["name"] = 1,
}

local aliases = {
    ["min"] = "mindist",
    ["max"] = "maxdist",
    ["mdl"] = "model",
    ["mat"] = "material",
    ["cls"] = "class",
    ["nam"] = "name",
}

local function PreParse(tokens)
    local i = 1
    
    if #tokens == 0 or tokens[1] == "" then
        return
    elseif #tokens == 1 and tokens[1] == "*" then
        return
    end
    
    while i <= #tokens do
        local token = tokens[i]
        
        -- Handle touching parenthesis
        if token:sub(1, 1) == "(" and token ~= "(" then
            table.insert(tokens, i + 1, token:sub(2))
            tokens[i] = "("
        else
            while token:sub(-1) == ")" and token ~= ")" do
                table.insert(tokens, i + 1, ")")
                token = token:sub(1, -2)
                tokens[i] = token
            end
        end
        
        i = i + 1
    end
end

local function Parse(tokens)
    local code = ""
    local i = 1
    local nextNegation = false
    
    if #tokens == 0 or tokens[1] == "" then
        return ""
    elseif #tokens == 1 and tokens[1] == "*" then
        return "true"
    end
    
    while i <= #tokens do
        local token = tokens[i]
        local directive = nil
        
        if token == "*" then
            Error("Unexpected *") 
        elseif token:sub(1, 1) == "@" then
            directive = token:sub(2):lower()
        elseif token:lower() == "and" then
            if nextNegation then Error("Unexpected AND after NOT") end
            
            if i == #tokens then
                Error("Missing condition(s) after explicit AND")
            elseif i == 1 then
                Error("Expression starts with an explicit AND")
            elseif tokens[i + 1]:lower() == "or" then
                Error("Two logic operators together")
            end
        elseif token:lower() == "or" then
            if nextNegation then Error("Unexpected OR after NOT") end
            local moreTokens = {}
            for k = i + 1, #tokens do
                table.insert(moreTokens, tokens[k])
            end
            if code == "" then
                Error("Missing condition(s) before OR")
            end
            if #moreTokens == 0 then
                Error("Missing condition(s) after OR")
            end
            code = "(" .. code .. ") or " .. Parse(moreTokens)
            break
        elseif token == "not" then
            nextNegation = true
        elseif token == "(" then
            -- Collect the tokens within the parenthesis
            local moreTokens = {}
            local depth = 0
            local foundEndParen = false
            for k = i + 1, #tokens do
                if tokens[k] == "(" then
                    depth = depth + 1
                elseif tokens[k] == ")" or tokens[k]:sub(-1) == ")" then
                    if depth == 0 then
                        i = k
                        foundEndParen = true
                        break
                    else
                        depth = depth - 1
                    end
                else
                    table.insert(moreTokens, tokens[k])
                end
            end
            if not foundEndParen then
                Error("Expected )")
            end
            local branchCode = Parse(moreTokens)
            if branchCode ~= "" then
                code = (code ~= "" and code .. " and " or "") .. 
                    (nextNegation and "not " or "") .. "(" .. branchCode .. ")"
            end
        elseif token == ")" then
            Error("Parenthesis mismatch")
        else
            local a, b = string.match(token, "^([^:]+)=(.*)$")
            if a ~= nil then
                directive = a
                tokens[i] = b
                i = i - 1 -- We added a token unexpectedly
            else
                directive = "class"
                i = i - 1 -- We added a token unexpectedly
            end
        end
        
        if directive ~= nil then
            if aliases[directive] then
                directive = aliases[directive]
            end
            
            if directives[directive] then
                local reqArgCount = directives[directive]
                
                if #tokens - i >= reqArgCount then
                    local negation = tokens[i + 1]:sub(1, 1) == "-"
                    if negation then
                        tokens[i + 1] = tokens[i + 1]:sub(2)
                    end
                    local snip
                    
                    if directive == "mindist" then
                        snip = "distance >= " .. (tonumber(tokens[i + 1]) or 0)
                    elseif directive == "maxdist" then
                        snip = "distance <= " .. (tonumber(tokens[i + 1]) or 0)
                    elseif directive == "id" then
                        snip = "ent:EntIndex() == " .. (tonumber(tokens[i + 1]) or 0)
                    elseif directive == "model" then
                        snip = "ent:GetModel():find(" .. string.format("%q", tokens[i + 1]) .. ", 1, true)"
                    elseif directive == "material" then
                        snip = "ent:GetMaterial():find(" .. string.format("%q", tokens[i + 1]) .. ", 1, true)"
                    elseif directive == "class" then
                        snip = "ent:GetClass():find(" .. string.format("%q", tokens[i + 1]) .. ", 1, true)"
                    elseif directive == "name" then
                        snip = "ent:GetName():find(" .. string.format("%q", tokens[i + 1]) .. ", 1, true)"
                    end
                    
                    code = (code ~= "" and code .. " and " or "") .. 
                        ((nextNegation or negation) and "not " or "") .. snip
                    
                    i = i + reqArgCount
                else
                    Error(string.format("Insufficient number of tokenuments for %s (%d required)",
                                        directive, reqArgCount))
                end
            else
                Error("Unknown directive: " .. directive)
            end
        end
        
        i = i + 1
    end
    
    return code
end

local function ParseArguments(str)
    local quoted = false
    local escaped = false
    local result = {}
    local buf = ""
    for c = 1, #str do
        local char = str:sub(c, c)
        if escaped then
            buf = buf .. char
            escaped = false
        elseif char == "\"" and quoted then
            quoted = false
            table.insert(result, buf)
            buf = ""
        elseif char == "\"" and buf == "" then
            quoted = true
        elseif char == "\\" then
            escaped = true
        elseif char == " " and not quoted then
            if buf ~= "" then
                table.insert(result, buf)
                buf = ""
            end
        else
            buf = buf .. char
        end
    end
    if buf ~= "" then
        table.insert(result, buf)
    end
    return result
end

function CompileMultiToolFilter(str)
    local args = ParseArguments(str)
    PreParse(args)
    local suc, ret = pcall(Parse, args)
    if not suc then
        return false, ret:gsub("^.*:[0-9]+:", ""):Trim()
    else
        ret = "return " .. ret
        
        local suc, ret2 = pcall(CompileString, ret, "filter")
        if not suc or type(ret2) ~= 'function' then
            ErrorNoHalt("Bad filter compilation: " .. ret .. "\n")
            return false, "Compilation error (please report)"
        end
        
        return function(ent, ply)
            local distance = ply:GetPos():Distance(ent:GetPos())
            setfenv(ret2, {
                ent = ent,
                distance = distance,
            })
            return ret2() and true or false
        end
    end
end
