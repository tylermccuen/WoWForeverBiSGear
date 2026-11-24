local _, ns = ...

--[[
    Boss popup: clicking a boss in "Where to get it" shows a small window with
    the boss's model, dungeon, Dungeon Journal description and the items on
    your lists that drop from it, plus a button to open the Dungeon Journal.

    Boss names come from the source text ("Stratholme: Baron Rivendare",
    "Drop: Gyth (Upper Blackrock Spire)") and are matched against the
    Dungeon Journal's encounters, so only real journal bosses are clickable.
]]

local bossIndex          -- lower-case boss name -> { encounterID, instanceID, instance }
local SKULL = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14:14|t "

local function buildIndex()
    bossIndex = {}
    if not (EJ_GetNumTiers and EJ_SelectTier and EJ_GetInstanceByIndex and EJ_GetEncounterInfoByIndex) then return end
    local okCur, current = pcall(EJ_GetCurrentTier)
    local okN, tiers = pcall(EJ_GetNumTiers)
    for tier = 1, (okN and tiers or 0) do
        pcall(EJ_SelectTier, tier)
        for _, isRaid in ipairs({ false, true }) do
            local i = 1
            while true do
                local ok, instanceID, instanceName = pcall(EJ_GetInstanceByIndex, i, isRaid)
                if not ok or not instanceID then break end
                local j = 1
                while true do
                    local okE, name, _, encounterID = pcall(EJ_GetEncounterInfoByIndex, j, instanceID)
                    if not okE or not name then break end
                    bossIndex[name:lower()] = bossIndex[name:lower()]
                        or { encounterID = encounterID, instanceID = instanceID, instance = instanceName, name = name }
                    j = j + 1
                end
                i = i + 1
            end
        end
    end
    if okCur and current then pcall(EJ_SelectTier, current) end
end

-- Boss named in a source string, if the Dungeon Journal knows it
function ns.FindBoss(source)
    if type(source) ~= "string" or source == "" then return nil end
    if source:find("[Qq]uest") or source:find("^Vendor") then return nil end
    if not bossIndex or next(bossIndex) == nil then buildIndex() end   -- retry until the journal answers
    -- "Zone: Boss / Other", "Drop: Boss (Zone)", "Zone: Boss (or ...)"
    local after = source:match(":%s*(.+)$") or source
    for name in (after .. " / "):gmatch("(.-) / ") do
        name = name:gsub("%s*%b()", ""):gsub("^%s+", ""):gsub("%s+$", "")
        local hit = bossIndex[name:lower()]
        if hit then return hit end
    end
    return nil
end
ns.BOSS_ICON = SKULL

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
local win

local function itemsFromBoss(boss)
    local out = {}
    local class, spec = ns.char.selectedClass, ns.char.selectedSpec
    local guide = class and spec and ns.GetGuide(class, spec, ns.LatestPhase())
    if not guide then return out end
    local seen = {}
    for _, mode in ipairs({ "bis", "realistic" }) do
        for _, r in ipairs(ns.GetGuideRows(guide, true, mode)) do
            local b = ns.FindBoss(r.source)
            if b and b.encounterID == boss.encounterID and not seen[r.id] then
                seen[r.id] = true
                table.insert(out, r)
            end
        end
    end
    return out
end

local function createWindow()
    win = CreateFrame("Frame", "ForeverBiSBossFrame", UIParent, "BasicFrameTemplateWithInset")
    win:SetSize(320, 470)
    win:SetPoint("CENTER", 0, 40)
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:EnableMouse(true)
    win:SetMovable(true)
    win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    tinsert(UISpecialFrames, "ForeverBiSBossFrame")

    win.title = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    win.title:SetPoint("TOP", 0, -5)

    win.instance = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.instance:SetPoint("TOP", 0, -32)

    -- model (drag to turn)
    local model = CreateFrame("PlayerModel", nil, win)
    model:SetPoint("TOPLEFT", 14, -52)
    model:SetPoint("TOPRIGHT", -14, -52)
    model:SetHeight(200)
    model:EnableMouse(true)
    model.facing = 0
    model:SetScript("OnMouseDown", function(self) self.dragX = GetCursorPosition() end)
    model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    model:SetScript("OnUpdate", function(self)
        if self.dragX then
            local x = GetCursorPosition()
            self.facing = self.facing + (x - self.dragX) * 0.02
            self.dragX = x
            self:SetFacing(self.facing)
        end
    end)
    win.model = model
    local bg = model:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.35)

    local scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", model, "BOTTOMLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", -32, 44)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(260, 200)
    scroll:SetScrollChild(child)
    win.text = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    win.text:SetPoint("TOPLEFT")
    win.text:SetWidth(258)
    win.text:SetJustifyH("LEFT")
    win.text:SetSpacing(3)
    win.child = child

    local open = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    open:SetSize(200, 24)
    open:SetPoint("BOTTOM", 0, 12)
    open:SetText("Open in Dungeon Journal")
    open:SetScript("OnClick", function()
        local b = win.boss
        if not b then return end
        if not EncounterJournal_OpenJournal then
            local load = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
            if load then pcall(load, "Blizzard_EncounterJournal") end
        end
        if EncounterJournal_OpenJournal then
            pcall(EncounterJournal_OpenJournal, nil, b.instanceID, b.encounterID)
        elseif ToggleEncounterJournal then
            ToggleEncounterJournal()
        end
    end)
end

function ns.ShowBoss(boss)
    if not boss then return end
    if not win then createWindow() end
    win.boss = boss
    win.title:SetText(boss.name)
    win.instance:SetText(boss.instance or "")

    -- model: first creature of the encounter
    win.model:ClearModel()
    local ok, _, _, _, displayInfo = pcall(EJ_GetCreatureInfo, 1, boss.encounterID)
    if ok and displayInfo then
        win.model:SetDisplayInfo(displayInfo)
        win.model.facing = 0
        win.model:SetFacing(0)
    end

    local parts = {}
    local okI, _, description = pcall(EJ_GetEncounterInfo, boss.encounterID)
    if okI and description and description ~= "" then table.insert(parts, description) end

    local items = itemsFromBoss(boss)
    if #items > 0 then
        table.insert(parts, "\n|cffffd100On your lists from this boss:|r")
        for _, r in ipairs(items) do
            local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(r.id) or ("item " .. r.id)
            local mark = ns.Owned[r.id] and "  |cff33ff33(have it)|r" or ""
            table.insert(parts, "  " .. r.slot .. ": " .. name .. mark)
        end
    end
    win.text:SetText(table.concat(parts, "\n"))
    win.child:SetHeight((win.text:GetStringHeight() or 0) + 10)
    win:Show()
    win:Raise()
end

-- Rebuild the boss list if the journal loads later
ns.On("ADDON_LOADED", function(_, name)
    if name == "Blizzard_EncounterJournal" then bossIndex = nil end
end)
