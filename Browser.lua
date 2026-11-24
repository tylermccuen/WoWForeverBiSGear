local _, ns = ...

local ROW_HEIGHT = 40
local frame, scrollChild, rows = nil, nil, {}
local CHECK_ICON = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t "
local lastRaidSpec
local WIDTH, HEIGHT = 960, 540          -- default size
local MIN_W, MIN_H, MAX_W, MAX_H = 880, 320, 1500, 1100
local headerSource, headerAvoid        -- "WHERE TO GET IT" / "ENCHANT" headers

-- saved window width, never narrower than the controls need
local function savedWidth()
    return math.max(MIN_W, ns.db.windowWidth or WIDTH)
end

-- Column positions follow the window width
local COMPACT_W = 600   -- width beside the character window

local function columnLayout(contentWidth)
    if frame and frame.compact then
        -- compact: no source / avoid columns; the source goes under the item name
        local nameW = math.max(200, contentWidth - 250)
        return nameW + 50, nameW, 0, nameW + 50, 0
    end
    local sourceX = math.max(250, math.floor(contentWidth * 0.30))
    local nameW = sourceX - 50
    local rest = math.max(300, contentWidth - sourceX - 200)   -- 200 = owned / done / link
    local avoidFixed = 150                                     -- enchant column
    local sourceW = math.max(180, rest - avoidFixed - 10)
    local avoidX = sourceX + sourceW + 10
    local avoidW = rest - sourceW - 10
    return sourceX, nameW, sourceW, avoidX, avoidW
end

local function layoutRow(row)
    local sourceX, nameW, sourceW, avoidX, avoidW = columnLayout(scrollChild:GetWidth())
    row.name:SetWidth(nameW - (row.isAlt and 18 or 0))
    row.slot:SetWidth(nameW)
    row.source:ClearAllPoints()
    row.source:SetPoint("LEFT", sourceX, 0)
    row.source:SetWidth(sourceW)
    row.avoid:ClearAllPoints()
    row.avoid:SetPoint("LEFT", avoidX, 0)
    row.avoid:SetWidth(avoidW)
    row.source:SetShown(not frame.compact)
    row.avoid:SetShown(not frame.compact)
end

local classButton, specButton, phaseButton, listTabs, slotButton, missingCheck, altCheck, altLabel, doneCheck, doneLabel, countText

local OWNED_ICON = {
    equipped = "|TInterface\\RaidFrame\\ReadyCheck-Ready:16:16|t Equipped",
    bag      = "|TInterface\\Buttons\\Button-Backpack-Up:16:16|t In bags",
    bank     = "|TInterface\\Icons\\INV_Misc_Bag_10_Blue:16:16|t In bank",
}

local function className(class)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
end

local function classColorHex(class)
    local c = C_ClassColor and C_ClassColor.GetClassColor(class)
    if c and c.GenerateHexColor then return "|c" .. c:GenerateHexColor() end
    return "|cffffffff"
end

local function selectedPhase()
    local p = ns.char.selectedPhase
    if not p or not ns.Phases[p] then p = ns.LatestPhase() end
    return p
end

-- returns guide, phase the list comes from
local function currentGuide()
    return ns.GetGuide(ns.char.selectedClass, ns.char.selectedSpec, selectedPhase())
end

-- Pick the player's class/spec the first time the window opens
local function ensureSelection()
    if ns.char.selectedClass and currentGuide() then return end
    local _, playerClass = UnitClass("player")
    ns.char.selectedClass = playerClass
    local specs = ns.GetSpecsForClass(playerClass)
    ns.char.selectedSpec = specs[1]

    local ok, idx = pcall(GetSpecialization)
    if ok and idx and GetSpecializationInfo then
        local _, specName = GetSpecializationInfo(idx)
        if specName then
            for _, s in ipairs(specs) do
                if s:lower() == specName:lower() then ns.char.selectedSpec = s end
            end
        end
    end
    if not currentGuide() then
        for _, cls in ipairs(ns.ClassOrder) do
            local s = ns.GetSpecsForClass(cls)[1]
            if s and ns.GetGuide(cls, s, selectedPhase()) then
                ns.char.selectedClass, ns.char.selectedSpec = cls, s
                break
            end
        end
    end
end

