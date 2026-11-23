local _, ns = ...

local ROW_HEIGHT = 40
local WIDTH, HEIGHT = 720, 540

local frame, scrollChild, rows = nil, nil, {}
local classButton, specButton, phaseButton, slotButton, missingCheck, countText

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

----------------------------------------------------------------------
-- Rows
----------------------------------------------------------------------
local function otherSpecsText(itemID)
    local entries = ns.ItemIndex[itemID]
    if not entries then return "" end
    local seen, parts = {}, {}
    local phase = selectedPhase()
    for _, e in ipairs(entries) do
        local g = e.guide
        local key = g.class .. g.spec
        if ns.EntryActiveIn(e, phase) and not seen[key]
            and not (g.class == ns.char.selectedClass and g.spec == ns.char.selectedSpec) then
            seen[key] = true
            table.insert(parts, classColorHex(g.class) .. g.spec .. " " .. className(g.class) .. "|r")
        end
    end
    if #parts == 0 then return "" end
    if #parts > 4 then
        local n = #parts - 4
        parts = { parts[1], parts[2], parts[3], parts[4], "+" .. n .. " more" }
    end
    return "Also BiS: " .. table.concat(parts, ", ")
end

local function createRow(i)
    local row = CreateFrame("Frame", nil, scrollChild)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0)

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

    row.source = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.source:SetPoint("TOPLEFT", 300, -5)
    row.source:SetWidth(250)
    row.source:SetJustifyH("LEFT")
    row.source:SetWordWrap(false)

    row.also = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.also:SetPoint("BOTTOMLEFT", 300, 5)
    row.also:SetWidth(250)
    row.also:SetJustifyH("LEFT")
    row.also:SetWordWrap(false)

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

    row.owned = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.owned:SetPoint("RIGHT", link, "LEFT", -6, 0)
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

    row.icon.tex:SetTexture(C_Item.GetItemIconByID(data.id) or 134400)
    row.name:SetText("|cff888888Loading item " .. data.id .. "...|r")
    local slotText = data.slot
    if data.isNew then slotText = "|cff1eff00NEW|r  " .. slotText end
    if data.faction then slotText = slotText .. "  |cffffd100(" .. data.faction .. ")|r" end
    row.slot:SetText(slotText)
    row.source:SetText(data.source or "")
    row.also:SetText(otherSpecsText(data.id))
    row.owned:SetText(OWNED_ICON[ns.Owned[data.id]] or "")

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
    missingCheck:SetChecked(ns.char.missingOnly)

    local list = {}
    local have = 0
    for _, r in ipairs(ns.GetGuideRows(guide)) do
        local owned = ns.Owned[r.id] ~= nil
        if owned then have = have + 1 end
        local slotOk = ns.char.selectedSlot == "All" or r.slot == ns.char.selectedSlot
        if slotOk and not (ns.char.missingOnly and owned) then
            r.isNew = prevSet ~= nil and not prevSet[r.id]
            table.insert(list, r)
        end
    end
    local total = #guide.items

    for i, data in ipairs(list) do
        fillRow(rows[i] or createRow(i), data)
    end
    for i = #list + 1, #rows do rows[i]:Hide() end
    scrollChild:SetHeight(math.max(1, #list * ROW_HEIGHT))

    countText:SetText(string.format("You own %d / %d", have, total))
    local info = ns.Phases[fromPhase]
    local text = ns.PhaseLabel(fromPhase) .. (info.subtitle and (" - " .. info.subtitle) or "")
        .. "  |  Data: " .. (info.source or "?") .. ", checked " .. (info.checked or "?")
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
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScale(ns.db.windowScale or 1)
    frame:Hide()
    tinsert(UISpecialFrames, "ForeverBiSFrame")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText(ns.title .. "  -  WoW Forever")

    phaseButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    phaseButton:SetSize(90, 24)
    phaseButton:SetPoint("TOPLEFT", 14, -32)
    phaseButton:SetScript("OnClick", phaseMenu)

    classButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    classButton:SetSize(120, 24)
    classButton:SetPoint("LEFT", phaseButton, "RIGHT", 6, 0)
    classButton:SetScript("OnClick", classMenu)

    specButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    specButton:SetSize(120, 24)
    specButton:SetPoint("LEFT", classButton, "RIGHT", 6, 0)
    specButton:SetScript("OnClick", specMenu)

    slotButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    slotButton:SetSize(110, 24)
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

    countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("TOPRIGHT", -18, -38)

    -- column headers
    local h1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h1:SetPoint("TOPLEFT", 18, -64)
    h1:SetText("ITEM")
    local h2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h2:SetPoint("TOPLEFT", 314, -64)
    h2:SetText("WHERE TO GET IT")

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -78)
    scroll:SetPoint("BOTTOMRIGHT", -32, 44)
    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(WIDTH - 46, 1)
    scroll:SetScrollChild(scrollChild)

    -- footer
    frame.sourceText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.sourceText:SetPoint("BOTTOMLEFT", 16, 12)
    frame.sourceText:SetWidth(WIDTH - 240)
    frame.sourceText:SetHeight(26)
    frame.sourceText:SetJustifyH("LEFT")
    frame.sourceText:SetJustifyV("MIDDLE")

    local guideLink = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    guideLink:SetSize(110, 22)
    guideLink:SetPoint("BOTTOMRIGHT", -14, 12)
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
end

function ns.ToggleBrowser()
    if not frame then createFrame() end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function ns.SetBrowserScale(scale)
    if frame then frame:SetScale(scale) end
end
