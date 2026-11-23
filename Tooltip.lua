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

local CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t"
local CROSS = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14|t"
local OWNED_TEXT = { equipped = "equipped", bag = "in your bags", bank = "in your bank" }

local function itemName(id)
    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
    if not name and C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(id)   -- name shows next time the tooltip refreshes
    end
    return name or ("item " .. id)
end

-- Verdict for the player's own spec: "BiS for you" or "Not BiS for you, your BiS is X"
local function addVerdict(tooltip, itemID)
    if not ns.db.showVerdict then return false end
    local class, spec = ns.GetMySpec()
    if not spec then return false end
    local phase = ns.LatestPhase()
    local guide = ns.GetGuide(class, spec, phase)
    if not guide then return false end

    local rows = ns.GetGuideRows(guide)
    local mySlots = {}
    for _, r in ipairs(rows) do
        if r.id == itemID then table.insert(mySlots, r.slot) end
    end

    if #mySlots > 0 then
        tooltip:AddLine(" ")
        local text = CHECK .. " BiS for you: " .. spec .. " " .. mySlots[1] .. " (" .. ns.PhaseLabel(phase) .. ")"
        local owned = ns.Owned[itemID]
        if owned then text = text .. ", " .. OWNED_TEXT[owned] end
        tooltip:AddLine(text, 0.2, 1, 0.2)
        return true
    end

    -- Not on my list: only comment on equippable gear of reasonable quality
    if not ns.db.showNotBis then return false end
    local _, _, _, equipLoc = C_Item.GetItemInfoInstant(itemID)
    local slots = equipLoc and ns.EquipLocSlots[equipLoc]
    if not slots then return false end
    local quality = C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(itemID)
    if quality and quality < 2 then return false end

    local bis = {}
    for _, r in ipairs(rows) do
        for _, s in ipairs(slots) do
            if r.slot == s then table.insert(bis, r) break end
        end
    end
    if #bis == 0 then return false end

    tooltip:AddLine(" ")
    tooltip:AddLine(CROSS .. " Not BiS for you (" .. spec .. ")", 1, 0.5, 0.3)
    for i, r in ipairs(bis) do
        if i > 3 then break end
        local mark = ns.Owned[r.id] and (" " .. CHECK) or ""
        tooltip:AddDoubleLine("   Your " .. r.slot .. " BiS:", itemName(r.id) .. mark, 0.7, 0.7, 0.7, 1, 0.82, 0)
    end
    return true
end

local function addBisLines(tooltip, itemID, noSpacer)
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
    if not noSpacer then tooltip:AddLine(" ") end
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

        local okV, added = pcall(addVerdict, tooltip, id)
        if not okV and ns.debug then ns.Print(added) end
        local ok, err = pcall(addBisLines, tooltip, id, okV and added)
        if not ok and ns.debug then ns.Print(err) end
    end)
end
