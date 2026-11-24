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
