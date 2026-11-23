local _, ns = ...

local function classColor(class)
    local c = C_ClassColor and C_ClassColor.GetClassColor(class)
    if c then return c end
    local rc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if rc then return rc end
    return { r = 1, g = 1, b = 1 }
end

local function classIcon(class)
    if CreateAtlasMarkup then
        return CreateAtlasMarkup("classicon-" .. class:lower(), 14, 14)
    end
    return ""
end

local function className(class)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
end

local function isSecret(v)
    return issecretvalue and issecretvalue(v)
end

-- "P1-3" / "P1, P3"
local function phaseTag(phases)
    table.sort(phases)
    local parts, i = {}, 1
    while i <= #phases do
        local j = i
        while j < #phases and phases[j + 1] == phases[j] + 1 do j = j + 1 end
        if j > i then table.insert(parts, "P" .. phases[i] .. "-" .. phases[j])
        else table.insert(parts, "P" .. phases[i]) end
        i = j + 1
    end
    return table.concat(parts, ", ")
end

local function addBisLines(tooltip, itemID)
    local entries = ns.ItemIndex[itemID]
    if not entries then return end

    local _, playerClass = UnitClass("player")
    local playerFaction = UnitFactionGroup("player")
    local latest = ns.LatestPhase()
    local allPhases = ns.db.tooltipPhases == "all"

    -- byClass[cls] = { labels = { {spec=, faction=, phases={set}} ... } }
    local byClass, order = {}, {}
    for _, e in ipairs(entries) do
        local cls = e.guide.class
        if not ns.db.tooltipOwnClass or cls == playerClass then
            -- phases in which this entry's list is the one in use
            local active = {}
            for _, p in ipairs(ns.PhaseList) do
                if p.id >= e.phase and ns.EntryActiveIn(e, p.id) then active[p.id] = true end
            end
            if allPhases or active[latest] then
                if not byClass[cls] then
                    byClass[cls] = { labels = {} }
                    table.insert(order, cls)
                end
                local faction = (e.faction and e.faction ~= playerFaction) and e.faction or nil
                local found
                for _, l in ipairs(byClass[cls].labels) do
                    if l.spec == e.guide.spec and l.faction == faction then found = l end
                end
                if not found then
                    found = { spec = e.guide.spec, faction = faction, phases = {} }
                    table.insert(byClass[cls].labels, found)
                end
                for id in pairs(active) do found.phases[id] = true end
            end
        end
    end
    if #order == 0 then return end

    local rank = {}
    for i, c in ipairs(ns.ClassOrder) do rank[c] = i end
    table.sort(order, function(a, b) return (rank[a] or 99) < (rank[b] or 99) end)

    local showTags = allPhases and ns.MultiPhase()
    tooltip:AddLine(" ")
    if allPhases then
        tooltip:AddLine("Forever BiS:", 0.9, 0.8, 0.5)
    else
        local p = ns.Phases[latest]
        tooltip:AddLine("Forever BiS - " .. ns.PhaseLabel(latest) .. (p and p.subtitle and (" (" .. p.subtitle .. ")") or "") .. ":", 0.9, 0.8, 0.5)
    end

    for _, cls in ipairs(order) do
        local labels = byClass[cls].labels
        -- drop "Spec (other faction)" when the same spec is already listed for the player's faction
        local plain = {}
        for _, l in ipairs(labels) do if not l.faction then plain[l.spec] = true end end
        local texts, tags, sameTag, anyFaction = {}, {}, true, false
        for _, l in ipairs(labels) do
            if not (l.faction and plain[l.spec]) then
                local list = {}
                for id in pairs(l.phases) do table.insert(list, id) end
                local tag = showTags and phaseTag(list) or ""
                local t = l.spec
                if l.faction then t = t .. " (" .. l.faction .. ")"; anyFaction = true end
                if tag ~= "" then t = t .. " " .. tag end
                table.insert(texts, t)
                if tags[1] and tags[1] ~= tag then sameTag = false end
                table.insert(tags, tag)
            end
        end
        local specText
        if #texts >= #ns.GetSpecsForClass(cls) and sameTag and not anyFaction then
            specText = "All specs" .. ((tags[1] and tags[1] ~= "") and (" " .. tags[1]) or "")
        else
            specText = table.concat(texts, ", ")
        end
        local c = classColor(cls)
        tooltip:AddDoubleLine(classIcon(cls) .. " " .. className(cls), specText, c.r, c.g, c.b, c.r, c.g, c.b)
    end
end

function ns.InitTooltip()
    if not (TooltipDataProcessor and Enum and Enum.TooltipDataType) then
        ns.Print("TooltipDataProcessor not found; tooltip lines are disabled.")
        return
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if not ns.db or not ns.db.showTooltip then return end
        if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
        if not tooltip.AddLine then return end
        if InCombatLockdown() and not ns.db.tooltipInCombat then return end
        if not data then return end

        local id = data.id
        if isSecret(id) then return end   -- Midnight-era restriction: some values are hidden in combat
        if type(id) ~= "number" then return end

        local ok, err = pcall(addBisLines, tooltip, id)
        if not ok and ns.debug then ns.Print(err) end
    end)
end
