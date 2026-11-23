local _, ns = ...

--[[
    Guild announcement for new BiS items (Settings: "Announce new BiS items in
    guild chat", off by default).

    Every item the character has ever had (equipped, bags or bank) is
    remembered in ns.char.seenItems. When an item that's a main pick on your
    spec's BiS list shows up for the first time, it's posted in guild chat
    with its link. Items present at login (the first seconds after entering
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

local function announce(itemID, slot, class, spec)
    ns.WithItem(itemID, function(item)
        local link = item and item:GetItemLink()
        if not link then return end
        local className = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
        local msg = string.format("Forever BiS: new BiS %s for my %s %s: %s", slot:lower(), spec, className, link)
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

    local bisSlot
    if live and ns.db.announceGuild and IsInGuild and IsInGuild() then
        local class, spec = ns.GetMySpec()
        local guide = spec and ns.GetGuide(class, spec, ns.LatestPhase())
        if guide then
            bisSlot = {}
            for _, r in ipairs(ns.GetGuideRows(guide, false, "bis")) do
                if not r.isAlt then bisSlot[r.id] = r.slot end
            end
            bisSlot.class, bisSlot.spec = class, spec
        end
    end

    for id in pairs(ns.Owned) do
        if not seen[id] then
            seen[id] = true
            if bisSlot and bisSlot[id] then announce(id, bisSlot[id], bisSlot.class, bisSlot.spec) end
        end
    end
end

ns.On("PLAYER_ENTERING_WORLD", function()
    -- give bags and equipment time to load before anything counts as new
    if not readyAt then readyAt = GetTime() + 15 end
end)
ns.On("PLAYER_REGEN_ENABLED", flush)
