local _, ns = ...

-- ItemIndex[itemID] = { { guide = g, phase = n, slot = "Head", faction = "Alliance"|"Horde"|nil, source = "...", alt = true|nil }, ... }
-- Main BiS picks are indexed before alternatives, so an item that is both counts as a main pick.
ns.ItemIndex = {}
ns.GuideByKey = {}     -- [phaseID][ "CLASS:Spec" ] = guide
ns.ClassSpecs = {}     -- [class] = { "Spec1", "Spec2", ... } across all phases

function ns.GuideKey(class, spec) return class .. ":" .. spec end

local function addIndex(id, entry)
    if not id then return end
    local list = ns.ItemIndex[id]
    if not list then list = {}; ns.ItemIndex[id] = list end
    -- avoid listing the same spec twice for the same item (e.g. two ring rows)
    for _, e in ipairs(list) do
        if e.guide == entry.guide and e.faction == entry.faction then return end
    end
    table.insert(list, entry)
end

function ns.BuildIndex()
    wipe(ns.ItemIndex)
    wipe(ns.GuideByKey)
    wipe(ns.ClassSpecs)
    for _, phase in ipairs(ns.PhaseList) do
        ns.GuideByKey[phase.id] = {}
        for _, g in ipairs(phase.guides) do
            ns.GuideByKey[phase.id][ns.GuideKey(g.class, g.spec)] = g

            local specs = ns.ClassSpecs[g.class]
            if not specs then specs = {}; ns.ClassSpecs[g.class] = specs end
            local known = false
            for _, s in ipairs(specs) do if s == g.spec then known = true end end
            if not known then table.insert(specs, g.spec) end

            for _, row in ipairs(g.items) do
                local slot, id, src, hId, hSrc = row[1], row[2], row[3], row[4], row[5]
                if hId then
                    addIndex(id,  { guide = g, phase = phase.id, slot = slot, faction = "Alliance", source = src })
                    addIndex(hId, { guide = g, phase = phase.id, slot = slot, faction = "Horde",    source = hSrc })
                else
                    addIndex(id,  { guide = g, phase = phase.id, slot = slot, source = src })
                end
            end
            -- alternatives, then the Realistic set; an item already indexed for this
            -- spec as a main pick (or alternative) keeps that stronger label
            local extras = {
                { rows = g.alts or {},      flag = "alt" },
                { rows = g.realistic or {}, flag = "realistic" },
                { rows = g.enchants or {},  flag = "enchant" },
                { rows = g.consumables or {}, flag = "consumable" },
            }
            for _, set in ipairs(extras) do
                for _, row in ipairs(set.rows) do
                    local slot, id, src, hId, hSrc = row[1], row[2], row[3], row[4], row[5]
                    if hId and hId ~= id then
                        addIndex(id,  { guide = g, phase = phase.id, slot = slot, faction = "Alliance", source = src, [set.flag] = true })
                        addIndex(hId, { guide = g, phase = phase.id, slot = slot, faction = "Horde",    source = hSrc, [set.flag] = true })
                    else
                        addIndex(id,  { guide = g, phase = phase.id, slot = slot, source = src, [set.flag] = true })
                    end
                end
            end
            -- Tier 0 pieces turned in for a Tier 0.5 piece on any of this spec's lists
            if g.prequest then
                for _, set in ipairs({ g.items, g.alts or {}, g.realistic or {} }) do
                    for _, row in ipairs(set) do
                        local pre = g.prequest[row[2]]
                        if pre then
                            addIndex(pre[1], { guide = g, phase = phase.id, slot = row[1], source = pre[2], pre = true, upgrade = row[2] })
                        end
                    end
                end
            end
        end
    end
end

-- The list that applies to a spec in a given phase: that phase's list, or the
-- most recent earlier one if the spec wasn't updated. Returns guide, phaseID.
function ns.GetGuide(class, spec, phaseID)
    if not class or not spec then return nil end
    local key = ns.GuideKey(class, spec)
    for i = #ns.PhaseList, 1, -1 do
        local p = ns.PhaseList[i]
        if p.id <= phaseID and ns.GuideByKey[p.id] and ns.GuideByKey[p.id][key] then
            return ns.GuideByKey[p.id][key], p.id
        end
    end
    return nil
end

-- Is this index entry part of the list that applies in phaseID?
function ns.EntryActiveIn(entry, phaseID)
    return ns.GetGuide(entry.guide.class, entry.guide.spec, phaseID) == entry.guide
end

function ns.GetSpecsForClass(class)
    return ns.ClassSpecs[class] or {}
end

