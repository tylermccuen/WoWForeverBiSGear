local _, ns = ...

--[[
    Guild announcement for new BiS items (Settings: "Announce new BiS items in
    guild chat", off by default).

    Every item the character has ever had (equipped, bags or bank) is
    remembered in ns.char.seenItems. When an item that's a main pick on your
    spec's BiS or Realistic list shows up for the first time, it's posted in
    guild chat: "I just got [new item] to replace my [old item]." Items present at login (the first seconds after entering
    the world) are only remembered, never announced, so nothing you already
    own gets posted.
]]

local readyAt          -- announcements start this many seconds after login
local queue = {}       -- messages waiting for combat to end

local function send(msg)
    local f = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    if f then pcall(f, msg, "GUILD") end
end

local function flush()
    if InCombatLockdown and InCombatLockdown() then return end
    for i = 1, #queue do send(queue[i]) end
    wipe(queue)
end

-- Equipment slots for each list slot
local INV_FOR = {
    Head = { 1 }, Neck = { 2 }, Shoulder = { 3 }, Back = { 15 }, Chest = { 5 }, Wrist = { 9 },
    Hands = { 10 }, Waist = { 6 }, Legs = { 7 }, Feet = { 8 }, Finger = { 11, 12 }, Trinket = { 13, 14 },
    ["Main Hand"] = { 16 }, ["Two Hand"] = { 16 }, ["Off Hand"] = { 17 },
    Ranged = { 18 }, Wand = { 18 }, Relic = { 18 },
}
local lastEquipped = {}   -- inv slot -> item link at the previous scan

local function equippedLinks()
    local t = {}
    for inv = 1, 19 do
        local ok, link = pcall(GetInventoryItemLink, "player", inv)
        if ok and link then t[inv] = link end
    end
    return t
end

local function itemLevel(link)
    local f = C_Item and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
    local ok, lvl = pcall(f, link)
    return (ok and lvl) or 0
end

local function linkID(link)
    return link and tonumber(link:match("item:(%d+)"))
end

-- The item the new one replaces: if the new item is already equipped, what
-- was in that slot before; otherwise what's in the slot now. Rings and
-- trinkets: the lower item level one.
local function replacedItem(itemID, slot, equippedNow)
    local invs = INV_FOR[slot]
    if not invs then return nil end
    local isOn = ns.Owned[itemID] == "equipped"
    local best, bestLvl
    for _, inv in ipairs(invs) do
        local cur = equippedNow[inv]
        local old = cur
        if isOn and linkID(cur) == itemID then old = lastEquipped[inv] end   -- the slot it went into
        if old and linkID(old) ~= itemID then
            local lvl = itemLevel(old)
            if not best or lvl < bestLvl then best, bestLvl = old, lvl end
        end
    end
    return best
end

local function announce(itemID, oldLink)
    ns.WithItem(itemID, function(item)
        local link = item and item:GetItemLink()
        if not link then return end
        local msg
        if oldLink then
            msg = string.format("I just got %s to replace my %s.", link, oldLink)
        else
            msg = string.format("I just got %s!", link)
        end
        table.insert(queue, msg)
        flush()
    end)
end

-- Called after every owned-items scan
function ns.CheckNewBis()
    if not ns.char then return end
    ns.char.seenItems = ns.char.seenItems or {}
    local seen = ns.char.seenItems
    local live = readyAt and GetTime() >= readyAt

    -- BiS and Realistic picks for your spec
    local listSlot
    if live and ns.db.announceGuild and IsInGuild and IsInGuild() then
        local class, spec = ns.GetMySpec()
        local guide = spec and ns.GetGuide(class, spec, ns.LatestPhase())
        if guide then
            listSlot = {}
            for _, mode in ipairs({ "bis", "realistic" }) do
                for _, r in ipairs(ns.GetGuideRows(guide, false, mode)) do
                    if not r.isAlt then listSlot[r.id] = listSlot[r.id] or r.slot end
                end
            end
        end
    end

    local equippedNow = equippedLinks()
    for id in pairs(ns.Owned) do
        if not seen[id] then
            seen[id] = true
            if listSlot and listSlot[id] then
                announce(id, replacedItem(id, listSlot[id], equippedNow))
            end
        end
    end
    lastEquipped = equippedNow
end

ns.On("PLAYER_ENTERING_WORLD", function()
    -- give bags and equipment time to load before anything counts as new
    if not readyAt then readyAt = GetTime() + 15 end
end)
ns.On("PLAYER_REGEN_ENABLED", flush)
