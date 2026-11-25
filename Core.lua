local ADDON, ns = ...

ns.name = ADDON
ns.title = "Forever Best In Slot"

-- Link sites. {id} is replaced by the item ID, {name} by the URL-encoded item name.
ns.LinkPresets = {
    { key = "wowhead_forever", label = "Wowhead (Forever)", template = "https://www.wowhead.com/forever/item={id}" },
    { key = "custom",          label = "Custom template",   template = nil },
}

local accountDefaults = {
    showTooltip      = true,
    tooltipOwnClass  = false,
    tooltipInCombat  = false,
    tooltipPhases    = "current",
    showVerdict      = true,        -- "BiS for you" / "Not BiS for you" line for your own spec
    showNotBis       = true,        -- also show "Not BiS" + your BiS item on other equippable gear   -- "current" = latest phase only, "all" = every phase with tags
    minimap          = { hide = false, angle = 200 },
    linkPreset       = "wowhead_forever",
    customTemplate   = "https://www.wowhead.com/forever/item={id}",
    windowScale      = 1,
    compactWithCharacter = true,    -- shrink the browser next to the character window
    raidWithCharacter = true,       -- raid check panel next to the character window
}

local charDefaults = {
    selectedClass = nil,
    selectedSpec  = nil,
    selectedSlot  = "All",
    missingOnly   = false,
    showAlts      = true,
    listMode      = "bis",          -- "bis", "realistic", "enchants" or "consumables"
    hideDone      = false,          -- hide slots where the BiS or Realistic item is owned
    savedSpecs    = {},             -- up to 5 "CLASS:Spec" picks for quick switching
    bankItems     = {},
    consumeTargets = {},            -- [itemID] = how many to keep on hand (else the recommendation)
}

local function applyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            applyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function ns.Print(msg)
    print("|cff33ccffForever BiS:|r " .. tostring(msg))
end

local function urlEncode(s)
    s = tostring(s or "")
    return (s:gsub("([^%w%-_%.~])", function(c) return string.format("%%%02X", string.byte(c)) end))
end

-- Build the copy-paste URL for an item using the selected link site.
function ns.GetItemURL(itemID, itemName)
    local template
    if ns.db.linkPreset == "custom" then
        template = ns.db.customTemplate
    else
        for _, p in ipairs(ns.LinkPresets) do
            if p.key == ns.db.linkPreset then template = p.template end
        end
    end
    if not template or template == "" then
        template = ns.LinkPresets[1].template
    end
    local url = template:gsub("{id}", tostring(itemID))
    url = url:gsub("{name}", function() return urlEncode(itemName or "") end)
    return url
end

-- Simple event dispatcher
local events = CreateFrame("Frame")
local handlers = {}
function ns.On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        pcall(events.RegisterEvent, events, event)   -- an event this client lacks is skipped
    end
    table.insert(handlers[event], fn)
end
local function dispatch(event, ...)
    local list = handlers[event]
    if not list then return end
    for _, fn in ipairs(list) do fn(event, ...) end
end
events:SetScript("OnEvent", function(_, event, ...) dispatch(event, ...) end)
ns.FireEvent = dispatch   -- used by tools/uitest.lua

ns.On("ADDON_LOADED", function(_, name)
    if name ~= ADDON then return end
    ForeverBiSDB = applyDefaults(ForeverBiSDB or {}, accountDefaults)
    ForeverBiSCharDB = applyDefaults(ForeverBiSCharDB or {}, charDefaults)
    ns.db = ForeverBiSDB
    ns.char = ForeverBiSCharDB

    ns.BuildIndex()
    ns.InitTooltip()
    ns.InitOptions()
end)

ns.On("PLAYER_LOGIN", function()
    ns.InitMinimap()
    ns.RefreshOwned()
    ns.Print("loaded. Type |cffffff00/bis|r to open, |cffffff00/bis link <shift-click item>|r to copy any item's link.")
end)

SLASH_FOREVERBIS1 = "/bis"
SLASH_FOREVERBIS2 = "/fbis"
SlashCmdList["FOREVERBIS"] = function(msg)
    msg = msg or ""
    local cmd, rest = msg:match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()

    if cmd == "" then
        ns.ToggleBrowser()
    elseif cmd == "settings" or cmd == "options" or cmd == "config" then
        ns.OpenOptions()
    elseif cmd == "link" then
        local id = tonumber(rest:match("item:(%d+)")) or tonumber(rest)
        if not id then
            ns.Print("Usage: /bis link <shift-click an item, or type an item ID>")
            return
        end
        ns.ShowLinkPopupForItem(id)
    elseif cmd == "raid" or cmd == "check" then
        ns.ToggleRaidCheck()
    elseif cmd == "minimap" then
        ns.db.minimap.hide = not ns.db.minimap.hide
        ns.UpdateMinimap()
    else
        ns.Print("Commands: /bis, /bis raid, /bis settings, /bis link <item>, /bis minimap")
    end
end

-- Addon compartment (the addon dropdown next to the minimap)
function ForeverBiS_OnAddonCompartmentClick(_, button)
    if button == "RightButton" then ns.OpenOptions() else ns.ToggleBrowser() end
end
function ForeverBiS_OnAddonCompartmentEnter(_, frame)
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    GameTooltip:AddLine(ns.title)
    GameTooltip:AddLine("|cff9cd6deLeft-click|r: open browser", 1, 1, 1)
    GameTooltip:AddLine("|cff9cd6deRight-click|r: settings", 1, 1, 1)
    GameTooltip:Show()
end
function ForeverBiS_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
