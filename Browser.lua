local _, ns = ...

local ROW_HEIGHT = 40
local frame, scrollChild, rows = nil, nil, {}
local WIDTH, HEIGHT = 900, 540          -- default size
local MIN_W, MIN_H, MAX_W, MAX_H = 880, 320, 1500, 1100
local headerSource                      -- "WHERE TO GET IT" column header

-- saved window width, never narrower than the controls need
local function savedWidth()
    return math.max(MIN_W, ns.db.windowWidth or WIDTH)
end

-- Column positions follow the window width
local function columnLayout(contentWidth)
    local sourceX = math.max(300, math.floor(contentWidth * 0.42))
    local nameW = sourceX - 50
    local sourceW = math.max(180, contentWidth - sourceX - 170)
    return sourceX, nameW, sourceW
end

local function layoutRow(row)
    local sourceX, nameW, sourceW = columnLayout(scrollChild:GetWidth())
    row.name:SetWidth(nameW - (row.isAlt and 18 or 0))
    row.slot:SetWidth(nameW)
    row.source:SetPoint("TOPLEFT", sourceX, -5)
    row.source:SetWidth(sourceW)
    row.also:SetPoint("BOTTOMLEFT", sourceX, 5)
    row.also:SetWidth(sourceW)
end

local classButton, specButton, phaseButton, listButton, slotButton, missingCheck, altCheck, altLabel, doneCheck, doneLabel, countText

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
    row.slot:SetText(slotText)
    local src = data.source or ""
    if data.note then src = src .. "  |cffaaaaaa(" .. data.note .. ")|r" end
    row.source:SetText(src)
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
    elseif ns.char.listMode == "enchants" and guide.enchants then mode = "enchants" end
    local realistic = mode == "realistic"
    listButton:SetText(mode == "realistic" and "List: Realistic" or mode == "enchants" and "List: Enchants" or "List: BiS")
    -- alternatives belong to the BiS list; "hide finished slots" to the gear lists
    if mode ~= "bis" then altCheck:Disable(); altLabel:SetAlpha(0.4) else altCheck:Enable(); altLabel:SetAlpha(1) end
    if mode == "enchants" then doneCheck:Disable(); doneLabel:SetAlpha(0.4) else doneCheck:Enable(); doneLabel:SetAlpha(1) end
    missingCheck:SetChecked(ns.char.missingOnly)
    altCheck:SetChecked(ns.char.showAlts ~= false)
    doneCheck:SetChecked(ns.char.hideDone)

    -- A slot is finished once you own its BiS pick or its Realistic pick
    -- (Finger / Trinket need as many as the list has).
    local doneSlot = {}
    if ns.char.hideDone and mode ~= "enchants" then
        local need, got, seen = {}, {}, {}
        for _, r in ipairs(ns.GetGuideRows(guide, false, mode)) do
            if not r.isAlt then need[r.slot] = (need[r.slot] or 0) + 1 end
        end
        for _, m in ipairs({ "bis", "realistic" }) do
            for _, r in ipairs(ns.GetGuideRows(guide, false, m)) do
                if not r.isAlt and ns.Owned[r.id] and not seen[r.id] then
                    seen[r.id] = true
                    got[r.slot] = (got[r.slot] or 0) + 1
                end
            end
        end
        for slot, n in pairs(need) do
            if (got[slot] or 0) >= n then doneSlot[slot] = true end
        end
    end

    local list = {}
    local have = 0
    local listRows = ns.GetGuideRows(guide, mode == "bis" and ns.char.showAlts ~= false, mode)
    local total = 0
    for _, r in ipairs(listRows) do if not r.isAlt then total = total + 1 end end
    for _, r in ipairs(listRows) do
        local owned = ns.Owned[r.id] ~= nil
        if owned and not r.isAlt then have = have + 1 end
        local slotOk = ns.char.selectedSlot == "All" or r.slot == ns.char.selectedSlot
        if slotOk and not doneSlot[r.slot] and not (ns.char.missingOnly and owned) then
            r.isNew = mode == "bis" and (not r.isAlt) and prevSet ~= nil and not prevSet[r.id]
            table.insert(list, r)
        end
    end

    for i, data in ipairs(list) do
        fillRow(rows[i] or createRow(i), data)
    end
    for i = #list + 1, #rows do rows[i]:Hide() end
    scrollChild:SetHeight(math.max(1, #list * ROW_HEIGHT))

    countText:SetText(string.format("You own %d / %d", have, total))
    local info = ns.Phases[fromPhase]
    local text = ns.PhaseLabel(fromPhase) .. (info.subtitle and (" - " .. info.subtitle) or "")
        .. "  |  Data: " .. (info.source or "?") .. ", checked " .. (info.checked or "?")
    if realistic then
        text = text .. "  |  Realistic set: " .. (guide.realisticSource or "community guides")
    elseif mode == "enchants" then
        text = text .. "  |  Enchants: " .. (guide.enchantSource or "community guides")
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

local function listMenu(owner)
    openMenu(owner, function(_, root)
        root:CreateTitle("Gear list")
        root:CreateRadio("BiS (best available)",
            function() return ns.char.listMode ~= "realistic" and ns.char.listMode ~= "enchants" end,
            function() ns.char.listMode = "bis"; ns.RefreshBrowser() end)
        root:CreateRadio("Realistic (quick to collect)",
            function() return ns.char.listMode == "realistic" end,
            function() ns.char.listMode = "realistic"; ns.RefreshBrowser() end)
        root:CreateRadio("Enchants",
            function() return ns.char.listMode == "enchants" end,
            function() ns.char.listMode = "enchants"; ns.RefreshBrowser() end)
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
    frame:SetSize(savedWidth(), ns.db.windowHeight or HEIGHT)
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
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
    else
        frame:SetMinResize(MIN_W, MIN_H); frame:SetMaxResize(MAX_W, MAX_H)
    end
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
    classButton:SetSize(110, 24)
    classButton:SetPoint("LEFT", phaseButton, "RIGHT", 6, 0)
    classButton:SetScript("OnClick", classMenu)

    specButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    specButton:SetSize(115, 24)
    specButton:SetPoint("LEFT", classButton, "RIGHT", 6, 0)
    specButton:SetScript("OnClick", specMenu)

    slotButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    listButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    listButton:SetSize(110, 24)
    listButton:SetPoint("LEFT", specButton, "RIGHT", 6, 0)
    listButton:SetScript("OnClick", listMenu)
    listButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Gear list")
        GameTooltip:AddLine("BiS: the best pre-raid items.", 1, 1, 1, true)
        GameTooltip:AddLine("Realistic: a set most players can finish in a week or two from dungeons, quests and Tier 0.5.", 1, 1, 1, true)
        GameTooltip:AddLine("Enchants: the enchant, arcanum or armor kit for each slot.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    listButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    slotButton:SetSize(95, 24)
    slotButton:SetPoint("LEFT", listButton, "RIGHT", 6, 0)
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
        GameTooltip:AddLine("Hides a slot once you own its BiS item or its Realistic item.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    doneCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
    doneLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    doneLabel:SetPoint("LEFT", doneCheck, "RIGHT", 2, 0)
    doneLabel:SetText("Hide finished")

    countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("TOPRIGHT", -40, -62)

    -- column headers
    local h1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h1:SetPoint("TOPLEFT", 18, -64)
    h1:SetText("ITEM")
    local h2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h2:SetPoint("TOPLEFT", 314, -64)
    headerSource = h2
    h2:SetText("WHERE TO GET IT")

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
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        ns.db.windowWidth, ns.db.windowHeight = math.floor(frame:GetWidth()), math.floor(frame:GetHeight())
    end)
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Drag to resize")
        GameTooltip:AddLine("Double-click to reset size", 1, 1, 1)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grip:SetScript("OnDoubleClick", function()
        frame:SetSize(WIDTH, HEIGHT)
        ns.db.windowWidth, ns.db.windowHeight = nil, nil
    end)

    frame:SetScript("OnSizeChanged", function(self, w)
        scrollChild:SetWidth(w - 46)
        if self.sourceText then self.sourceText:SetWidth(w - 240) end
        local sourceX = columnLayout(w - 46)
        headerSource:SetPoint("TOPLEFT", sourceX + 14, -64)
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
