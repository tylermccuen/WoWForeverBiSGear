local _, ns = ...

--[[
    Quest hover: where to pick up the quests named in "Where to get it".
    Data (quest giver, zone, coordinates, side) is in Data/Quests.lua.
]]

-- Tier 0.5 set quests: which Tier 0 pieces they take
local TIER_QUESTS = {
    ["Saving the Best for Last"] = "head and chest",
    ["Anthion's Parting Words"]  = "shoulders, legs and feet",
    ["Just Compensation"]        = "hands and waist",
    ["An Earnest Proposition"]   = "wrists",
}

-- Quests named in a source: "Quest: A / B (Zone)", "Dungeon Set 2 quest: X",
-- or a recipe source like "Sharing the Knowledge (Silithus)"
function ns.QuestsInSource(source)
    if type(source) ~= "string" or not ns.Quests then return nil end
    local names = source:match("[Qq]uest: (.+)$") or source
    names = names:gsub("%s*%b()%s*$", "")
    local found = {}
    for name in (names .. " / "):gmatch("(.-) / ") do
        if ns.Quests[name] then table.insert(found, name) end
    end
    return #found > 0 and found or nil
end

local SIDE_COLOR = { Alliance = { 0.3, 0.6, 1 }, Horde = { 1, 0.3, 0.3 } }

function ns.AddQuestTooltip(tooltip, names)
    local mySide = UnitFactionGroup("player")
    for i, name in ipairs(names) do
        if i > 1 then tooltip:AddLine(" ") end
        tooltip:AddLine(name, 1, 0.82, 0)
        local tier = TIER_QUESTS[name]
        if tier then
            tooltip:AddLine("Tier 0.5 set quest: hand in your Tier 0 " .. tier
                .. " (plus the quest items) to upgrade them to Tier 0.5.", 0.2, 1, 0.2, true)
        end
        local givers = ns.Quests[name] or {}
        -- your faction's giver first
        table.sort(givers, function(a, b)
            return (a[1] == mySide and 0 or 1) < (b[1] == mySide and 0 or 1)
        end)
        for _, g in ipairs(givers) do
            local side, giver, zone, coords, level = g[1], g[2], g[3], g[4], g[5]
            local c = SIDE_COLOR[side] or { 1, 1, 1 }
            local where = zone ~= "" and zone or "?"
            if coords and coords ~= "" then where = where .. "  (" .. coords:gsub(",", ", ") .. ")" end
            tooltip:AddDoubleLine((side ~= "" and side ~= "Both") and (side .. ": " .. giver) or ("Quest giver: " .. giver),
                where, c[1], c[2], c[3], 1, 1, 1)
            if level and level ~= "" then tooltip:AddLine("   Requires level " .. level, 0.7, 0.7, 0.7) end
        end
        if #givers == 0 then tooltip:AddLine("Quest giver: TBD", 0.7, 0.7, 0.7) end
    end
end

----------------------------------------------------------------------
-- Map pins: put a waypoint on the quest giver (the game's own map pin,
-- plus TomTom's arrow when TomTom is installed)
----------------------------------------------------------------------
local mapByName

local function findMap(zone)
    if not (C_Map and C_Map.GetMapChildrenInfo) then return nil end
    if not mapByName then
        mapByName = {}
        for _, root in ipairs({ 947, 1414, 1415 }) do   -- Azeroth, Kalimdor, Eastern Kingdoms
            local ok, kids = pcall(C_Map.GetMapChildrenInfo, root, nil, true)
            if ok and type(kids) == "table" then
                for _, m in ipairs(kids) do
                    if m.name and m.mapID then
                        local key = m.name:lower()
                        -- prefer zones / cities over dungeon floors with the same name
                        if not mapByName[key] or (Enum and Enum.UIMapType and m.mapType == Enum.UIMapType.Zone) then
                            mapByName[key] = m.mapID
                        end
                    end
                end
            end
        end
    end
    return mapByName[zone:lower()]
end

-- zone "Orgrimmar", coords "31.7,37.8". Returns true when a pin was set.
function ns.PinOnMap(zone, coords, title)
    local x, y = (coords or ""):match("([%d%.]+)%s*,%s*([%d%.]+)")
    x, y = tonumber(x), tonumber(y)
    local mapID = zone and findMap(zone)
    if not (x and y and mapID) then
        ns.Print("Can't pin " .. (title or "that") .. ": no map position for " .. tostring(zone) .. ".")
        return false
    end
    x, y = x / 100, y / 100
    local pinned = false
    if C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapID) and UiMapPoint then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        pinned = true
    end
    if TomTom and TomTom.AddWaypoint then
        pcall(TomTom.AddWaypoint, TomTom, mapID, x, y, { title = title, from = "Forever Best In Slot" })
        pinned = true
    end
    if pinned then
        local link = C_Map.GetUserWaypointHyperlink and C_Map.GetUserWaypointHyperlink()
        ns.Print("Pinned " .. (title or "") .. " in " .. zone .. " (" .. coords:gsub(",", ", ") .. ")" .. (link and ("  " .. link) or ""))
    else
        ns.Print("Your client doesn't allow map pins in " .. zone .. ".")
    end
    return pinned
end

-- Quest givers with a map position, your faction first
function ns.QuestPins(names)
    local mySide = UnitFactionGroup("player")
    local out = {}
    for _, name in ipairs(names or {}) do
        for _, g in ipairs(ns.Quests[name] or {}) do
            local side, giver, zone, coords = g[1], g[2], g[3], g[4]
            if coords and coords ~= "" and zone ~= "" and not zone:find(",")
                and (side == "Both" or side == "" or side == mySide) then
                table.insert(out, { quest = name, giver = giver, zone = zone, coords = coords })
            end
        end
    end
    return out
end