-- The spec whose list counts as "mine": the spec picked in the browser (if it is
-- for the player's class, e.g. Feral Tank), otherwise the active specialization.
function ns.GetMySpec()
    local _, playerClass = UnitClass("player")
    local specs = ns.GetSpecsForClass(playerClass)
    if #specs == 0 then return playerClass, nil end

    if ns.char and ns.char.selectedClass == playerClass and ns.char.selectedSpec then
        for _, s in ipairs(specs) do
            if s == ns.char.selectedSpec then return playerClass, s end
        end
    end

    local ok, idx = pcall(GetSpecialization)
    if ok and idx and GetSpecializationInfo then
        local _, specName = GetSpecializationInfo(idx)
        if specName then
            for _, s in ipairs(specs) do
                if s:lower() == specName:lower() then return playerClass, s end
            end
        end
    end
    return playerClass, specs[1]
end

-- The character's real class and active spec (ignores what the browser shows)
function ns.GetActiveSpec()
    local _, playerClass = UnitClass("player")
    local specs = ns.GetSpecsForClass(playerClass)
    if #specs == 0 then return playerClass, nil end
    local ok, idx = pcall(GetSpecialization)
    if ok and idx and GetSpecializationInfo then
        local _, specName = GetSpecializationInfo(idx)
        if specName then
            for _, s in ipairs(specs) do
                if s:lower() == specName:lower() then return playerClass, s end
            end
        end
    end
    return playerClass, specs[1]
end

-- Your specs: your active spec first, then up to 5 saved class / spec pairs
ns.MAX_SAVED_SPECS = 5
function ns.GetSavedSpecs()
    ns.char.savedSpecs = ns.char.savedSpecs or {}
    return ns.char.savedSpecs
end

function ns.GetMySpecList()
    local list = {}
    local cls, spec = ns.GetActiveSpec()
    if spec then table.insert(list, { class = cls, spec = spec, mine = true }) end
    for _, key in ipairs(ns.GetSavedSpecs()) do
        local c, s = key:match("^(%u+):(.+)$")
        if c and not (c == cls and s == spec) then table.insert(list, { class = c, spec = s }) end
    end
    return list
end

function ns.IsSavedSpec(class, spec)
    for _, key in ipairs(ns.GetSavedSpecs()) do
        if key == class .. ":" .. spec then return true end
    end
    return false
end

function ns.SaveSpec(class, spec)
    local saved = ns.GetSavedSpecs()
    local mc, ms = ns.GetActiveSpec()
    if (class == mc and spec == ms) or ns.IsSavedSpec(class, spec) or #saved >= ns.MAX_SAVED_SPECS then return false end
    table.insert(saved, class .. ":" .. spec)
    return true
end

function ns.RemoveSavedSpec(class, spec)
    local saved = ns.GetSavedSpecs()
    for i, key in ipairs(saved) do
        if key == class .. ":" .. spec then table.remove(saved, i) return true end
    end
    return false
end

-- Equip location -> slot names used in the guides
ns.EquipLocSlots = {
    INVTYPE_HEAD = { "Head" },         INVTYPE_NECK = { "Neck" },
    INVTYPE_SHOULDER = { "Shoulder" }, INVTYPE_CLOAK = { "Back" },
    INVTYPE_CHEST = { "Chest" },       INVTYPE_ROBE = { "Chest" },
    INVTYPE_WRIST = { "Wrist" },       INVTYPE_HAND = { "Hands" },
    INVTYPE_WAIST = { "Waist" },       INVTYPE_LEGS = { "Legs" },
    INVTYPE_FEET = { "Feet" },         INVTYPE_FINGER = { "Finger" },
    INVTYPE_TRINKET = { "Trinket" },   INVTYPE_2HWEAPON = { "Two Hand", "Main Hand" },
    INVTYPE_WEAPON = { "Main Hand", "Off Hand", "Two Hand" },
    INVTYPE_WEAPONMAINHAND = { "Main Hand", "Two Hand" },
    INVTYPE_WEAPONOFFHAND = { "Off Hand" }, INVTYPE_SHIELD = { "Off Hand" },
    INVTYPE_HOLDABLE = { "Off Hand" },
    INVTYPE_RANGED = { "Ranged", "Wand" }, INVTYPE_RANGEDRIGHT = { "Ranged", "Wand" },
    INVTYPE_THROWN = { "Ranged" },     INVTYPE_RELIC = { "Relic" },
    INVTYPE_QUIVER = { "Quiver" },     INVTYPE_AMMO = { "Ammo" },
}

-- Set of item IDs on a guide (both factions)
function ns.GuideItemSet(guide)
    local set = {}
    if not guide then return set end
    for _, row in ipairs(guide.items) do
        set[row[2]] = true
        if row[4] then set[row[4]] = true end
    end
    return set
end

-- Rows for a guide resolved for the player's faction
local function resolveRow(row, faction, isAlt)
    local slot, id, src, hId, hSrc, note = row[1], row[2], row[3], row[4], row[5], row.note
    if hId and faction == "Horde" then
        return { slot = slot, id = hId, source = hSrc, faction = "Horde", isAlt = isAlt, note = note }
    end
    return { slot = slot, id = id, source = src, faction = hId and "Alliance" or nil, isAlt = isAlt, note = note }
end

-- Rows for a guide resolved for the player's faction.
-- listMode "realistic" returns the Realistic set (when the spec has one) instead
-- of the BiS list. With includeAlts (BiS list only), each alternative is placed
-- right after the last main pick for its slot.
-- After each Tier 0.5 row, add the Tier 0 piece its quest needs (unless the
-- Tier 0.5 piece is already owned).
local function addPrequest(guide, rows)
    if not guide.prequest then return rows end
    local out = {}
    for _, r in ipairs(rows) do
        table.insert(out, r)
        local pre = guide.prequest[r.id]
        if pre and not ns.Owned[r.id] then
            table.insert(out, { slot = r.slot, id = pre[1], source = pre[2], isAlt = true, isPre = true,
                                upgrade = r.id, note = "Turn in for the Tier 0.5 piece above" })
        end
    end
    return out
end

local function buildGuideRows(guide, includeAlts, listMode)
    local faction = UnitFactionGroup("player")
    local rows = {}
    local set = (listMode == "realistic" and guide.realistic) or (listMode == "enchants" and guide.enchants)
        or (listMode == "consumables" and guide.consumables)
    if set then
        for _, row in ipairs(set) do
            local r = resolveRow(row, faction, nil)
            if row[4] == row[2] then r.faction = nil end   -- same item for both factions
            table.insert(rows, r)
        end
        if listMode == "realistic" then rows = addPrequest(guide, rows) end
        return rows
    end
    for _, row in ipairs(guide.items) do
        table.insert(rows, resolveRow(row, faction, nil))
    end
    if includeAlts and guide.alts then
        local mainIds = {}
        for _, r in ipairs(rows) do mainIds[r.id] = true end
        for _, row in ipairs(guide.alts) do
            local alt = resolveRow(row, faction, true)
            if not mainIds[alt.id] then
                local pos = #rows + 1
                for i = #rows, 1, -1 do
                    if rows[i].slot == alt.slot then pos = i + 1 break end
                end
                table.insert(rows, pos, alt)
            end
        end
    end
    return addPrequest(guide, rows)
end

-- Rows are cached per guide / list / faction and rebuilt only when what you
-- own changes (Tier 0 rows depend on it), so tooltips and refreshes don't
-- build fresh tables every time.
ns.OwnedVersion = 0
local rowCache = setmetatable({}, { __mode = "k" })
local cacheVersion = -1
local cachedGuides = 0

function ns.GetGuideRows(guide, includeAlts, listMode)
    if cacheVersion ~= ns.OwnedVersion then
        wipe(rowCache); cachedGuides = 0
        cacheVersion = ns.OwnedVersion
    end
    local key = (listMode or "bis") .. (includeAlts and "+" or "-") .. (UnitFactionGroup("player") or "")
    local byGuide = rowCache[guide]
    if not byGuide then
        -- keep only a few specs (yours for tooltips, the one on screen)
        cachedGuides = cachedGuides + 1
        if cachedGuides > 3 then wipe(rowCache); cachedGuides = 1 end
        byGuide = {}; rowCache[guide] = byGuide
    end
    local rows = byGuide[key]
    if not rows then
        rows = buildGuideRows(guide, includeAlts, listMode)
        byGuide[key] = rows
    end
    return rows
end

function ns.ClearRowCache() wipe(rowCache); cachedGuides = 0 end

-- Asynchronous item data load. cb(itemMixin or nil)
function ns.WithItem(itemID, cb)
    if not itemID or itemID <= 0 then cb(nil) return end
    local item = Item:CreateFromItemID(itemID)
    if item:IsItemEmpty() then cb(nil) return end
    item:ContinueOnItemLoad(function() cb(item) end)
end

----------------------------------------------------------------------
-- Owned items: equipped, bags, bank (bank remembered between visits)
----------------------------------------------------------------------
ns.Owned = {}   -- [itemID] = "equipped" | "bag" | "bank"

local function safeNumSlots(bag)
    local ok, n = pcall(C_Container.GetContainerNumSlots, bag)
    if ok and type(n) == "number" then return n end
    return 0
end

-- Only items the guides list are remembered: a bag full of other things then
-- costs nothing, and the saved bank list stays small.
local function wanted(id)
    return next(ns.ItemIndex) == nil or ns.ItemIndex[id] ~= nil
end

local function scanContainer(bag, into)
    for slot = 1, safeNumSlots(bag) do
        local ok, id = pcall(C_Container.GetContainerItemID, bag, slot)
        if ok and type(id) == "number" and wanted(id) then into[id] = true end
    end
end

local function bankBagIDs()
    local ids, seen = {}, {}
    local function add(v)
        if type(v) == "number" and not seen[v] then seen[v] = true; table.insert(ids, v) end
    end
    if Enum and Enum.BagIndex then
        for key, value in pairs(Enum.BagIndex) do
            -- character bank (old style bank + bank bags, or new bank tabs); skip warband/account bank
            if type(key) == "string" and key:find("Bank") and not key:find("Account") then
                add(value)
            end
        end
    end
    if BANK_CONTAINER then add(BANK_CONTAINER) end
    return ids
end

local bankOpen = false

local scratch, bankScratch = {}, {}

function ns.RefreshOwned()
    if not ns.char then return end
    local now = scratch
    wipe(now)

    if bankOpen then
        wipe(bankScratch)
        for _, bag in ipairs(bankBagIDs()) do scanContainer(bag, bankScratch) end
        local saved = {}
        for id in pairs(bankScratch) do saved[id] = true end
        ns.char.bankItems = saved
    end
    for id in pairs(ns.char.bankItems or {}) do
        if wanted(id) then now[id] = "bank" end
    end

    local lastBag = (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4)
    for bag = 0, lastBag do
        for slot = 1, safeNumSlots(bag) do
            local ok, id = pcall(C_Container.GetContainerItemID, bag, slot)
            if ok and type(id) == "number" and wanted(id) then now[id] = "bag" end
        end
    end

    -- 0 = ammo, 1-19 = gear, 20-23 = equipped bags (quiver / ammo pouch)
    for invSlot = 0, 23 do
        local ok, id = pcall(GetInventoryItemID, "player", invSlot)
        if ok and id and wanted(id) then now[id] = "equipped" end
    end

    -- nothing the guides care about moved: skip the redraw
    local changed = false
    for id, where in pairs(now) do
        if ns.Owned[id] ~= where then changed = true break end
    end
    if not changed then
        for id in pairs(ns.Owned) do
            if now[id] == nil then changed = true break end
        end
    end
    if not changed and ns.OwnedVersion > 0 then return end

    wipe(ns.Owned)
    for id, where in pairs(now) do ns.Owned[id] = where end
    ns.OwnedVersion = ns.OwnedVersion + 1

    if ns.OnOwnedChanged then ns.OnOwnedChanged() end
end

local pending = false
local function queueRefresh()
    if pending then return end
    pending = true
    C_Timer.After(0.5, function()
        pending = false
        ns.RefreshOwned()
    end)
end

ns.On("BAG_UPDATE_DELAYED", queueRefresh)
ns.On("PLAYER_EQUIPMENT_CHANGED", queueRefresh)
ns.On("BANKFRAME_OPENED", function() bankOpen = true; queueRefresh() end)
ns.On("BANKFRAME_CLOSED", function() bankOpen = false end)
ns.On("PLAYERBANKSLOTS_CHANGED", function() if bankOpen then queueRefresh() end end)

----------------------------------------------------------------------
-- Slots ticked "done" in the browser, per character and spec
----------------------------------------------------------------------
function ns.GetDoneMarks(specKey)
    ns.char.done = ns.char.done or {}
    return ns.char.done[specKey] or {}
end

-- A tick is saved with a signature of the items the slot had on the lists
-- when it was ticked ({ on = true/false, sig = "..." }). If a list update
-- changes the slot's items, the tick no longer matches and is cleared.
function ns.SetDoneMark(specKey, key, on, sig)
    if not specKey or not key then return end
    ns.char.done = ns.char.done or {}
    local t = ns.char.done[specKey]
    if not t then t = {}; ns.char.done[specKey] = t end
    if on == nil then t[key] = nil else t[key] = { on = on, sig = sig } end   -- nil = automatic
end

-- Returns true / false for a valid tick, nil for automatic. Second return:
-- true when an outdated tick was just cleared.
function ns.ResolveDoneMark(specKey, key, sig)
    local t = ns.char.done and ns.char.done[specKey]
    local m = t and t[key]
    if m == nil then return nil end
    if type(m) ~= "table" then          -- tick from before signatures: adopt the current lists
        t[key] = { on = m, sig = sig }
        return m
    end
    if sig and m.sig and m.sig ~= sig then
        t[key] = nil
        return nil, true
    end
    return m.on
end
