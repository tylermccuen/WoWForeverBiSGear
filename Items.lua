local _, ns = ...

-- ItemIndex[itemID] = { { guide = g, phase = n, slot = "Head", faction = "Alliance"|"Horde"|nil, source = "..." }, ... }
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
function ns.GetGuideRows(guide)
    local faction = UnitFactionGroup("player")
    local rows = {}
    for _, row in ipairs(guide.items) do
        local slot, id, src, hId, hSrc = row[1], row[2], row[3], row[4], row[5]
        if hId and faction == "Horde" then
            table.insert(rows, { slot = slot, id = hId, source = hSrc, faction = "Horde" })
        else
            table.insert(rows, { slot = slot, id = id, source = src, faction = hId and "Alliance" or nil })
        end
    end
    return rows
end

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

local function scanContainer(bag, into)
    for slot = 1, safeNumSlots(bag) do
        local ok, id = pcall(C_Container.GetContainerItemID, bag, slot)
        if ok and type(id) == "number" then into[id] = true end
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

function ns.RefreshOwned()
    if not ns.char then return end
    wipe(ns.Owned)

    if bankOpen then
        local bank = {}
        for _, bag in ipairs(bankBagIDs()) do scanContainer(bag, bank) end
        ns.char.bankItems = bank
    end
    for id in pairs(ns.char.bankItems or {}) do ns.Owned[id] = "bank" end

    local bags = {}
    local lastBag = (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4)
    for bag = 0, lastBag do scanContainer(bag, bags) end
    for id in pairs(bags) do ns.Owned[id] = "bag" end

    for invSlot = 1, 19 do
        local id = GetInventoryItemID("player", invSlot)
        if id then ns.Owned[id] = "equipped" end
    end

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