-- The spec's enchant for a gear row's slot, with a green tick when the
-- equipped item in that slot is already enchanted.
local function enchantFor(guide, slot)
    if not guide.enchants then return nil end
    for _, e in ipairs(guide.enchants) do
        if e[1] == slot then return e[2] end
    end
end

local function setEnchantText(row, data, name)
    name = name:gsub("^Enchant ", "")
    if ns.Owned[data.id] == "equipped" and ns.SlotEnchant and select(2, ns.SlotEnchant(data.slot)) then
        row.avoid:SetText("|cff33ff33" .. CHECK_ICON .. name .. "|r")
    else
        row.avoid:SetText("|cffffffff" .. name .. "|r")
    end
end

local function enchantCell(row, data)
    local id = data.enchantID
    if not id then row.avoid:SetText("") return end
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
    if name then setEnchantText(row, data, name) return end
    row.avoid:SetText("|cff999999...|r")
    ns.WithItem(id, function(item)
        local loaded = item and item.GetItemName and item:GetItemName()
        if loaded and row.enchantID == id then setEnchantText(row, data, loaded) end
    end)
end

-- Quests in the player's quest log (lower-case titles), for highlighting
-- "Quest: ..." sources the player is already on.
local questTitles = {}
local function scanQuestLog()
    wipe(questTitles)
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then return end
    local ok, n = pcall(C_QuestLog.GetNumQuestLogEntries)
    for i = 1, (ok and n or 0) do
        local okI, info = pcall(C_QuestLog.GetInfo, i)
        if okI and type(info) == "table" and info.title and not info.isHeader then
            questTitles[info.title:lower()] = true
        end
    end
end

-- "Quest: Name (Zone)", "Dungeon Set 2 quest: Name", "Quest: A / B"
function ns.OnSourceQuest(source)
    if type(source) ~= "string" then return false end
    local names = source:match("[Qq]uest: (.+)$")
    if not names then return false end
    names = names:gsub("%s*%b()%s*$", "")
    for name in (names .. " / "):gmatch("(.-) / ") do
        if questTitles[name:lower()] then return true end
    end
    return false
end

ns.On("QUEST_LOG_UPDATE", function()
    scanQuestLog()
    if frame and frame:IsShown() then ns.RefreshBrowser() end
end)
ns.On("PLAYER_LOGIN", scanQuestLog)
ns.ScanQuestLog = scanQuestLog   -- used by tools/uitest.lua

----------------------------------------------------------------------
-- Rows
----------------------------------------------------------------------

local function createRow(i)
    local row = CreateFrame("Frame", nil, scrollChild)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0)
    row.index = i

    local icon = CreateFrame("Button", nil, row)
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", 4, 0)
    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints()
    icon:SetScript("OnEnter", function(self)
        if not row.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(row.itemID)
        GameTooltip:Show()
    end)
    icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    icon:SetScript("OnClick", function()
        -- Shift-click puts the item in chat, Ctrl-click opens the dressing room
        if row.itemLink then HandleModifiedItemClick(row.itemLink) end
    end)
    row.icon = icon

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, -1)
    row.name:SetWidth(250)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row.slot = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.slot:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 6, 1)
    row.slot:SetWidth(250)
    row.slot:SetJustifyH("LEFT")
    row.slot:SetTextColor(0.65, 0.65, 0.65)
    row.slot:SetWordWrap(false)

    row.source = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.source:SetPoint("TOPLEFT", 300, -5)
    row.source:SetWidth(250)
    row.source:SetJustifyH("LEFT")
    row.source:SetJustifyV("MIDDLE")
    row.source:SetWordWrap(true)          -- up to two lines instead of cutting off
    if row.source.SetMaxLines then row.source:SetMaxLines(2) end

    row.avoid = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.avoid:SetJustifyH("LEFT")
    row.avoid:SetWordWrap(false)


    local link = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    link:SetSize(64, 22)
    link:SetPoint("RIGHT", -4, 0)
    link:SetText("Link")
    link:SetScript("OnClick", function()
        if row.itemID then ns.ShowLinkPopupForItem(row.itemID) end
    end)
    link:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Copy web link")
        GameTooltip:AddLine(row.itemID and ns.GetItemURL(row.itemID, row.itemName) or "", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    link:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.link = link

    -- "done" tick: marks this slot finished for the spec, in every list
    local done = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    done:SetSize(24, 24)
    done:SetPoint("RIGHT", link, "LEFT", -4, 0)
    done:SetScript("OnClick", function(self)
        if row.doneKey then
            local on = self:GetChecked() and true or false
            -- back to automatic when the tick matches what ownership says
            if on == (row.autoDone or false) then on = nil end
            ns.SetDoneMark(row.specKey, row.doneKey, on)
            ns.RefreshBrowser()
        end
    end)
    done:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Done")
        if row.autoDone then
            GameTooltip:AddLine("Ticked because you own a BiS or Realistic item for this slot. Untick it if the slot isn't finished.", 1, 1, 1, true)
        else
            GameTooltip:AddLine("Tick when this slot is finished, with this item or one from the other list. It counts in both the BiS and Realistic lists.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    done:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.done = done

    row.owned = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.owned:SetPoint("RIGHT", done, "LEFT", -4, 0)
    row.owned:SetJustifyH("RIGHT")

    rows[i] = row
    return row
end

local function fillRow(row, data)
    row.itemID = data.id
    row.itemLink = nil
    row.itemName = nil
    row.token = (row.token or 0) + 1
    local token = row.token

    -- alternatives are indented and tinted under the main pick for their slot
    row.isAlt = data.isAlt
    row.isPre = data.isPre
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", data.isAlt and 22 or 4, 0)
    row.icon:SetSize(data.isAlt and 26 or 32, data.isAlt and 26 or 32)
    if data.isAlt then
        row.bg:SetColorTexture(0.45, 0.6, 1, 0.07)
    else
        row.bg:SetColorTexture(1, 1, 1, (row.index % 2 == 0) and 0.04 or 0)
    end

    layoutRow(row)
    row.icon.tex:SetTexture(C_Item.GetItemIconByID(data.id) or 134400)
    row.name:SetText("|cff888888Loading item " .. data.id .. "...|r")
    local slotText = data.slot
    if data.isPre then slotText = "|cffffd100For T0.5 quest|r  " .. slotText
    elseif data.isAlt then slotText = "|cff8fb8ffAlternative|r  " .. slotText end
    if data.isNew then slotText = "|cff1eff00NEW|r  " .. slotText end
    if data.faction then slotText = slotText .. "  |cffffd100(" .. data.faction .. ")|r" end
    local onQuest = ns.OnSourceQuest(data.source)
    if frame.compact and data.source then
        slotText = slotText .. (onQuest and "  |cff33ff33" or "  |cff999999") .. data.source .. "|r"
    end
    row.slot:SetText(slotText)
    local src = data.source or ""
    if onQuest then src = "|cff33ff33" .. src .. "  (On quest)|r" end
    if data.note and not data.isPre then src = src .. "  |cffaaaaaa(" .. data.note .. ")|r" end
    row.source:SetText(src)
    row.enchantID = data.enchantID
    enchantCell(row, data)
    local ownedText = OWNED_ICON[ns.Owned[data.id]] or ""
    if ownedText == "" and data.isDone then ownedText = "|cff33ff33Done|r" end
    row.owned:SetText(ownedText)
    row.doneKey, row.specKey, row.autoDone = data.doneKey, data.specKey, data.autoDone
    if data.doneKey then
        row.done:Show()
        row.done:SetChecked(data.isDone and true or false)
    else
        row.done:Hide()
    end
    row:SetAlpha(data.isDone and 0.6 or 1)

    ns.WithItem(data.id, function(item)
        if row.token ~= token then return end
        if not item then
            row.name:SetText("|cffff5555Unknown item " .. data.id .. "|r")
            return
        end
        row.itemLink = item:GetItemLink()
        row.itemName = item:GetItemName()
        row.icon.tex:SetTexture(item:GetItemIcon())
        local text = (row.itemLink or row.itemName or ""):gsub("[%[%]]", "")
        if row.isPre then text = "|cffffd100Needs:|r " .. text
        elseif row.isAlt then text = "|cff8fb8ffAlt:|r " .. text end
        row.name:SetText(text)
    end)
    row:Show()
end

----------------------------------------------------------------------
-- Refresh
----------------------------------------------------------------------
function ns.RefreshBrowser()
    if not frame or not frame:IsShown() then return end
    ensureSelection()
    local guide, fromPhase = currentGuide()
    local phase = selectedPhase()
    if not guide then return end

    -- items that weren't on this spec's list in the previous phase
    local prevSet
    local prevPhase
    for i = #ns.PhaseList, 1, -1 do
        if ns.PhaseList[i].id < fromPhase then prevPhase = ns.PhaseList[i].id break end
    end
    if prevPhase then
        local prevGuide = ns.GetGuide(ns.char.selectedClass, ns.char.selectedSpec, prevPhase)
        if prevGuide then prevSet = ns.GuideItemSet(prevGuide) end
    end

    phaseButton:SetText(ns.PhaseLabel(phase))
    classButton:SetText(classColorHex(ns.char.selectedClass) .. className(ns.char.selectedClass) .. "|r")
    specButton:SetText(ns.char.selectedSpec or "")
    slotButton:SetText("Slot: " .. (ns.char.selectedSlot or "All"))
    local mode = "bis"
    if ns.char.listMode == "realistic" and guide.realistic then mode = "realistic"
    elseif ns.char.listMode == "enchants" and guide.enchants then mode = "enchants"
    elseif ns.char.listMode == "consumables" and guide.consumables then mode = "consumables" end
    local gearList = mode == "bis" or mode == "realistic"
    local realistic = mode == "realistic"
    ns.UpdateListTabs(mode, guide)
    if headerAvoid then headerAvoid:SetShown(gearList and not frame.compact) end
    -- alternatives belong to the BiS list; "hide finished slots" to the gear lists
    if mode ~= "bis" then altCheck:Disable(); altLabel:SetAlpha(0.4) else altCheck:Enable(); altLabel:SetAlpha(1) end
    if mode == "consumables" then doneCheck:Disable(); doneLabel:SetAlpha(0.4) else doneCheck:Enable(); doneLabel:SetAlpha(1) end
    missingCheck:SetChecked(ns.char.missingOnly)
    altCheck:SetChecked(ns.char.showAlts ~= false)
    doneCheck:SetChecked(ns.char.hideDone)

    -- Done slots. Each main row has a key ("Head#1", "Finger#2"...) that is the
    -- same in the BiS and Realistic lists, so a slot can be done with a piece
    -- from either list. A key is done when you tick it, or automatically when
    -- you own enough of that slot's BiS / Realistic picks.
    local specKey = (ns.char.selectedClass or "") .. ":" .. (ns.char.selectedSpec or "")
    local canMark = gearList or mode == "enchants"
    local marks = ns.GetDoneMarks(specKey)
    local listRows = ns.GetGuideRows(guide, mode == "bis" and ns.char.showAlts ~= false, mode)
    local seenSlot = {}
    for _, r in ipairs(listRows) do
        if not r.isAlt and canMark then
            local n = r.slot == "Ammo" and 1 or ((seenSlot[r.slot] or 0) + 1)   -- one ammo slot
            seenSlot[r.slot] = n
            r.doneKey = (mode == "enchants" and "E:" or "") .. r.slot .. "#" .. n
        end
    end
    local auto = {}
    if gearList then
        local got, seen = {}, {}
        for _, m in ipairs({ "bis", "realistic" }) do
            for _, r in ipairs(ns.GetGuideRows(guide, false, m)) do
                if not r.isAlt and ns.Owned[r.id] and not seen[r.id] then
                    seen[r.id] = true
                    got[r.slot] = (got[r.slot] or 0) + 1
                end
            end
        end
        for slot, n in pairs(got) do
            for k = 1, n do auto[slot .. "#" .. k] = true end
        end
    end
    local slotKeys, slotDone = {}, {}
    for _, r in ipairs(listRows) do
        if r.doneKey then
            r.autoDone = auto[r.doneKey] or false
            -- a tick (true) or untick (false) overrides the automatic state
            if marks[r.doneKey] ~= nil then r.isDone = marks[r.doneKey] else r.isDone = r.autoDone end
            slotKeys[r.slot] = slotKeys[r.slot] or {}
            table.insert(slotKeys[r.slot], r)
        end
    end
    for slot, list in pairs(slotKeys) do
        local all = true
        for _, r in ipairs(list) do if not r.isDone then all = false end end
        slotDone[slot] = all
    end

    local list = {}
    local have, total = 0, 0
    for _, r in ipairs(listRows) do
        if not r.isAlt then
            total = total + 1
            if (canMark and r.isDone) or (not canMark and ns.Owned[r.id]) then have = have + 1 end
        end
    end
    for _, r in ipairs(listRows) do
        local owned = ns.Owned[r.id] ~= nil
        local slotOk = ns.char.selectedSlot == "All" or r.slot == ns.char.selectedSlot or mode == "consumables"
        local hidden = ns.char.hideDone and canMark and (r.doneKey and r.isDone or (not r.doneKey and slotDone[r.slot]))
        if slotOk and not hidden and not (ns.char.missingOnly and owned) then
            r.isNew = mode == "bis" and (not r.isAlt) and prevSet ~= nil and not prevSet[r.id]
            r.specKey = specKey
            r.enchantID = gearList and not r.isAlt and enchantFor(guide, r.slot) or nil
            table.insert(list, r)
        end
    end

    for i, data in ipairs(list) do
        fillRow(rows[i] or createRow(i), data)
    end
    for i = #list + 1, #rows do rows[i]:Hide() end
    scrollChild:SetHeight(math.max(1, #list * ROW_HEIGHT))

    countText:SetText(string.format(mode == "consumables" and "In bags %d / %d" or "Done %d / %d", have, total))
    -- keep the raid check companion on the spec being viewed
    if specKey ~= lastRaidSpec then
        lastRaidSpec = specKey
        if ns.RefreshRaidCheck then ns.RefreshRaidCheck() end
    end
    local info = ns.Phases[fromPhase]
    local text = ns.PhaseLabel(fromPhase) .. (info.subtitle and (" - " .. info.subtitle) or "")
        .. "  |  Data: " .. (info.source or "?") .. ", checked " .. (info.checked or "?")
    if realistic then
        text = text .. "  |  Realistic set: " .. (guide.realisticSource or "community guides")
    elseif mode == "enchants" then
        text = text .. "  |  Enchants: " .. (guide.enchantSource or "community guides")
    elseif mode == "consumables" then
        text = text .. "  |  Consumables: " .. (guide.consumableSource or "community guides")
    elseif guide.alts and #guide.alts > 0 and ns.char.showAlts ~= false then
        text = text .. "  |  Alternatives: " .. (guide.altSource or info.altSource or "community guides")
    end
    if fromPhase ~= phase then
        text = "|cffffd100No " .. ns.PhaseLabel(phase) .. " list for this spec yet, showing "
            .. ns.PhaseLabel(fromPhase) .. ".|r  " .. text
    end
    frame.sourceText:SetText(text)
end

ns.OnOwnedChanged = function() ns.RefreshBrowser() end

----------------------------------------------------------------------
-- Menus
----------------------------------------------------------------------
local function openMenu(owner, build)
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(owner, build)
    end
end

local function classMenu(owner)
    openMenu(owner, function(_, root)
        root:CreateTitle("Class")
        for _, cls in ipairs(ns.ClassOrder) do
            root:CreateRadio(classColorHex(cls) .. className(cls) .. "|r",
                function() return ns.char.selectedClass == cls end,
                function()
                    ns.char.selectedClass = cls
                    ns.char.selectedSpec = ns.GetSpecsForClass(cls)[1]
                    ns.RefreshBrowser()
                end)
        end
    end)
end

local function specMenu(owner)
    openMenu(owner, function(_, root)
        root:CreateTitle("Specialization")
        for _, spec in ipairs(ns.GetSpecsForClass(ns.char.selectedClass)) do
            root:CreateRadio(spec,
                function() return ns.char.selectedSpec == spec end,
                function() ns.char.selectedSpec = spec; ns.RefreshBrowser() end)
        end
    end)
end

local function phaseMenu(owner)
    openMenu(owner, function(_, root)
        root:CreateTitle("Phase")
        for _, p in ipairs(ns.PhaseList) do
            local label = p.label .. (p.subtitle and (" - " .. p.subtitle) or "")
            if p.id == ns.LatestPhase() then label = label .. " (current)" end
            root:CreateRadio(label,
                function() return selectedPhase() == p.id end,
                function()
                    -- remember "latest" as nil so new phases are picked up automatically
                    ns.char.selectedPhase = (p.id ~= ns.LatestPhase()) and p.id or nil
                    ns.RefreshBrowser()
                end)
        end
    end)
end

-- List tabs along the bottom edge of the window (like the character panel)
local LIST_TABS = {
    { mode = "bis",         text = "BiS",         tip = "The best pre-raid items." },
    { mode = "realistic",   text = "Realistic",   tip = "A set most players can finish in a week or two from dungeons, quests and Tier 0.5." },
    { mode = "enchants",    text = "Enchants",    tip = "The enchant, arcanum or armor kit for each slot." },
    { mode = "consumables", text = "Consumables", tip = "Raid shopping list: flask, elixirs, food, weapon oil or stone and potions." },
}

local function createListTabs()
    listTabs = {}
    for i, info in ipairs(LIST_TABS) do
        local name = "ForeverBiSFrameTab" .. i
        local ok, tab = pcall(CreateFrame, "Button", name, frame, "PanelTabButtonTemplate")
        if not ok or not tab then
            tab = CreateFrame("Button", name, frame, "UIPanelButtonTemplate")   -- fallback look
            tab:SetSize(100, 24)
        end
        tab:SetID(i)
        tab:SetText(info.text)
        if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 0) end
        if i == 1 then
            tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 12, 2)
        else
            tab:SetPoint("LEFT", listTabs[i - 1], "RIGHT", 3, 0)
        end
        tab:SetScript("OnClick", function()
            ns.char.listMode = info.mode
            if PlaySound and SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB then pcall(PlaySound, SOUNDKIT.IG_CHARACTER_INFO_TAB) end
            ns.RefreshBrowser()
        end)
        tab:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(info.text)
            GameTooltip:AddLine(info.tip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
        listTabs[i] = tab
    end
    frame.numTabs = #listTabs
    frame.Tabs = listTabs
end

-- Highlight the tab for the list on screen; grey out lists this spec lacks
function ns.UpdateListTabs(mode, guide)
    if not listTabs then return end
    local have = { bis = true, realistic = guide and guide.realistic ~= nil,
                   enchants = guide and guide.enchants ~= nil, consumables = guide and guide.consumables ~= nil }
    for i, info in ipairs(LIST_TABS) do
        local tab = listTabs[i]
        if info.mode == mode then
            if PanelTemplates_SelectTab then pcall(PanelTemplates_SelectTab, tab) else tab:LockHighlight() end
        elseif have[info.mode] then
            if PanelTemplates_EnableTab then pcall(PanelTemplates_EnableTab, frame, i) end
            if PanelTemplates_DeselectTab then pcall(PanelTemplates_DeselectTab, tab) else tab:UnlockHighlight(); tab:Enable() end
        else
            if PanelTemplates_DisableTab then pcall(PanelTemplates_DisableTab, frame, i) else tab:Disable() end
        end
    end
end

local function slotMenu(owner)
    openMenu(owner, function(_, root)
        root:CreateTitle("Slot")
        local opts = { "All" }
        for _, s in ipairs(ns.SlotOrder) do table.insert(opts, s) end
        for _, s in ipairs(opts) do
            root:CreateRadio(s,
                function() return ns.char.selectedSlot == s end,
                function() ns.char.selectedSlot = s; ns.RefreshBrowser() end)
        end
    end)
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
local function createFrame()
    frame = CreateFrame("Frame", "ForeverBiSFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(savedWidth(), ns.db.windowHeight or HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if ns.UpdateRaidCompanion then ns.UpdateRaidCompanion() end   -- re-pick the docking side
    end)
    frame:SetScale(ns.db.windowScale or 1)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
    else
        frame:SetMinResize(MIN_W, MIN_H); frame:SetMaxResize(MAX_W, MAX_H)
    end
    frame:Hide()
    tinsert(UISpecialFrames, "ForeverBiSFrame")

    frame:HookScript("OnShow", function()
        ns.UpdateCompact()
        if ns.UpdateRaidCompanion then ns.UpdateRaidCompanion() end
    end)
    frame:HookScript("OnHide", function()
        ns.UpdateCompact()      -- leave compact mode so the next open is normal size
        if ns.UpdateRaidCompanion then ns.UpdateRaidCompanion() end
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText(ns.title .. "  -  WoW Forever")

    phaseButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    phaseButton:SetSize(90, 24)
    phaseButton:SetPoint("TOPLEFT", 14, -32)
    phaseButton:SetScript("OnClick", phaseMenu)

    classButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    classButton:SetSize(110, 24)
    classButton:SetPoint("LEFT", phaseButton, "RIGHT", 6, 0)
    classButton:SetScript("OnClick", classMenu)

    specButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    specButton:SetSize(115, 24)
    specButton:SetPoint("LEFT", classButton, "RIGHT", 6, 0)
    specButton:SetScript("OnClick", specMenu)

    slotButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    createListTabs()

    slotButton:SetSize(95, 24)
    slotButton:SetPoint("LEFT", specButton, "RIGHT", 6, 0)
    slotButton:SetScript("OnClick", slotMenu)

    missingCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    missingCheck:SetSize(24, 24)
    missingCheck:SetPoint("LEFT", slotButton, "RIGHT", 10, 0)
    missingCheck:SetScript("OnClick", function(self)
        ns.char.missingOnly = self:GetChecked() and true or false
        ns.RefreshBrowser()
    end)
    local mcLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mcLabel:SetPoint("LEFT", missingCheck, "RIGHT", 2, 0)
    mcLabel:SetText("Missing only")

    altCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    altCheck:SetSize(24, 24)
    altCheck:SetPoint("LEFT", mcLabel, "RIGHT", 10, 0)
    altCheck:SetScript("OnClick", function(self)
        ns.char.showAlts = self:GetChecked() and true or false
        ns.RefreshBrowser()
    end)
    altLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    altLabel:SetPoint("LEFT", altCheck, "RIGHT", 2, 0)
    altLabel:SetText("Alternatives")

    doneCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    doneCheck:SetSize(24, 24)
    doneCheck:SetPoint("LEFT", altLabel, "RIGHT", 10, 0)
    doneCheck:SetScript("OnClick", function(self)
        ns.char.hideDone = self:GetChecked() and true or false
        ns.RefreshBrowser()
    end)
    doneCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Hide finished slots")
        GameTooltip:AddLine("Hides a slot once it's done: you own its BiS or Realistic item, or you ticked it done.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    doneCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
    doneLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    doneLabel:SetPoint("LEFT", doneCheck, "RIGHT", 2, 0)
    doneLabel:SetText("Hide finished")
    frame.wideOnly = { missingCheck, mcLabel, altCheck, altLabel, doneCheck, doneLabel }

    local raidButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    raidButton:SetSize(96, 20)
    raidButton:SetPoint("TOPRIGHT", -14, -60)
    raidButton:SetText("Raid check")
    raidButton:SetScript("OnClick", function() ns.ToggleRaidCheck() end)
    raidButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Raid check")
        GameTooltip:AddLine("Checks hit, defense, empty slots and enchants for your spec, and compares your gear's stats with the pre-raid BiS set.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    raidButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("RIGHT", raidButton, "LEFT", -10, 0)

    -- column headers
    local h1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h1:SetPoint("TOPLEFT", 18, -64)
    h1:SetText("ITEM")
    local h2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h2:SetPoint("TOPLEFT", 314, -64)
    headerSource = h2
    h2:SetText("WHERE TO GET IT")
    headerAvoid = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerAvoid:SetPoint("TOPLEFT", 560, -64)
    headerAvoid:SetText("ENCHANT")
    table.insert(frame.wideOnly, headerSource)
    table.insert(frame.wideOnly, headerAvoid)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -78)
    scroll:SetPoint("BOTTOMRIGHT", -32, 44)
    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(savedWidth() - 46, 1)

    -- resize grip in the bottom-right corner
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:SetFrameLevel(frame:GetFrameLevel() + 10)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    -- pin the top-left corner first so only the bottom-right edge follows the mouse
    local function pinTopLeft()
        local left, top = frame:GetLeft(), frame:GetTop()
        if left and top then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
    end
    grip:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        pinTopLeft()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function(_, button)
        if button ~= "LeftButton" then return end
        frame:StopMovingOrSizing()
        if not frame.compact then
            ns.db.windowWidth, ns.db.windowHeight = math.floor(frame:GetWidth()), math.floor(frame:GetHeight())
        end
        if ns.UpdateRaidCompanion then ns.UpdateRaidCompanion() end
    end)
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Drag to resize")
        GameTooltip:AddLine("Right-click to reset size", 1, 1, 1)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grip:SetScript("OnClick", function(_, button)
        if button ~= "RightButton" then return end
        pinTopLeft()
        frame:SetSize(WIDTH, HEIGHT)
        ns.db.windowWidth, ns.db.windowHeight = nil, nil
    end)

    frame:SetScript("OnSizeChanged", function(self, w)
        scrollChild:SetWidth(w - 46)
        if self.sourceText then self.sourceText:SetWidth(w - 240) end
        local sourceX, _, _, avoidX = columnLayout(w - 46)
        headerSource:SetPoint("TOPLEFT", sourceX + 14, -64)
        headerAvoid:SetPoint("TOPLEFT", avoidX + 14, -64)
        for _, row in ipairs(rows) do
            if row:IsShown() then layoutRow(row) end
        end
    end)
    scroll:SetScrollChild(scrollChild)

    -- footer
    frame.sourceText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.sourceText:SetPoint("BOTTOMLEFT", 16, 12)
    frame.sourceText:SetWidth(savedWidth() - 240)
    frame.sourceText:SetHeight(26)
    frame.sourceText:SetJustifyH("LEFT")
    frame.sourceText:SetJustifyV("MIDDLE")

    local guideLink = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    guideLink:SetSize(110, 22)
    guideLink:SetPoint("BOTTOMRIGHT", -26, 12)
    guideLink:SetText("Guide link")
    guideLink:SetScript("OnClick", function()
        local g = currentGuide()
        if g then
            ns.ShowLinkPopup(g.spec .. " " .. className(g.class) .. " - source guide", g.url)
        end
    end)

    local settings = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    settings:SetSize(80, 22)
    settings:SetPoint("RIGHT", guideLink, "LEFT", -6, 0)
    settings:SetText("Settings")
    settings:SetScript("OnClick", function() ns.OpenOptions() end)

    frame:SetScript("OnShow", function() ns.RefreshOwned(); ns.RefreshBrowser() end)
    -- apply the saved size to the columns once
    frame:GetScript("OnSizeChanged")(frame, frame:GetWidth(), frame:GetHeight())
end

function ns.ToggleBrowser()
    if not frame then createFrame() end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function ns.SetBrowserScale(scale)
    if frame then frame:SetScale(scale) end
end

----------------------------------------------------------------------
-- Compact mode: narrower window beside the character window
----------------------------------------------------------------------
local function setCompact(on)
    if not frame or (frame.compact or false) == on then return end
    if on then
        frame.savedPoints = {}
        for i = 1, (frame:GetNumPoints() or 0) do frame.savedPoints[i] = { frame:GetPoint(i) } end
        frame.savedWidth = frame:GetWidth()
        frame.compact = true
        if frame.SetResizeBounds then frame:SetResizeBounds(COMPACT_W - 60, MIN_H, MAX_W, MAX_H) end
        for _, w in ipairs(frame.wideOnly or {}) do w:Hide() end
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 6, 0)
        frame:SetWidth(COMPACT_W)
    else
        frame.compact = false
        if frame.SetResizeBounds then frame:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H) end
        for _, w in ipairs(frame.wideOnly or {}) do w:Show() end
        frame:ClearAllPoints()
        for _, p in ipairs(frame.savedPoints or {}) do frame:SetPoint(unpack(p)) end
        if not frame.savedPoints or #frame.savedPoints == 0 then frame:SetPoint("CENTER") end
        frame:SetWidth(frame.savedWidth or savedWidth())
    end
    -- re-run the layout for the new mode
    local onSize = frame:GetScript("OnSizeChanged")
    if onSize then onSize(frame, frame:GetWidth(), frame:GetHeight()) end
    ns.RefreshBrowser()
    if ns.UpdateRaidCompanion then ns.UpdateRaidCompanion() end
end

-- Compact while both windows are open (and the setting is on)
function ns.UpdateCompact()
    if not frame then return end
    local charOpen = CharacterFrame and CharacterFrame:IsShown()
    setCompact((frame:IsShown() and charOpen and ns.db.compactWithCharacter) and true or false)
end

ns.On("PLAYER_LOGIN", function()
    if CharacterFrame and CharacterFrame.HookScript then
        CharacterFrame:HookScript("OnShow", ns.UpdateCompact)
        CharacterFrame:HookScript("OnHide", ns.UpdateCompact)
    end
end)
