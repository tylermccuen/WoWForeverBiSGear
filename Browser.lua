local _, ns = ...

local ROW_HEIGHT = 40
local frame, scrollChild, rows = nil, nil, {}
local CHECK_ICON = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t "
local YELLOW_CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:16:16:0:0:64:64:0:64:0:64:255:210:0|t"
local GREEN_CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:16:16|t"
local lastRaidSpec
local WIDTH, HEIGHT = 1040, 540          -- default size
local MIN_W, MIN_H, MAX_W, MAX_H = 920, 320, 1500, 1100
local headerSource, headerAvoid        -- "WHERE TO GET IT" / "ENCHANT" headers

-- saved window width, never narrower than the controls need
local function savedWidth()
    return math.max(MIN_W, ns.db.windowWidth or WIDTH)
end

-- Column positions follow the window width
local COMPACT_W = 660   -- width beside the character window

-- Column positions. Gear tabs: item | dungeon | boss / source | drop | enchant.
-- Consumables / Enchants: item | recipe | materials. Compact: item | source | drop.
local function columnLayout(contentWidth)
    local L = { dungeonW = 0, dropW = 0 }
    local gear = frame and (frame.layoutMode == nil or frame.layoutMode == "bis" or frame.layoutMode == "realistic"
        or frame.layoutMode == "ranked")
    if frame and frame.compact then
        L.nameW = 180
        L.sourceX = L.nameW + 50
        L.dropW = gear and 40 or 0
        L.sourceW = math.max(140, contentWidth - L.sourceX - 130 - L.dropW - (gear and 8 or 0))
        L.dropX = L.sourceX + L.sourceW + 8
        L.avoidX, L.avoidW = L.dropX + L.dropW, 0
        L.dungeonX = L.sourceX
        return L
    end
    local firstX = math.max(250, math.floor(contentWidth * 0.28))
    L.nameW = firstX - 50
    local rest = math.max(360, contentWidth - firstX - 200)   -- 200 = owned / done / link
    if gear then
        local enchantW, dropW = 140, 44
        if frame.layoutMode == "ranked" then enchantW = 0 end   -- Gear tab: enchants have their own tab
        local inner = math.max(200, rest - enchantW - dropW - 30)
        L.dungeonX, L.dungeonW = firstX, math.floor(inner * 0.42)
        L.sourceX = L.dungeonX + L.dungeonW + 10
        L.sourceW = inner - L.dungeonW
        L.dropX, L.dropW = L.sourceX + L.sourceW + 10, dropW
        L.avoidX, L.avoidW = L.dropX + dropW + 10, enchantW
    else
        -- Enchants / Consumables: skill | where to get the recipe | materials
        local matsW = math.floor(rest * 0.42)
        local skillW = 96
        L.dungeonX, L.dungeonW = firstX, skillW
        L.sourceX = firstX + skillW + 10
        L.sourceW = math.max(160, rest - skillW - matsW - 20)
        L.dropX = L.sourceX + L.sourceW
        L.avoidX, L.avoidW = L.sourceX + L.sourceW + 10, rest - skillW - L.sourceW - 20
    end
    return L
end

-- "Stratholme: Baron Rivendare" -> "Stratholme", "Baron Rivendare"
-- "Quest: The Princess Saved? (Blackrock Depths)" -> "Blackrock Depths", "Quest: The Princess Saved?"
-- "Dungeon Set 2 quest: Saving the Best for Last" -> "Dungeon Set 2", "Quest: Saving the Best for Last"
function ns.SplitSource(source)
    if type(source) ~= "string" or source == "" then return "", "" end
    local q = source:match("^Quest: (.+)$")
    if q then
        local name, zone = q:match("^(.-)%s*%(([^()]*)%)$")
        if not zone and ns.Quests then
            -- no place in the source: use where the quest is picked up
            local first = q:match("^(.-)%s*/") or q
            local e = ns.Quests[first] and ns.Quests[first][1]
            zone = e and e[3] ~= "" and e[3] or nil
        end
        return zone or "", "Quest: " .. (name or q)
    end
    local prefix, qname = source:match("^(.-) quest: (.+)$")
    if prefix then
        if prefix == "Dungeon Set 2" then prefix = "Tier 0.5 set" end
        return prefix, "Quest: " .. qname
    end
    -- faction rewards: "Darkspear Raiders (Exalted)", "X reputation (Revered)"
    local faction, standing = source:match("^([^:]-) %((%a+)%)$")
    if faction and (standing == "Exalted" or standing == "Revered" or standing == "Honored" or standing == "Friendly") then
        faction = faction:gsub(" reputation$", "")
        local place = faction:find("Stormpike") and "Alterac Valley" or "Reputation"
        return place, faction .. " (" .. standing .. ")"
    end
    if source:match("^World drop") then
        return "World Drop", source:match("%((.-)%)") and ("Any Mob (" .. source:match("%((.-)%)") .. ")") or "Any Mob"
    end
    local prof = source:match("^Crafted: (.+)$")
    if prof then return "Crafted", prof end
    local trash = source:match("^Random trash drop %((.-)%)$")
    if trash then return trash, "Trash Drop" end
    local where, rest = source:match("^(.-):%s*(.+)$")
    if where then return where, rest end
    return "", source
end

-- Drop chance (percent) of an item from the boss its source names
function ns.DropChance(itemID, source)
    local list = ns.DropRates and ns.DropRates[itemID]
    if not list then return nil end
    if type(source) == "string" then
        for _, e in ipairs(list) do
            if source:find(e[1], 1, true) then return e[2] end
        end
    end
    return list[1][2]
end

function ns.FormatChance(p)
    if p >= 10 then return string.format("%d%%", math.floor(p + 0.5)) end
    return string.format("%.1f%%", p)
end

-- Sort the gear list by ns.char.sortBy; alternatives / Tier 0 rows stay
-- under their main item.
function ns.SortRows(list)
    local by = ns.char.sortBy or "slot"
    if by == "slot" and not ns.char.sortDesc then return list end
    local blocks = {}
    for i, r in ipairs(list) do
        if r.isAlt and #blocks > 0 then
            table.insert(blocks[#blocks].rows, r)
        else
            table.insert(blocks, { main = r, rows = { r }, index = i })
        end
    end
    local function key(r)
        if r.craft ~= nil or r.craftTab then
            -- Enchants / Consumables: SKILL and WHERE TO GET IT columns
            if by == "dungeon" then
                return (r.craft and r.craft.skill) or -1
            elseif by == "boss" then
                local from = (r.craft and (r.craft.from or "~")) or r.source or "~"
                return from:lower()
            end
            return 0
        end
        if by == "dungeon" then
            local d = ns.SplitSource(r.source)
            return d == "" and "~" or d:lower()
        elseif by == "boss" then
            local _, b = ns.SplitSource(r.source)
            return b:lower()
        elseif by == "drop" then
            return ns.DropChance(r.id, r.source) or -1
        end
        return 0
    end
    for _, b in ipairs(blocks) do b.key = key(b.main) end
    local desc = ns.char.sortDesc
    table.sort(blocks, function(a, b)
        if a.key == b.key then return a.index < b.index end
        if desc then return a.key > b.key end
        return a.key < b.key
    end)
    local out = {}
    for _, b in ipairs(blocks) do
        for _, r in ipairs(b.rows) do table.insert(out, r) end
    end
    return out
end

-- Header positions and labels for the current tab and width
function ns.LayoutHeaders()
    if not frame or not frame.headers then return end
    local H = frame.headers
    local L = columnLayout(scrollChild:GetWidth())
    local mode = frame.layoutMode or "ranked"
    local gear = mode == "bis" or mode == "realistic" or mode == "ranked"
    local crafting = mode == "consumables" or mode == "enchants"
    local function place(h, x, text, shown)
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 14, -62)
        local arrow = ""
        if (gear or crafting) and h.sortKey and (ns.char.sortBy or "slot") == h.sortKey then
            arrow = ns.char.sortDesc and " v" or " ^"
        end
        h:SetText(text .. arrow)
        h:SetShown(shown)
    end
    place(H.item, 4, "ITEM", true)
    place(H.dungeon, L.dungeonX, crafting and "SKILL" or "DUNGEON", (gear or crafting) and L.dungeonW > 0)
    place(H.source, L.sourceX, crafting and "WHERE TO GET IT"
        or (frame.compact and "WHERE TO GET IT" or "BOSS / SOURCE"), true)
    place(H.drop, L.dropX, "DROP", gear and L.dropW > 0)
    place(H.avoid, L.avoidX, crafting and "MATERIALS" or "ENCHANT", not frame.compact and L.avoidW > 0)
    -- sorting: gear tabs (all columns), Enchants / Consumables (item, skill, where)
    for _, h in pairs(H) do
        if h.sortKey then h:EnableMouse(gear or (crafting and h.sortKey ~= "drop")) end
        if frame.podiumOn then h:Hide() end   -- podium cards have no columns
    end
end

local function layoutRow(row)
    local L = columnLayout(scrollChild:GetWidth())
    row.name:SetWidth(L.nameW - (row.isAlt and 18 or 0) - (row.place and 24 or 0)
        - (row.more and row.more:IsShown() and 62 or 0))
    if row.more then
        row.more:ClearAllPoints()
        row.more:SetPoint("RIGHT", row, "LEFT", L.dungeonX - 8, 0)
    end
    row.slot:SetWidth(L.nameW)
    row.dungeon:ClearAllPoints()
    row.dungeon:SetPoint("LEFT", L.dungeonX, 0)
    row.dungeon:SetWidth(math.max(1, L.dungeonW))
    row.dungeon:SetShown(L.dungeonW > 0)
    row.source:ClearAllPoints()
    row.source:SetPoint("LEFT", L.sourceX, 0)
    row.source:SetWidth(L.sourceW)
    row.drop:ClearAllPoints()
    row.drop:SetPoint("LEFT", L.dropX, 0)
    row.drop:SetWidth(math.max(1, L.dropW))
    row.drop:SetShown(L.dropW > 0)
    row.avoid:ClearAllPoints()
    row.avoid:SetPoint("LEFT", L.avoidX, 0)
    row.avoid:SetWidth(math.max(1, L.avoidW))
    row.avoid:SetShown(not frame.compact and L.avoidW > 0)
end

local classButton, specButton, phaseButton, listTabs, slotButton, missingCheck, altCheck, altLabel, doneCheck, doneLabel, countText, viewButton

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
    -- open on your real spec (from talent points), like the gold-ringed icon
    local _, mySpec = ns.GetActiveSpec()
    ns.char.selectedSpec = mySpec or ns.GetSpecsForClass(playerClass)[1]
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
        if e[1] == slot then return e[2], e.note, e[3] end
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

-- "30 Gromsblood, 1 Crystal Vial" for crafted consumables / enchants
local function itemIcon(id)
    local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
    if not icon and GetItemIcon then icon = GetItemIcon(id) end
    return icon
end

local function materialsText(craft, withIcons)
    local parts = {}
    for _, m in ipairs(craft.mats or {}) do
        local icon = withIcons and itemIcon(m[1])
        if icon then
            -- one material per line: icon, amount, name, and how many you have
            local have = 0
            local count = (C_Item and C_Item.GetItemCount) or GetItemCount
            if count then
                local ok, n = pcall(count, m[1], true)
                have = ok and tonumber(n) or 0
            end
            local haveText = have >= m[2] and ("  |cff33ff33have " .. have .. "|r")
                or (have > 0 and ("  |cffffd100have " .. have .. "|r") or "")
            table.insert(parts, "|T" .. icon .. ":14:14:0:0|t |cffffffff" .. m[2] .. " " .. m[3] .. "|r" .. haveText)
        else
            table.insert(parts, m[2] .. " " .. m[3])
        end
    end
    return table.concat(parts, withIcons and "\n" or ", ")
end

-- "Vendor: Beneris / Alynsia (120 Merchant's Favor)" -> two lines: who, then
-- the part in brackets (cost, zone, reputation) on its own line
function ns.SourceLines(src)
    if type(src) ~= "string" then return src end
    local main, extra = src:match("^(.-)%s*%((.+)%)%s*$")
    if main and main ~= "" and not main:find("%(") then
        return main .. "\n|cffd0d0d0" .. extra .. "|r"
    end
    return src
end

-- Enchants / Consumables rows grow to fit one material per line, and the
-- where-to-get-it lines
local function craftRowHeight(data)
    local n = data.craft and data.craft.mats and #data.craft.mats or 0
    local from = (data.craft and data.craft.from) or data.source or ""
    local srcLines = 1 + (from:find("%(.+%)%s*$") and 1 or 0) + (data.note and 1 or 0)
    if #from > 46 then srcLines = srcLines + 1 end   -- a long first line wraps
    return math.max(ROW_HEIGHT, n * 15 + 10, srcLines * 14 + 10)
end

local function enchantCell(row, data)
    if data.craft then
        if row.avoid.SetMaxLines then row.avoid:SetMaxLines(8) end
        row.avoid:SetText(materialsText(data.craft, true))
        return
    end
    if row.avoid.SetMaxLines then row.avoid:SetMaxLines(2) end
    local id = data.enchantID
    if not id then
        row.avoid:SetText(data.craftTab and "|cff666666-|r" or "")
        return
    end
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
            questTitles[info.title:lower()] = { id = info.questID, index = i, title = info.title }
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

-- The first quest from a source that's in your quest log: { id, index, title }
function ns.QuestInLog(source)
    if type(source) ~= "string" then return nil end
    local names = source:match("[Qq]uest: (.+)$")
    if not names then return nil end
    names = names:gsub("%s*%b()%s*$", "")
    for name in (names .. " / "):gmatch("(.-) / ") do
        local q = questTitles[name:lower()]
        if q then return q end
    end
end

-- Open the quest log on a quest (whichever quest log this client has)
function ns.OpenQuestLog(q)
    if not q then return end
    local ok = false
    if q.id and QuestMapFrame_OpenToQuestDetails then
        ok = pcall(QuestMapFrame_OpenToQuestDetails, q.id)
    end
    if not ok and QuestLogFrame and q.index then
        ok = pcall(function()
            ShowUIPanel(QuestLogFrame)
            if SelectQuestLogEntry then SelectQuestLogEntry(q.index) end
            if QuestLog_Update then QuestLog_Update() end
        end)
    end
    if not ok and q.id and C_QuestLog and C_QuestLog.SetSelectedQuest then
        ok = pcall(function()
            C_QuestLog.SetSelectedQuest(q.id)
            if ToggleQuestLog then ToggleQuestLog() end
        end)
    end
    if not ok then ns.Print("Couldn't open the quest log on " .. (q.title or "that quest") .. ".") end
end

ns.On("QUEST_LOG_UPDATE", function()
    scanQuestLog()
    if frame and frame:IsShown() then ns.RefreshBrowser() end
end)
ns.On("PLAYER_LOGIN", scanQuestLog)
ns.ScanQuestLog = scanQuestLog   -- used by tools/uitest.lua

-- Your specs bar: class icons in the title bar, left of the close button.
-- The first is always your own active spec (gold ring); then up to 5 saved
-- specs; then "+" to save the spec on screen. (In the title bar they can't
-- run into the checkboxes on the button row.)
local function classIcon(cls)
    return "Interface\\Icons\\ClassIcon_" .. (cls:sub(1, 1) .. cls:sub(2):lower())
end

local function makeSpecButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(18, 18)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b.ring = b:CreateTexture(nil, "BACKGROUND")
    b.ring:SetPoint("TOPLEFT", -1, 1)
    b.ring:SetPoint("BOTTOMRIGHT", 1, -1)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("CENTER", 0, 1)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    return b
end

function ns.UpdateSpecBar()
    if not frame or not frame.specBar then return end
    local bar = frame.specBar
    local list = ns.GetMySpecList()
    local selCls, selSpec = ns.char.selectedClass, ns.char.selectedSpec
    for i = 1, ns.MAX_SAVED_SPECS + 1 do
        local b = bar.buttons[i]
        local f = list[i]
        if f then
            b.entry = f
            b.icon:SetTexture(classIcon(f.class))
            b.icon:Show()
            b.text:SetText("")
            local selected = f.class == selCls and f.spec == selSpec
            if f.mine then b.ring:SetColorTexture(1, 0.82, 0, 1)
            elseif selected then b.ring:SetColorTexture(1, 1, 1, 0.9)
            else b.ring:SetColorTexture(0, 0, 0, 0.6) end
            b.icon:SetDesaturated(not selected)
            b:Show()
        else
            b:Hide()
        end
    end
    -- "+" to save the spec on screen
    local plus = bar.plus
    local mc, ms = ns.GetActiveSpec()
    local canSave = selCls and selSpec and not (selCls == mc and selSpec == ms)
        and not ns.IsSavedSpec(selCls, selSpec) and #ns.GetSavedSpecs() < ns.MAX_SAVED_SPECS
    plus:SetShown(canSave and true or false)
    -- lay out right to left: "+" last
    local x = 0
    local shown = {}
    for i = 1, ns.MAX_SAVED_SPECS + 1 do if bar.buttons[i]:IsShown() then table.insert(shown, bar.buttons[i]) end end
    if plus:IsShown() then table.insert(shown, plus) end
    for i = #shown, 1, -1 do
        shown[i]:ClearAllPoints()
        shown[i]:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -x, 0)
        x = x + 22
    end
end

local function createSpecBar()
    local bar = CreateFrame("Frame", nil, frame)
    bar:SetSize(160, 18)
    bar:SetPoint("TOPRIGHT", -28, -3)
    bar:SetFrameLevel(frame:GetFrameLevel() + 5)
    bar.buttons = {}
    for i = 1, ns.MAX_SAVED_SPECS + 1 do
        local b = makeSpecButton(bar)
        b:SetScript("OnClick", function(self, button)
            local f = self.entry
            if not f then return end
            if button == "RightButton" then
                if not f.mine then ns.RemoveSavedSpec(f.class, f.spec); ns.RefreshBrowser()
                elseif MenuUtil and MenuUtil.CreateContextMenu then
                    -- pick your spec by hand when the talents can't tell
                    MenuUtil.CreateContextMenu(self, function(_, root)
                        root:CreateTitle("Your spec")
                        for _, sp in ipairs(ns.GetSpecsForClass(f.class)) do
                            root:CreateRadio(sp, function() return f.spec == sp end, function()
                                ns.char.mySpec = sp
                                ns.char.selectedClass, ns.char.selectedSpec = f.class, sp
                                ns.RefreshBrowser()
                            end)
                        end
                    end)
                end
                return
            end
            ns.char.selectedClass, ns.char.selectedSpec = f.class, f.spec
            ns.RefreshBrowser()
        end)
        b:SetScript("OnEnter", function(self)
            local f = self.entry
            if not f then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(classColorHex(f.class) .. f.spec .. " " .. className(f.class) .. "|r")
            if f.mine then
                GameTooltip:AddLine("Your spec", 1, 0.82, 0)
                if ns.SpecFromTalents and ns.SpecFromTalents() then
                    GameTooltip:AddLine("Picked from where your talent points are.", 0.8, 0.8, 0.8, true)
                else
                    GameTooltip:AddLine("Right-click to choose your spec if this is wrong.", 0.8, 0.8, 0.8, true)
                end
            else
                GameTooltip:AddLine("Saved spec. Right-click to remove.", 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        bar.buttons[i] = b
    end
    local plus = makeSpecButton(bar)
    plus.icon:Hide()
    plus.ring:SetColorTexture(1, 1, 1, 0.12)
    plus.text:SetText("+")
    plus:SetScript("OnClick", function()
        if ns.SaveSpec(ns.char.selectedClass, ns.char.selectedSpec) then ns.RefreshBrowser() end
    end)
    plus:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Save " .. (ns.char.selectedSpec or "") .. " " .. className(ns.char.selectedClass or "") .. " to your specs")
        GameTooltip:AddLine("Keep up to 5 for quick switching. Your own spec is always first.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    plus:SetScript("OnLeave", function() GameTooltip:Hide() end)
    bar.plus = plus
    frame.specBar = bar
end

----------------------------------------------------------------------
-- Sleek window style: a flat dark panel with a thin gold border and flat
-- buttons and tabs, in place of the stone frame and red buttons
----------------------------------------------------------------------
local SLEEK = {
    bg = { 0.07, 0.06, 0.045, 0.97 }, edge = { 0.42, 0.34, 0.22, 1 }, line = { 0.3, 0.24, 0.16, 1 },
    titleTop = { 0.17, 0.13, 0.09, 1 }, titleBottom = { 0.1, 0.08, 0.055, 1 },
    button = { 0.13, 0.1, 0.07, 1 }, buttonEdge = { 0.45, 0.36, 0.22, 1 },
    tab = { 0.09, 0.075, 0.055, 1 }, tabOn = { 0.24, 0.17, 0.09, 1 },
}

local function solid(parent, layer, c, sub)
    local t = parent:CreateTexture(nil, layer, nil, sub or 0)
    t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    return t
end

-- 1px lines on all four sides, inset by `inset`
local function outline(parent, c, inset, layer)
    inset = inset or 0
    local top = solid(parent, layer or "BORDER", c)
    top:SetPoint("TOPLEFT", inset, -inset); top:SetPoint("TOPRIGHT", -inset, -inset); top:SetHeight(1)
    local bottom = solid(parent, layer or "BORDER", c)
    bottom:SetPoint("BOTTOMLEFT", inset, inset); bottom:SetPoint("BOTTOMRIGHT", -inset, inset); bottom:SetHeight(1)
    local left = solid(parent, layer or "BORDER", c)
    left:SetPoint("TOPLEFT", inset, -inset); left:SetPoint("BOTTOMLEFT", inset, inset); left:SetWidth(1)
    local right = solid(parent, layer or "BORDER", c)
    right:SetPoint("TOPRIGHT", -inset, -inset); right:SetPoint("BOTTOMRIGHT", -inset, inset); right:SetWidth(1)
end

local function hideTemplateArt(f)
    for _, r in ipairs({ f:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "Texture" then r:SetAlpha(0) end
    end
end

local function hline(parent, y, c)
    local t = solid(parent, "BORDER", c or SLEEK.line)
    t:SetPoint("TOPLEFT", 2, y); t:SetPoint("TOPRIGHT", -2, y); t:SetHeight(1)
    return t
end

local function skinFrame(f)
    hideTemplateArt(f)
    for _, key in ipairs({ "NineSlice", "Inset" }) do
        if type(f[key]) == "table" and f[key].SetAlpha then f[key]:SetAlpha(0) end
    end
    solid(f, "BACKGROUND", SLEEK.bg, -8):SetAllPoints()
    outline(f, { 0, 0, 0, 1 }, 0)
    outline(f, SLEEK.edge, 1)
    local band = solid(f, "BACKGROUND", SLEEK.titleBottom, -7)
    band:SetPoint("TOPLEFT", 2, -2); band:SetPoint("TOPRIGHT", -2, -2); band:SetHeight(22)
    if band.SetGradient and CreateColor then
        pcall(band.SetGradient, band, "VERTICAL",
            CreateColor(unpack(SLEEK.titleBottom)), CreateColor(unpack(SLEEK.titleTop)))
    end
    hline(f, -24, SLEEK.edge)        -- under the title
    hline(f, -60)                    -- under the buttons
    local foot = solid(f, "BORDER", SLEEK.line)
    foot:SetPoint("BOTTOMLEFT", 2, 42); foot:SetPoint("BOTTOMRIGHT", -2, 42); foot:SetHeight(1)
end

local function skinButton(b, colors)
    if not b then return end
    for _, key in ipairs({ "Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled", "RightDisabled",
                           "LeftActive", "MiddleActive", "RightActive", "LeftHighlight", "MiddleHighlight", "RightHighlight" }) do
        if type(b[key]) == "table" and b[key].SetAlpha then b[key]:SetAlpha(0) end
    end
    for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
        local t = b[get] and b[get](b)
        if t and t.SetAlpha then t:SetAlpha(0) end
    end
    hideTemplateArt(b)
    b.skinBg = solid(b, "BACKGROUND", colors or SLEEK.button, -8)
    b.skinBg:SetAllPoints()
    outline(b, SLEEK.buttonEdge, 0, "BACKGROUND")
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetColorTexture(1, 0.82, 0, 0.12)
    hl:SetAllPoints()
end

----------------------------------------------------------------------
-- Treasure gleam around 1st place items: a soft breathing gold glow
-- and two small, slow twinkles
----------------------------------------------------------------------
local SPARK_SPOTS = {   -- point on the icon, x, y, size, delay
    { "TOPRIGHT", -2, -2, 9, 0 }, { "BOTTOMLEFT", 2, 2, 7, 1.6 },
}

function ns.CreateSparkle(parent, anchor)
    local f = CreateFrame("Frame", nil, parent)
    f:SetAllPoints(anchor)
    f:SetFrameLevel(parent:GetFrameLevel() + 3)
    f.groups = {}
    -- soft golden halo glowing out from behind the icon (drawn on the
    -- parent so it sits under the icon art instead of washing over it)
    local glow = parent:CreateTexture(nil, "ARTWORK", nil, 7)
    glow:SetTexture(ns.TEXTURES .. "halo")
    glow:SetBlendMode("ADD")
    glow:SetPoint("CENTER", anchor, "CENTER")
    glow:SetSize(64, 64)
    glow:Hide()
    f.glow = glow
    -- the glow stays steady (no fading); only the little stars twinkle
    for _, s in ipairs(SPARK_SPOTS) do
        local t = f:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetTexture(ns.TEXTURES .. "sparkle")
        t:SetBlendMode("ADD")
        t:SetSize(s[4], s[4])
        t:SetPoint("CENTER", f, s[1], s[2], s[3])
        t:SetAlpha(0)
        local sg = t:CreateAnimationGroup()
        sg:SetLooping("REPEAT")
        local fadeIn = sg:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(0.85); fadeIn:SetDuration(0.6)
        fadeIn:SetOrder(1); fadeIn:SetStartDelay(s[5])
        local turn = sg:CreateAnimation("Rotation")
        turn:SetDegrees(-45); turn:SetDuration(0.6)
        turn:SetOrder(1); turn:SetStartDelay(s[5])
        local fadeOut = sg:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(0.85); fadeOut:SetToAlpha(0); fadeOut:SetDuration(0.8)
        fadeOut:SetOrder(2)
        local rest = sg:CreateAnimation("Alpha")
        rest:SetFromAlpha(0); rest:SetToAlpha(0); rest:SetDuration(2.2)
        rest:SetOrder(3)
        table.insert(f.groups, sg)
    end
    f:Hide()
    return f
end

function ns.ShowSparkle(f, on, iconSize)
    if not f then return end
    if on then
        -- the gold ring sits on the icon's edge and fades out within a few pixels
        f.glow:SetSize((iconSize or 32) * 2.1, (iconSize or 32) * 2.1)
        f.glow:SetAlpha(1)
        f.glow:Show()
        f:Show()
        -- restart every time: WoW can stop an animation while its card is
        -- hidden and still report it as playing, which left the glow dark
        for _, g in ipairs(f.groups) do
            g:Stop()
            g:Play()
        end
    else
        for _, g in ipairs(f.groups) do g:Stop() end
        f.glow:Hide()
        f:Hide()
    end
end

----------------------------------------------------------------------
-- Rows
----------------------------------------------------------------------

local function sourceClick(self, row)
    if row.boss then ns.ShowBoss(row.boss) return end
    -- a quest you have: open it in the quest log (Shift-click still pins the giver)
    if row.questInLog and not IsShiftKeyDown() then ns.OpenQuestLog(row.questInLog) return end
    -- quest: pin the quest giver on the map
    local pins = row.quests and ns.QuestPins and ns.QuestPins(row.quests) or {}
    if #pins == 1 then
        ns.PinOnMap(pins[1].zone, pins[1].coords, pins[1].giver)
    elseif #pins > 1 and MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle("Pin on map")
            for _, p in ipairs(pins) do
                root:CreateButton(p.giver .. "  |cffaaaaaa(" .. p.quest .. ", " .. p.zone .. ")|r",
                    function() ns.PinOnMap(p.zone, p.coords, p.giver) end)
            end
        end)
    end
end

local function sourceEnter(self, row)
    -- podium cards add where it drops and how often
    local function extra()
        if row.dungeonName and row.dungeonName ~= "" then
            GameTooltip:AddDoubleLine("Dungeon", row.dungeonName, 0.8, 0.8, 0.8, 1, 1, 1)
        end
        if row.dropRate then GameTooltip:AddDoubleLine("Drop", row.dropRate, 0.8, 0.8, 0.8, 1, 1, 1) end
    end
    if row.boss then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(row.boss.name)
        GameTooltip:AddLine(row.boss.instance or "", 1, 1, 1)
        if row.dropRate then GameTooltip:AddDoubleLine("Drop", row.dropRate, 0.8, 0.8, 0.8, 1, 1, 1) end
        GameTooltip:AddLine("Click to see the boss", 0.2, 1, 0.2)
        GameTooltip:Show()
    elseif row.quests then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        ns.AddQuestTooltip(GameTooltip, row.quests)
        extra()
        local canPin = ns.QuestPins and #ns.QuestPins(row.quests) > 0
        if row.questInLog or canPin then GameTooltip:AddLine(" ") end
        if row.questInLog then
            GameTooltip:AddLine("Click to open " .. row.questInLog.title .. " in your quest log", 0.2, 1, 0.2)
            if canPin then GameTooltip:AddLine("Shift-click to pin the quest giver on your map", 0.2, 1, 0.2) end
        elseif canPin then
            GameTooltip:AddLine("Click to pin the quest giver on your map", 0.2, 1, 0.2)
        end
        GameTooltip:Show()
    elseif row.questInLog then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(row.questInLog.title, 1, 0.82, 0)
        GameTooltip:AddLine("Click to open it in your quest log", 0.2, 1, 0.2)
        GameTooltip:Show()
    end
end

----------------------------------------------------------------------
-- Celebration: when a slot becomes done, gold sprinkles down over it
-- (snow during the holiday theme)
----------------------------------------------------------------------
local fx, fxPool, fxLive = nil, {}, {}

-- row / card background for the place you have: gold, silver, bronze
local PLACE_TINT = { { 0.94, 0.71, 0.16, 0.16 }, { 0.76, 0.8, 0.84, 0.13 }, { 0.79, 0.48, 0.24, 0.15 } }

local function fxUpdate(self, elapsed)
    local any = false
    for i = #fxLive, 1, -1 do
        local p = fxLive[i]
        p.t = p.t + elapsed
        if p.t >= p.life then
            p.tex:Hide()
            table.remove(fxLive, i)
            table.insert(fxPool, p)
        else
            any = true
            local k = p.t / p.life
            p.x = p.x + (p.vx + math.sin((p.t + p.phase) * p.wobble) * p.sway) * elapsed
            p.y = p.y - p.vy * elapsed
            p.tex:ClearAllPoints()
            p.tex:SetPoint("CENTER", self, "BOTTOMLEFT", p.x, p.y)
            p.tex:SetAlpha(p.alpha * (k < 0.15 and k / 0.15 or (k > 0.6 and (1 - k) / 0.4 or 1)))
        end
    end
    if not any then self:SetScript("OnUpdate", nil) end
end

function ns.Celebrate(anchor)
    if not (frame and anchor and anchor.GetLeft and frame:IsShown()) then return end
    if not fx then
        fx = CreateFrame("Frame", nil, frame)
        fx:SetAllPoints(frame)
        fx:SetFrameLevel(frame:GetFrameLevel() + 60)
        fx:EnableMouse(false)
    end
    local left, top, w = anchor:GetLeft(), anchor:GetTop(), anchor:GetWidth()
    local fl, fb = fx:GetLeft(), fx:GetBottom()
    if not (left and top and w and fl and fb) then return end
    local x0, y0 = left - fl, top - fb
    local snow = ns.HolidayOn()
    for _ = 1, (snow and 26 or 22) do
        local p = table.remove(fxPool)
        if not p then
            p = { tex = fx:CreateTexture(nil, "OVERLAY") }
            p.tex:SetTexture(ns.TEXTURES .. "sparkle")
        end
        p.tex:SetBlendMode(snow and "BLEND" or "ADD")
        if snow then p.tex:SetVertexColor(0.92, 0.96, 1) else p.tex:SetVertexColor(1, 0.82, 0.25) end
        local size = snow and math.random(5, 10) or math.random(6, 13)
        p.tex:SetSize(size, size)
        p.x = x0 + math.random() * math.min(w, 420)
        p.y = y0 + math.random(0, 26)
        p.vx = (math.random() - 0.5) * 16
        p.vy = snow and math.random(28, 55) or math.random(55, 110)
        p.sway = snow and math.random(10, 22) or math.random(3, 8)
        p.wobble = snow and 2.2 or 5
        p.phase = math.random() * 6
        p.t, p.life = 0, snow and (1.8 + math.random() * 0.9) or (1.1 + math.random() * 0.6)
        p.alpha = snow and 0.95 or 1
        p.tex:Show()
        table.insert(fxLive, p)
    end
    fx:SetScript("OnUpdate", fxUpdate)
end

-- remember each slot's done state so only a change celebrates
local doneSeen = {}
local function celebrateIfNewlyDone(key, isDone, anchor)
    if not key then return end
    if doneSeen[key] == false and isDone then ns.Celebrate(anchor) end
    doneSeen[key] = isDone and true or false
end
ns._celebrateIfNewlyDone = celebrateIfNewlyDone   -- (tools/uitest.lua)

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

    -- 1st / 2nd / 3rd place icon left of the item icon (Gear tab)
    local trophy = CreateFrame("Frame", nil, row)
    trophy:SetSize(24, 24)
    trophy.tex = trophy:CreateTexture(nil, "ARTWORK")
    trophy.tex:SetAllPoints()
    trophy:EnableMouse(true)
    trophy:SetScript("OnEnter", function(self)
        if not row.place then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine((ns.PLACE_NAMES[row.place] or "") .. " place for " .. (row.slotName or "this slot"), 1, 0.82, 0)
        if row.paired and row.place == 1 and not row.isExtra then
            GameTooltip:AddLine("You wear two, so both of these best picks are 1st place.", 1, 1, 1, true)
        elseif row.place == 1 then
            GameTooltip:AddLine("The best pick for this slot.", 1, 1, 1, true)
        else
            GameTooltip:AddLine("A good pick while you work on the places above it.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    trophy:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- 1st place: a soft glow behind the icon and a twinkle on the tree's star
    trophy.glow = trophy:CreateTexture(nil, "BACKGROUND")
    trophy.glow:SetTexture(ns.TEXTURES .. "halo")
    trophy.glow:SetBlendMode("ADD")
    trophy.glow:SetPoint("CENTER")
    trophy.glow:SetSize(40, 40)
    trophy.glow:SetAlpha(0.8)   -- steady glow, no fading
    -- 1st place: the trophy drawn again on top, added, so it reads brighter
    trophy.bright = trophy:CreateTexture(nil, "OVERLAY")
    trophy.bright:SetAllPoints(trophy.tex)
    trophy.bright:SetBlendMode("ADD")
    trophy.bright:SetAlpha(0.3)
    trophy.bright:Hide()
    -- holiday: a soft glow on the tree's star, and the twinkle on top of it
    trophy.starGlow = trophy:CreateTexture(nil, "OVERLAY")
    trophy.starGlow:SetTexture(ns.TEXTURES .. "halo")
    trophy.starGlow:SetBlendMode("ADD")
    trophy.starGlow:SetVertexColor(1, 0.9, 0.4)
    trophy.starGlow:SetSize(18, 18)
    trophy.starGlow:SetPoint("CENTER", trophy, "TOP", 0, -3)
    trophy.starGlow:SetAlpha(0.7)
    trophy.starGlow:Hide()
    trophy.star = trophy:CreateTexture(nil, "OVERLAY")
    trophy.star:SetTexture(ns.TEXTURES .. "sparkle")
    trophy.star:SetBlendMode("ADD")
    trophy.star:SetSize(16, 16)
    trophy.star:SetPoint("CENTER", trophy, "TOP", 0, -2)
    trophy.star:SetAlpha(0)
    trophy.starAnim = trophy.star:CreateAnimationGroup()
    trophy.starAnim:SetLooping("REPEAT")
    local tIn = trophy.starAnim:CreateAnimation("Alpha")
    tIn:SetFromAlpha(0); tIn:SetToAlpha(1); tIn:SetDuration(0.45); tIn:SetOrder(1)
    local tTurn = trophy.starAnim:CreateAnimation("Rotation")
    tTurn:SetDegrees(-90); tTurn:SetDuration(0.9); tTurn:SetOrder(1)
    local tOut = trophy.starAnim:CreateAnimation("Alpha")
    tOut:SetFromAlpha(1); tOut:SetToAlpha(0); tOut:SetDuration(0.45); tOut:SetOrder(2)
    local tRest = trophy.starAnim:CreateAnimation("Alpha")
    tRest:SetFromAlpha(0); tRest:SetToAlpha(0); tRest:SetDuration(1.4 + (i % 5) * 0.3); tRest:SetOrder(3)
    trophy:Hide()
    row.trophy = trophy
    -- branch line tying a 2nd / 3rd place row to its slot
    row.branchV = row:CreateTexture(nil, "ARTWORK")
    row.branchV:SetColorTexture(0.55, 0.46, 0.32, 0.8)
    row.branchV:SetSize(1, ROW_HEIGHT / 2)
    row.branchV:SetPoint("TOPLEFT", 12, 0)
    row.branchH = row:CreateTexture(nil, "ARTWORK")
    row.branchH:SetColorTexture(0.55, 0.46, 0.32, 0.8)
    row.branchH:SetSize(9, 1)
    row.branchH:SetPoint("TOPLEFT", 12, -ROW_HEIGHT / 2)
    row.branchV:Hide(); row.branchH:Hide()
    row.sparkle = ns.CreateSparkle(row, icon)

    -- "+2 more" / "Hide": opens a slot's 2nd and 3rd place (Gear tab)
    local more = CreateFrame("Button", nil, row)
    more:SetSize(58, 18)
    more.bg = more:CreateTexture(nil, "BACKGROUND")
    more.bg:SetAllPoints()
    more.bg:SetColorTexture(0, 0, 0, 0.45)
    more.text = more:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    more.text:SetPoint("CENTER")
    more:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    more:SetScript("OnClick", function()
        if not row.slotName then return end
        ns.char.expandedSlots = ns.char.expandedSlots or {}
        local open = ns.char.expandedSlots
        if open[row.slotName] then open[row.slotName] = nil else open[row.slotName] = true end
        ns.RefreshBrowser()
    end)
    more:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local open = ns.char.expandedSlots and ns.char.expandedSlots[row.slotName]
        GameTooltip:AddLine(open and "Hide 2nd and 3rd place" or ("Show 2nd and 3rd place for " .. (row.slotName or "this slot")))
        GameTooltip:AddLine("Tick \"2nd & 3rd\" at the top to open every slot.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    more:SetScript("OnLeave", function() GameTooltip:Hide() end)
    more:Hide()
    row.more = more

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

    row.dungeon = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.dungeon:SetJustifyH("LEFT")
    row.dungeon:SetJustifyV("MIDDLE")
    row.dungeon:SetWordWrap(true)
    if row.dungeon.SetMaxLines then row.dungeon:SetMaxLines(2) end

    row.drop = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.drop:SetJustifyH("RIGHT")

    row.avoid = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.avoid:SetJustifyH("LEFT")
    row.avoid:SetWordWrap(true)
    if row.avoid.SetMaxLines then row.avoid:SetMaxLines(2) end

    -- click area over "where to get it": opens the boss window
    local srcHit = CreateFrame("Button", nil, row)
    srcHit:SetPoint("TOPLEFT", row.source, "TOPLEFT", -2, 4)
    srcHit:SetPoint("BOTTOMRIGHT", row.source, "BOTTOMRIGHT", 2, -4)
    srcHit:SetScript("OnClick", function(self) sourceClick(self, row) end)
    srcHit:SetScript("OnEnter", function(self) sourceEnter(self, row) end)
    srcHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.srcHit = srcHit

    -- hover area over the enchant name: shows what the enchant does
    local enchHit = CreateFrame("Frame", nil, row)
    enchHit:SetPoint("TOPLEFT", row.avoid, "TOPLEFT", -2, 6)
    enchHit:SetPoint("BOTTOMRIGHT", row.avoid, "BOTTOMRIGHT", 2, -6)
    enchHit:EnableMouse(true)
    enchHit:SetScript("OnEnter", function(self)
        if row.craft then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Materials")
            for _, m in ipairs(row.craft.mats or {}) do
                local have = (C_Item.GetItemCount and C_Item.GetItemCount(m[1], true)) or 0
                local r, g, b = 1, 0.4, 0.4
                if have >= m[2] then r, g, b = 0.2, 1, 0.2 end
                GameTooltip:AddDoubleLine(m[2] .. "x " .. m[3], "have " .. have, 1, 1, 1, r, g, b)
            end
            if row.craft.recipe then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(row.craft.recipe, 1, 0.82, 0)
                GameTooltip:AddLine(row.craft.from or "Where to get it: TBD", 1, 1, 1, true)
            end
            GameTooltip:Show()
            return
        end
        if not row.enchantID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(row.enchantID)
        if row.enchantNote or row.enchantSource then GameTooltip:AddLine(" ") end
        if row.enchantNote then GameTooltip:AddLine("Gives: " .. row.enchantNote, 0.2, 1, 0.2) end
        if row.enchantSource then GameTooltip:AddLine("Get it from: " .. row.enchantSource, 1, 0.82, 0) end
        local current, enchanted
        if ns.SlotEnchant then current, enchanted = ns.SlotEnchant(row.slotName) end
        if enchanted then
            GameTooltip:AddLine("Your " .. row.slotName:lower() .. " now: " .. (current or "enchanted"), 1, 1, 1)
        elseif current == nil and enchanted == false and ns.Owned[row.itemID] == "equipped" then
            GameTooltip:AddLine("Your " .. row.slotName:lower() .. " isn't enchanted yet", 1, 0.4, 0.4)
        end
        GameTooltip:Show()
    end)
    enchHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.enchHit = enchHit


    local link = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    link:SetSize(64, 22)
    link:SetPoint("RIGHT", -4, 0)
    link:SetText("Link")
    if frame.sleek then skinButton(link) end
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
            -- (unless another spec's tick would then show through)
            if on == (row.autoDone or false) then
                local shared = ns.SharedDoneMark and ns.SharedDoneMark(row.specKey, row.doneKey, row.doneSig)
                if shared == nil or shared == on then on = nil end
            end
            ns.SetDoneMark(row.specKey, row.doneKey, on, row.doneSig)
            ns.RefreshBrowser()
        end
    end)
    done:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Done")
        if row.autoDone then
            if row.doneBy then
                local e = row.doneBy
                local name = (C_Item.GetItemNameByID and C_Item.GetItemNameByID(e.id)) or ("item " .. e.id)
                GameTooltip:AddLine("Ticked because you have " .. name .. " from the "
                    .. (e.list == "bis" and "BiS" or "Realistic") .. " list.", 1, 1, 1, true)
                GameTooltip:AddLine("Untick it if the slot isn't finished.", 0.8, 0.8, 0.8, true)
            else
                GameTooltip:AddLine("Ticked because you own a BiS or Realistic item for this slot. Untick it if the slot isn't finished.", 1, 1, 1, true)
            end
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

    -- Consumables tab: "have / keep" with a menu to change how many to keep
    local haveHit = CreateFrame("Button", nil, row)
    haveHit:SetPoint("TOPLEFT", row.owned, "TOPLEFT", -6, 6)
    haveHit:SetPoint("BOTTOMRIGHT", row.owned, "BOTTOMRIGHT", 4, -6)
    haveHit:SetScript("OnEnter", function(self)
        if not row.stock then return end
        local s = row.stock
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("On hand")
        GameTooltip:AddDoubleLine("In bags", s.bags, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("In bank", s.total - s.bags, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Keep", s.target .. (s.custom and "" or " (recommended)"), 1, 1, 1, 1, 0.82, 0)
        if s.total < s.target then
            GameTooltip:AddLine("Buy or make " .. (s.target - s.total) .. " more", 1, 0.4, 0.4)
        end
        GameTooltip:AddLine("Click to change how many to keep", 0.2, 1, 0.2)
        GameTooltip:Show()
    end)
    haveHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    haveHit:SetScript("OnClick", function(self)
        local s = row.stock
        if not s or not (MenuUtil and MenuUtil.CreateContextMenu) then return end
        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle("Keep on hand")
            local rec = ns.ConsumeRecommended[s.kind] or 5
            for _, n in ipairs({ 1, 2, 3, 5, 10, 15, 20, 40 }) do
                root:CreateRadio(n .. (n == rec and "  |cffaaaaaa(recommended)|r" or ""),
                    function() return s.target == n end,
                    function() ns.SetConsumeTarget(s.id, n); ns.RefreshBrowser() end)
            end
            root:CreateDivider()
            root:CreateButton("Don't track this one", function() ns.SetConsumeTarget(s.id, 0); ns.RefreshBrowser() end)
            root:CreateButton("Use the recommendation (" .. rec .. ")", function() ns.SetConsumeTarget(s.id, nil); ns.RefreshBrowser() end)
        end)
    end)
    row.haveHit = haveHit

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
    row.isExtra = data.isExtra
    row.slotName = data.slot
    row.paired = ns.PAIRED_SLOTS and ns.PAIRED_SLOTS[data.slot] or nil
    -- place icon (Gear tab), then the item icon
    local placeIcon = data.place and ns.PlaceIcon and ns.PlaceIcon(data.place)
    row.place = placeIcon and data.place or nil
    local iconX = data.isAlt and 22 or 4
    if placeIcon then
        local size = data.isAlt and 20 or 24
        row.trophy:ClearAllPoints()
        row.trophy:SetPoint("LEFT", iconX, 0)
        row.trophy:SetSize(size, size)
        row.trophy.tex:SetTexture(placeIcon)
        row.trophy:Show()
        local shine = data.place == 1 and not data.isAlt
        row.trophy.glow:SetSize(size * 1.7, size * 1.7)
        row.trophy.glow:SetShown(shine)
        row.trophy.bright:SetTexture(placeIcon)
        row.trophy.bright:SetShown(shine)
        local twinkle = shine and ns.HolidayOn() or false
        row.trophy.star:SetShown(twinkle)
        row.trophy.starGlow:SetShown(twinkle)
        if twinkle then
            if not row.trophy.starAnim:IsPlaying() then row.trophy.starAnim:Play() end
        else
            row.trophy.starAnim:Stop()
        end
        iconX = iconX + size + 2
    else
        row.trophy:Hide()
    end
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", iconX, 0)
    row.icon:SetSize(data.isAlt and 26 or 32, data.isAlt and 26 or 32)
    -- sparkle is saved for the podium cards; list rows stay calm
    ns.ShowSparkle(row.sparkle, false)
    if data.extraCount and ns.char.showAlts == false then
        local open = ns.char.expandedSlots and ns.char.expandedSlots[data.slot]
        row.more.text:SetText(open and "Hide" or ("+" .. data.extraCount .. " more"))
        row.more:Show()
    else
        row.more:Hide()
    end
    row.branchV:SetShown(data.isExtra and true or false)
    row.branchH:SetShown(data.isExtra and true or false)
    if data.isExtra then
        row.bg:SetColorTexture(0, 0, 0, 0.22)
    elseif data.isAlt then
        row.bg:SetColorTexture(0.45, 0.6, 1, 0.07)
    elseif data.ownedPlace and PLACE_TINT[data.ownedPlace] then
        -- you have a 1st / 2nd / 3rd place item for this slot: gold / silver / bronze
        local c = PLACE_TINT[data.ownedPlace]
        row.bg:SetColorTexture(c[1], c[2], c[3], c[4])
    else
        row.bg:SetColorTexture(1, 1, 1, (row.index % 2 == 0) and 0.04 or 0)
    end

    layoutRow(row)
    row.icon.tex:SetTexture(C_Item.GetItemIconByID(data.id) or 134400)
    row.name:SetText("|cff888888Loading item " .. data.id .. "...|r")
    local slotText = data.slot
    if data.isPre then slotText = "|cffffd100For T0.5 quest|r  " .. slotText
    elseif data.isExtra then slotText = "|cffd0d0d0" .. (ns.PLACE_NAMES[data.place] or "") .. " place|r  " .. slotText
    elseif data.isAlt then slotText = "|cff8fb8ffAlternative|r  " .. slotText end
    if row.place and not data.isAlt and row.paired then slotText = slotText .. "  |cffffd100wear 2|r" end
    if data.weaponChoice then
        slotText = slotText .. (data.slot == "Two Hand" and "  |cffaaaaaa(instead of one-handers)|r" or "  |cffaaaaaa(instead of a two-hander)|r")
    end
    if data.isNew then slotText = "|cff1eff00NEW|r  " .. slotText end
    if data.faction then slotText = slotText .. "  |cffffd100(" .. data.faction .. ")|r" end
    local onQuest = ns.OnSourceQuest(data.source)

    row.slot:SetText(slotText)
    local src = data.source or ""
    if data.craft then
        local c = data.craft
        if c.prof then
            src = "|cffffd100" .. c.prof .. (c.skill and (" " .. c.skill) or "") .. "|r"
            local TBD = "|cff999999TBD|r"
            if c.recipe then
                src = src .. "  " .. c.recipe .. ": " .. (c.from or TBD)
            else
                src = src .. "  Recipe: " .. TBD
            end
        elseif c.from then
            src = c.from
        end
    end
    -- gear tabs: dungeon in its own column, boss / source in this one
    local splitCols = not data.craft and not frame.compact
        and (frame.layoutMode == nil or frame.layoutMode == "bis" or frame.layoutMode == "realistic"
             or frame.layoutMode == "ranked")
    local dungeon, bossText = ns.SplitSource(data.source)
    if splitCols then
        row.dungeon:SetText(dungeon)
        if frame.layoutMode == "ranked" then row.dungeon:SetTextColor(0.8, 0.76, 0.66)
        else row.dungeon:SetTextColor(1, 0.82, 0) end
        src = bossText
    elseif data.craftTab and not frame.compact then
        -- Enchants / Consumables: skill in its own column, recipe source here
        local c = data.craft
        if c and c.prof then
            row.dungeon:SetText("|cffffd100" .. c.prof .. "|r" .. (c.skill and ("\n|cffffffff" .. c.skill .. "|r") or ""))
            src = c.from or (c.recipe and "|cff999999TBD|r") or "|cff999999Recipe: TBD|r"
        else
            row.dungeon:SetText("|cff999999None|r")
            src = (c and c.from) or data.source or ""
        end
    else
        row.dungeon:SetText("")
    end
    local rate = ns.DropChance(data.id, data.source)
    row.drop:SetText(rate and ns.FormatChance(rate) or "|cff666666-|r")
    if onQuest then src = "|cff33ff33" .. src .. "  (On quest)|r" end
    -- a Dungeon Journal boss: skull icon, click to view it
    local boss = ns.FindBoss and ns.FindBoss(data.craft and data.craft.from or data.source)
    row.boss = boss
    row.quests = (not boss) and ns.QuestsInSource and ns.QuestsInSource(data.craft and data.craft.from or data.source) or nil
    row.questInLog = (not boss) and ns.QuestInLog(data.craft and data.craft.from or data.source) or nil
    row.srcHit:SetShown(boss ~= nil or row.quests ~= nil or row.questInLog ~= nil)
    if boss then src = ns.BOSS_ICON .. src end
    -- notes: on the gear tabs, only what the item's own tooltip doesn't say
    -- (stat notes like "1% hit" or "Agility +8" are dropped there)
    local note = data.note
    if note and not data.craftTab then note = ns.NoteWithoutStats(note) end
    local tallCell = data.craftTab and not frame.compact
    if tallCell then
        -- Enchants / Consumables: one fact per line, like the materials
        -- ("Vendor: Beneris / Alynsia" / "120 Merchant's Favor" / "Agility +5")
        src = ns.SourceLines(src)
        if note then src = src .. "\n|cffaaaaaa" .. note .. "|r" end
    elseif note and not data.isPre then
        src = src .. "  |cffaaaaaa(" .. note .. ")|r"
    end
    if row.source.SetMaxLines then row.source:SetMaxLines(tallCell and 6 or 2) end
    row.source:SetText(ns.AnnotateCost(src))
    row.enchantID = data.enchantID
    row.enchantNote, row.enchantSource = data.enchantNote, data.enchantSource
    row.slotName, row.itemID = data.slot, data.id
    row.craft = data.craft
    row.enchHit:SetShown((data.enchantID ~= nil or data.craft ~= nil) and row.avoid:IsShown())
    enchantCell(row, data)
    local ownedText = OWNED_ICON[ns.Owned[data.id]] or ""
    if data.enchanted then
        ownedText = GREEN_CHECK .. " |cff33ff33Enchanted|r"
    elseif data.gearReady then
        ownedText = YELLOW_CHECK .. " |cffffd100Ready|r"
    end
    row.stock = nil
    if frame.layoutMode == "consumables" then
        -- how many you have against how many to keep
        local bags, total = ns.ConsumeCount(data.id)
        local target, custom = ns.ConsumeTarget(data.id, data.slot)
        row.stock = { id = data.id, kind = data.slot, bags = bags, total = total, target = target, custom = custom }
        if target == 0 then
            ownedText = "|cff888888" .. total .. "|r"
        else
            local color = total >= target and "|cff33ff33" or (total > 0 and "|cffffd100" or "|cffff5555")
            ownedText = color .. total .. "|r |cffaaaaaa/ " .. target .. "|r"
        end
    end
    row.haveHit:SetShown(row.stock ~= nil)
    if frame.compact and not row.stock then ownedText = ownedText:match("^(|T.-|t)") or ownedText end   -- icon only
    row.doneBy = nil
    if ownedText == "" and data.isDone and data.doneBy and not frame.compact then
        -- done through another item: say which list and where it is
        local e = data.doneBy
        local where = ({ equipped = "equipped", bag = "in bags", bank = "in bank" })[ns.Owned[e.id]] or "owned"
        ownedText = "|cff33ff33" .. (e.list == "bis" and "BiS" or "Realistic") .. " " .. where .. "|r"
        row.doneBy = e
    end
    if ownedText == "" and data.isDone then ownedText = "|cff33ff33Done|r" end
    -- Tier 0.5 piece you don't have yet, but you own the Tier 0 piece its quest needs
    if ownedText == "" and not data.isPre and data.preID and ns.Owned[data.preID] and not frame.compact then
        ownedText = "|cffffd100Tier 0 ready|r"
    end
    row.owned:SetText(ownedText)
    row.doneKey, row.specKey, row.autoDone, row.doneSig = data.doneKey, data.specKey, data.autoDone, data.doneSig
    if data.doneKey then
        row.done:Show()
        row.done:SetChecked(data.isDone and true or false)
    else
        row.done:Hide()
    end
    row:SetAlpha(data.isDone and not data.ownedPlace and 0.6 or (data.isDone and 0.85) or 1)
    if data.doneKey and not data.isAlt then
        celebrateIfNewlyDone((data.specKey or "") .. "|" .. data.doneKey, data.isDone, row)
    end

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
        elseif row.isAlt and not row.isExtra then text = "|cff8fb8ffAlt:|r " .. text end
        row.name:SetText(text)
    end)
    row:Show()
end

----------------------------------------------------------------------
-- Podium view (Gear tab): one card per slot with 2nd, 1st and 3rd place
-- standing on podium steps
----------------------------------------------------------------------
local CARD_W, CARD_H, CARD_GAP = 300, 198, 10
local STEP_H = { 40, 32, 26 }                     -- block height by place (tall enough for the trophy)
local STEP_COLOR = { { 1, 0.78, 0.2 }, { 0.78, 0.82, 0.86 }, { 0.8, 0.5, 0.26 } }
local STEP_ORDER = { 2, 1, 3 }                    -- left to right
local podiumCards = {}

local function podiumItemEnter(self)
    local d = self.data
    if not d then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(d.id)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine((ns.PLACE_NAMES[d.place] or "") .. " place for " .. d.slot
        .. ((ns.PAIRED_SLOTS[d.slot] and d.place == 1) and " (you wear two)" or ""), 1, 0.82, 0)
    local dungeon, boss = ns.SplitSource(d.source)
    if dungeon ~= "" then GameTooltip:AddDoubleLine("Dungeon", dungeon, 0.8, 0.8, 0.8, 1, 1, 1) end
    if boss ~= "" then GameTooltip:AddDoubleLine("Boss / source", boss, 0.8, 0.8, 0.8, 1, 1, 1) end
    local rate = ns.DropChance(d.id, d.source)
    if rate then GameTooltip:AddDoubleLine("Drop", ns.FormatChance(rate) .. "  |cffaaaaaa" .. ns.DropMood(rate) .. "|r", 0.8, 0.8, 0.8, 1, 1, 1) end
    local dn = ns.NoteWithoutStats(d.note)
    if dn then GameTooltip:AddLine(dn, 0.67, 0.67, 0.67, true) end
    local where = ({ equipped = "You have it equipped", bag = "It's in your bags", bank = "It's in your bank" })[ns.Owned[d.id]]
    if where then GameTooltip:AddLine(where, 0.2, 1, 0.2) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Right-click: copy web link", 0.2, 1, 0.2)
    GameTooltip:AddLine("Shift-click: link in chat   Ctrl-click: preview", 0.2, 1, 0.2)
    GameTooltip:Show()
end

local function edge(card, a, b, w, h)
    local t = card:CreateTexture(nil, "BORDER")
    t:SetColorTexture(1, 0.82, 0, 0.18)
    t:SetPoint(a, card, a)
    t:SetPoint(b, card, b)
    if w then t:SetWidth(w) else t:SetHeight(h) end
end

local function makeItemButton(card, size)
    local btn = CreateFrame("Button", nil, card)
    btn:SetSize(size, size)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn.tex = btn:CreateTexture(nil, "ARTWORK")
    btn.tex:SetAllPoints()
    btn.own = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    btn.own:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    btn.own:SetSize(14, 14)
    btn.own:SetPoint("BOTTOMRIGHT", 4, -4)
    btn:SetScript("OnEnter", podiumItemEnter)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnClick", function(self, button)
        if not self.data then return end
        if button == "RightButton" then ns.ShowLinkPopupForItem(self.data.id) return end
        if self.link then HandleModifiedItemClick(self.link) end
    end)
    return btn
end

-- "Why this place?": hovering a podium step explains the ranking from what we
-- know for sure: which guide ranked it, how its stats compare with the place
-- next to it, and how hard it is to get.
local function howToGet(d)
    local src = d.source or ""
    local dungeon, boss = ns.SplitSource(src)
    local rate = ns.DropChance(d.id, src)
    if boss:find("^Quest:") then return "Quest reward, a sure thing once the quest is done" end
    if src:find("Leatherworking") or src:find("Blacksmithing") or src:find("Tailoring")
        or src:find("Engineering") or src:find("Crafted") then
        return "Crafted (" .. (src:match("(%a+working)") or src:match("(%a+smithing)") or src:match("(Tailoring)") or src:match("(Engineering)") or "profession") .. "), buy it or make it"
    end
    if src:find("Revered") or src:find("Exalted") or src:find("Honored") or src:find("Friendly%)") then
        return "Reputation reward, a steady grind"
    end
    if src:find("Trash") then return "Trash drop in " .. dungeon .. (rate and (", about " .. ns.FormatChance(rate)) or "") end
    if rate then return "Drops from " .. boss .. (dungeon ~= "" and (" in " .. dungeon) or "") .. ", " .. ns.FormatChance(rate) .. " chance" end
    if boss ~= "" then return boss .. (dungeon ~= "" and (" (" .. dungeon .. ")") or "") end
    return dungeon
end

local function statDiff(a, b, role)
    if not ns.ItemKeyStats then return {} end
    local sa, sb = ns.ItemKeyStats(a.id), ns.ItemKeyStats(b.id)
    local keys = {}
    for _, k in ipairs((ns.ROLE_STATS and ns.ROLE_STATS[role]) or {}) do table.insert(keys, k) end
    table.insert(keys, "hit"); table.insert(keys, "crit")
    local out = {}
    for _, k in ipairs(keys) do
        local dv = (sa[k] or 0) - (sb[k] or 0)
        if dv ~= 0 then
            local pct = (k == "hit" or k == "crit") and "%" or ""
            table.insert(out, { text = (dv > 0 and "+" or "") .. dv .. pct .. " " .. (ns.STAT_LABEL[k] or k), up = dv > 0 })
        end
    end
    return out
end

-- The item's stats that matter for the role, e.g. "21 Agility, 1% crit"
local function itemStatLine(d, role)
    if not ns.ItemKeyStats then return "" end
    local st = ns.ItemKeyStats(d.id)
    local keys = {}
    for _, k in ipairs((ns.ROLE_STATS and ns.ROLE_STATS[role]) or {}) do table.insert(keys, k) end
    table.insert(keys, "hit"); table.insert(keys, "crit")
    local parts = {}
    for _, k in ipairs(keys) do
        local v = st[k]
        if v and v ~= 0 then
            if k == "hit" or k == "crit" then table.insert(parts, v .. "% " .. k)
            else table.insert(parts, v .. " " .. (ns.STAT_LABEL[k] or k)) end
        end
    end
    return table.concat(parts, ", ")
end

local function kindOf(src)
    src = src or ""
    if src:find("[Qq]uest:") then return "quest" end
    if src:find("Crafted") or src:find("working") or src:find("smithing") or src:find("Tailoring") or src:find("Engineering") then return "crafted" end
    if src:find("Exalted") or src:find("Revered") or src:find("Honored") or src:find("Friendly%)") then return "rep" end
    if src:find("[Vv]endor") or src:find("Tarnished Undermine Real") then return "vendor" end
    return "drop"
end

-- One sentence on why the item holds its place
local function placeReason(d, place, first)
    if place == 1 then
        return "The strongest item for your spec in this slot."
    end
    local why = {}
    local k = kindOf(d.source)
    local rate = ns.DropChance(d.id, d.source)
    local firstRate = first and ns.DropChance(first.id, first.source)
    local firstKind = first and kindOf(first.source)
    if k == "quest" then table.insert(why, "it's a quest reward, so it's guaranteed")
    elseif k == "crafted" then table.insert(why, "you can make it or buy it")
    elseif k == "vendor" then table.insert(why, "you can buy it from a vendor")
    elseif k == "rep" then table.insert(why, "it's a reputation reward, a steady grind")
    elseif rate and firstRate and rate > firstRate * 1.3 then
        table.insert(why, "it drops more often (" .. ns.FormatChance(rate) .. " against " .. ns.FormatChance(firstRate) .. ")")
    elseif rate and firstKind == "crafted" then
        table.insert(why, "it's a " .. ns.FormatChance(rate) .. " drop, so you can skip the crafting cost")
    end
    if d.isPre then table.insert(why, "you need it for the Tier 0.5 quest anyway") end
    if #why == 0 then
        return "A little weaker than 1st place; a solid pick until you get 1st place."
    end
    return "A little weaker than 1st place, but " .. table.concat(why, ", and ") .. "."
end

-- Notes without references to where the list came from
local function cleanWhy(text)
    if not text then return nil end
    text = text:gsub("%s*In the best%-in%-slot set%.?", "")
    text = text:gsub("%s*In the Realistic set, the easier%-to%-get gear%.?", " Easier to get.")
    text = text:gsub("%s*In the Realistic set%.?", " Easier to get.")
    text = text:gsub("%s*%(page prose%)", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" or text == "." then return nil end
    return text
end

-- A word on the odds, for fun
function ns.DropMood(rate)
    if not rate then return "" end
    if rate >= 50 then return "practically yours"
    elseif rate >= 25 then return "decent odds"
    elseif rate >= 10 then return "bring snacks"
    elseif rate >= 3 then return "clear your weekend"
    elseif rate >= 1 then return "good luck"
    else return "pray to RNG" end
end

-- Currencies in sources ("75 Tarnished Undermine Real", "120 Merchant's Favor"):
-- how many you have, from the currency list or your bags and bank
local COST_NAMES = { "Tarnished Undermine Real", "Merchant's Favor" }
function ns.CurrencyHave(name)
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize and C_CurrencyInfo.GetCurrencyListInfo then
        local ok, n = pcall(C_CurrencyInfo.GetCurrencyListSize)
        for i = 1, (ok and n or 0) do
            local okI, info = pcall(C_CurrencyInfo.GetCurrencyListInfo, i)
            if okI and type(info) == "table" and info.name == name and not info.isHeader then
                return info.quantity or 0
            end
        end
    end
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    if count then
        local ok, n = pcall(count, name, true)
        if ok and tonumber(n) then return tonumber(n) end
    end
    return nil
end

-- Add "(have N)" after each cost in a source line: green when you have enough
function ns.AnnotateCost(text)
    if type(text) ~= "string" then return text end
    for _, name in ipairs(COST_NAMES) do
        local plain = name:gsub("%p", "%%%0")
        text = text:gsub("(%d+) (" .. plain .. ")", function(need, n)
            local have = ns.CurrencyHave(name)
            if not have then return need .. " " .. n end
            local color = have >= tonumber(need) and "|cff33ff33" or "|cffffd100"
            return need .. " " .. n .. " " .. color .. "(have " .. have .. ")|r"
        end)
    end
    return text
end

-- redraw when the amount of a currency you're saving up for changes
local lastCostKey
local function costKey()
    local parts = {}
    for _, name in ipairs(COST_NAMES) do table.insert(parts, tostring(ns.CurrencyHave(name))) end
    return table.concat(parts, ":")
end
local function costChanged()
    if not frame or not frame:IsShown() then return end
    local key = costKey()
    if lastCostKey and key ~= lastCostKey then ns.RefreshBrowser() end
    lastCostKey = key
end
ns.On("CURRENCY_DISPLAY_UPDATE", costChanged)
ns.On("BAG_UPDATE_DELAYED", costChanged)

-- Drop the stat parts of a note ("1% hit", "Agility +8", "15% ranged attack
-- speed", "7 defense"): the item's tooltip already shows those. Keeps the
-- rest ("Best quiver (bows, crossbows)", "tank version"). nil if nothing left.
local function isStat(part)
    part = part:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%.$", "")
    if part == "" then return true end
    if part:match("^[%+%-]?%d+%.?%d*%%?%s+[%a%s]+$") then return true end   -- 1% hit, +8 Strength, 15% ranged attack speed
    if part:match("^[%a%s]+%s[%+%-]%d+%.?%d*%%?$") then return true end    -- Agility +8, armor +40
    if part:match("^[Nn]o %a+$") then return true end                        -- No hit
    return false
end

function ns.NoteWithoutStats(note)
    if type(note) ~= "string" then return note end
    local parts, depth, cur = {}, 0, ""
    for ch in note:gmatch(".") do
        if ch == "(" then depth = depth + 1 elseif ch == ")" then depth = depth - 1 end
        if (ch == "," or ch == ";") and depth == 0 then
            table.insert(parts, cur); cur = ""
        else
            cur = cur .. ch
        end
    end
    table.insert(parts, cur)
    local keep = {}
    for _, p in ipairs(parts) do
        if not isStat(p) then table.insert(keep, (p:gsub("^%s+", ""):gsub("%s+$", ""))) end
    end
    if #keep == 0 then return nil end
    return table.concat(keep, ", ")
end

local function podiumWhyEnter(self)
    local card, place = self.card, self.place
    local e = card.entry
    local d = e and e.places[place]
    if not d then return end
    local guide = currentGuide()
    local info = guide and ns.Phases[guide.phase] or {}
    local role = ns.SpecRole and ns.SpecRole(ns.char.selectedClass, ns.char.selectedSpec)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Why " .. ns.PLACE_NAMES[place] .. " place?", 1, 0.82, 0)
    -- the reason, from the item itself: what it gives your spec, and (for
    -- 2nd / 3rd) why you might take it over 1st
    local keyStats = itemStatLine(d, role)
    if keyStats ~= "" then GameTooltip:AddLine(keyStats, 1, 1, 1, true) end
    GameTooltip:AddLine(placeReason(d, place, e.places[1]), 0.8, 0.8, 0.8, true)
    if place == 1 and e.second then
        GameTooltip:AddLine("You wear two, so both of these are 1st place.", 0.8, 0.8, 0.8, true)
    end
    -- stats against the neighbouring place
    local other, otherPlace
    if place == 1 then other, otherPlace = e.places[2], 2 else other, otherPlace = e.places[1], 1 end
    if other then
        local diffs = statDiff(d, other, role)
        if #diffs > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Compared with " .. ns.PLACE_NAMES[otherPlace] .. " place:", 0.8, 0.8, 0.8)
            for _, x in ipairs(diffs) do
                if x.up then GameTooltip:AddLine("  " .. x.text, 0.3, 1, 0.3) else GameTooltip:AddLine("  " .. x.text, 1, 0.4, 0.4) end
            end
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("How to get it", 0.8, 0.8, 0.8)
    GameTooltip:AddLine(howToGet(d), 1, 1, 1, true)
    local dn = ns.NoteWithoutStats(d.note)
    if dn then GameTooltip:AddLine(dn, 0.67, 0.67, 0.67, true) end
    local notes = cleanWhy(d.why ~= d.note and d.why or nil)
    if notes then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Notes", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(notes, 1, 1, 1, true)
    end
    -- what players report about the item (filled in from community feedback)
    local said = ns.PlayerNotes and ns.PlayerNotes[d.id]
    if said then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("What players say", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(said, 1, 1, 1, true)
    end
    GameTooltip:Show()
end

ns.PodiumWhyEnter = podiumWhyEnter   -- (tools/uitest.lua)

-- Twinkles: little stars that fade in and out over a card you've earned a
-- place on, and over that place's step. Animation groups, so no per-frame cost.
-- bright enough to show on their own step: silver goes pure white, bronze a warm orange
local TWINKLE_COLOR = { { 1, 0.85, 0.35 }, { 1, 1, 1 }, { 1, 0.55, 0.2 } }
local function makeTwinkle(parent, delay)
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetTexture(ns.TEXTURES .. "sparkle")
    t:SetBlendMode("ADD")
    t:SetAlpha(0)
    local g = t:CreateAnimationGroup()
    g:SetLooping("REPEAT")
    local wait = g:CreateAnimation("Alpha"); wait:SetFromAlpha(0); wait:SetToAlpha(0); wait:SetDuration(delay); wait:SetOrder(1)
    local up = g:CreateAnimation("Alpha"); up:SetFromAlpha(0); up:SetToAlpha(1); up:SetDuration(0.5); up:SetOrder(2)
    local spin = g:CreateAnimation("Rotation"); spin:SetDegrees(90); spin:SetDuration(1); spin:SetOrder(2)
    local down = g:CreateAnimation("Alpha"); down:SetFromAlpha(1); down:SetToAlpha(0); down:SetDuration(0.5); down:SetOrder(3)
    t.anim = g
    return t
end

local function setTwinkles(card, e)
    -- only 1st place sparkles: it's the reward for getting the best item
    local place = e.ownedPlace == 1 and 1 or nil
    if not card.twinkles then
        card.twinkles = {}
        for k = 1, 9 do card.twinkles[k] = makeTwinkle(card, 0.4 + (k % 5) * 0.55) end
    end
    for k, t in ipairs(card.twinkles) do
        if place then
            local c = TWINKLE_COLOR[place]
            if ns.HolidayOn() and k % 3 == 0 then t:SetVertexColor(1, 1, 1) else t:SetVertexColor(c[1], c[2], c[3]) end
            -- gold adds light; on silver / bronze a normal blend keeps the star visible
            t:SetBlendMode(place == 1 and "ADD" or "BLEND")
            -- silver and bronze stars are a touch bigger: they don't glow as much as gold
            local size = place == 1 and math.random(7, 13) or math.random(10, 16)
            t:SetSize(size, size)
            t:ClearAllPoints()
            local st = card.steps[place]
            if k <= 4 and st and st.block then
                -- on the step you've earned
                t:SetPoint("CENTER", st.block, "BOTTOMLEFT", math.random(6, math.max(8, math.floor((st.block:GetWidth() or 80) - 6))), math.random(4, 22))
            else
                -- around the card
                t:SetPoint("CENTER", card, "TOPLEFT", math.random(10, math.max(12, math.floor((card:GetWidth() or 300) - 10))), -math.random(10, 120))
            end
            t:Show()
            if not t.anim:IsPlaying() then t.anim:Play() end
        else
            t.anim:Stop()
            t:Hide()
        end
    end
end

local function createCard(i)
    local card = CreateFrame("Frame", nil, scrollChild)
    card:SetSize(CARD_W, CARD_H)
    card.bg = card:CreateTexture(nil, "BACKGROUND")
    card.bg:SetAllPoints()
    card.bg:SetColorTexture(0, 0, 0, 0.35)
    edge(card, "TOPLEFT", "TOPRIGHT", nil, 1); edge(card, "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    edge(card, "TOPLEFT", "BOTTOMLEFT", 1); edge(card, "TOPRIGHT", "BOTTOMRIGHT", 1)
    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.title:SetPoint("TOPLEFT", 10, -8)
    card.wear = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.wear:SetPoint("TOPRIGHT", -10, -9)
    card.wear:SetTextColor(1, 0.82, 0)
    card.steps = {}
    for place = 1, 3 do
        local st = {}
        st.block = card:CreateTexture(nil, "ARTWORK")
        st.block:SetHeight(STEP_H[place])
        st.num = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        st.num:SetPoint("CENTER", st.block, "CENTER", 0, 0)
        st.num:SetText(place)
        st.num:SetTextColor(0.15, 0.1, 0.05)
        -- drop chance on the step itself
        st.rateTag = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        st.rateTag:SetPoint("RIGHT", st.block, "RIGHT", -5, 0)
        st.rateTag:SetTextColor(1, 0.95, 0.85)
        -- boss / quest: brighter, up to two lines, click for details
        st.src = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        st.src:SetPoint("BOTTOM", st.block, "TOP", 0, 3)
        st.src:SetHeight(22)
        st.src:SetJustifyH("CENTER")
        st.src:SetJustifyV("BOTTOM")
        st.src:SetWordWrap(true)
        if st.src.SetMaxLines then st.src:SetMaxLines(2) end
        st.src:SetTextColor(0.85, 0.82, 0.74)
        st.srcHit = CreateFrame("Button", nil, card)
        st.srcHit:SetPoint("TOPLEFT", st.src, "TOPLEFT", -2, 2)
        st.srcHit:SetPoint("BOTTOMRIGHT", st.src, "BOTTOMRIGHT", 2, -2)
        st.srcHit:SetScript("OnClick", function(self) sourceClick(self, st) end)
        st.srcHit:SetScript("OnEnter", function(self) sourceEnter(self, st) end)
        st.srcHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
        st.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        st.name:SetPoint("BOTTOM", st.src, "TOP", 0, 1)
        st.name:SetJustifyH("CENTER")
        st.name:SetWordWrap(true)
        if st.name.SetMaxLines then st.name:SetMaxLines(2) end
        local size = place == 1 and 36 or 30
        local btn = makeItemButton(card, size)
        btn:SetPoint("BOTTOM", st.name, "TOP", 0, 3)
        st.btn = btn
        if place == 1 then
            -- rings / trinkets: the second 1st place pick stands beside the first
            st.btn2 = makeItemButton(card, 32)
            st.btn2:SetPoint("BOTTOM", st.name, "TOP", 19, 3)
            st.btn2:Hide()
        end
        -- the trophy stands on its step, in place of the number
        st.trophy = card:CreateTexture(nil, "OVERLAY")
        local tsz = ({ 32, 26, 22 })[place]
        st.trophy:SetSize(tsz, tsz)
        st.trophy:SetPoint("CENTER", st.block, "CENTER", 0, 0)
        if place == 1 then
            st.trophyBright = card:CreateTexture(nil, "OVERLAY")
            st.trophyBright:SetAllPoints(st.trophy)
            st.trophyBright:SetBlendMode("ADD")
            st.trophyBright:SetAlpha(0.3)
            st.starGlow = card:CreateTexture(nil, "OVERLAY")
            st.starGlow:SetTexture(ns.TEXTURES .. "halo")
            st.starGlow:SetBlendMode("ADD")
            st.starGlow:SetVertexColor(1, 0.9, 0.4)
            st.starGlow:SetSize(22, 22)
            st.starGlow:SetPoint("CENTER", st.trophy, "TOP", 0, -3)
            st.starGlow:SetAlpha(0.75)
        end
        if place == 1 then
            st.sparkle = ns.CreateSparkle(card, btn)
        end
        -- hover the numbered step: why it is in this place
        st.why = CreateFrame("Frame", nil, card)
        st.why:SetAllPoints(st.block)
        st.why:EnableMouse(true)
        st.why.card, st.why.place = card, place
        st.why:SetScript("OnEnter", podiumWhyEnter)
        st.why:SetScript("OnLeave", function() GameTooltip:Hide() end)
        st.empty = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        st.empty:SetPoint("BOTTOM", st.block, "TOP", 0, 8)
        st.empty:SetText("No " .. ns.PLACE_NAMES[place] .. " pick")
        card.steps[place] = st
    end
    podiumCards[i] = card
    return card
end

local function layoutPodium()
    local w = scrollChild:GetWidth() or CARD_W
    local cols = math.max(1, math.floor((w + CARD_GAP) / (CARD_W + CARD_GAP)))
    local cw = math.floor((w - (cols - 1) * CARD_GAP) / cols)
    local side = math.floor((cw - 28) * 0.31)
    local mid = cw - 28 - 2 * side
    local xs = { [2] = 10, [1] = 10 + side + 4, [3] = 10 + side + 4 + mid + 4 }
    local ws = { [2] = side, [1] = mid, [3] = side }
    local shown = 0
    for _, card in ipairs(podiumCards) do
        if card:IsShown() then
            local col, rowN = shown % cols, math.floor(shown / cols)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", col * (cw + CARD_GAP), -rowN * (CARD_H + CARD_GAP))
            card:SetWidth(cw)
            for place, st in ipairs(card.steps) do
                st.block:ClearAllPoints()
                st.block:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", xs[place], 8)
                st.block:SetWidth(ws[place])
                st.src:SetWidth(ws[place] - 2)
                st.name:SetWidth(ws[place] - 2)
            end
            shown = shown + 1
        end
    end
    return math.ceil(shown / cols) * (CARD_H + CARD_GAP)
end

local function fillItemButton(st, btn, d, nameKey)
    btn.data, btn.link = d, nil
    btn.tex:SetTexture(C_Item.GetItemIconByID(d.id) or 134400)
    btn.own:SetShown(ns.Owned[d.id] ~= nil)
    local token = st.token
    ns.WithItem(d.id, function(item)
        if st.token ~= token then return end
        if not item then st[nameKey] = "|cffff5555Item " .. d.id .. "|r"
        else
            btn.link = item:GetItemLink()
            btn.tex:SetTexture(item:GetItemIcon())
            local text = (btn.link or item:GetItemName() or ""):gsub("[%[%]]", "")
            st[nameKey] = text
        end
        st.name:SetText(st.names2 and ((st.n1 or "...") .. "\n" .. (st.n2 or "...")) or st.n1)
    end)
end

-- d2: the second 1st place pick for rings / trinkets (both are worn)
local function fillStep(card, st, place, d, holiday, d2)
    local on = d ~= nil
    -- a deeper shade of gold / silver / bronze, so the trophy on it stands out
    local c = STEP_COLOR[place]
    st.block:SetColorTexture(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, on and 0.95 or 0.18)
    st.num:SetShown(false)
    st.src:SetShown(on); st.name:SetShown(on); st.btn:SetShown(on); st.trophy:SetShown(on)
    if st.trophyBright and not on then st.trophyBright:Hide(); st.starGlow:Hide() end
    st.empty:SetShown(not on)
    local two = on and d2 ~= nil and st.btn2 ~= nil
    if st.btn2 then
        st.btn2:SetShown(two)
        st.btn:ClearAllPoints()
        st.btn:SetPoint("BOTTOM", st.name, "TOP", two and -19 or 0, 3)
        st.btn:SetSize(two and 32 or 36, two and 32 or 36)
        if not two then st.btn2.data = nil end
    end
    if st.sparkle then ns.ShowSparkle(st.sparkle, on, two and 32 or 36) end
    if not on or two then st.rateTag:SetText("") end
    if not on then st.btn.data = nil; st.srcHit:Hide() return end
    st.trophy:ClearAllPoints()
    st.trophy:SetPoint("CENTER", st.block, "CENTER", 0, 0)
    st.trophy:SetTexture(ns.PlaceIcon(place))
    if st.trophyBright then
        st.trophyBright:SetTexture(ns.PlaceIcon(place))
        st.trophyBright:Show()
        st.starGlow:SetShown(ns.HolidayOn())
    end
    st.token = (st.token or 0) + 1
    st.names2, st.n1, st.n2 = two, nil, nil
    if two then
        st.src:SetText("Wear both")
        if st.sparkle2 == nil then st.sparkle2 = ns.CreateSparkle(card, st.btn2) end
    else
        local dungeon, bossText = ns.SplitSource(d.source)
        local rate = ns.DropChance(d.id, d.source)
        local from = d.craft and d.craft.from or d.source
        st.boss = ns.FindBoss and ns.FindBoss(from) or nil
        st.quests = (not st.boss) and ns.QuestsInSource and ns.QuestsInSource(from) or nil
        st.questInLog = (not st.boss) and ns.QuestInLog and ns.QuestInLog(from) or nil
        st.dungeonName, st.dropRate = dungeon, rate and ns.FormatChance(rate) or nil
        local text = bossText ~= "" and bossText or dungeon
        -- not a boss: say where (e.g. "Dire Maul East: Trash Drop (satyrs)")
        local general = { Crafted = true, Reputation = true, ["World Drop"] = true, Quest = true, [""] = true }
        if not st.boss and bossText ~= "" and not general[dungeon] and not bossText:find("^Quest: ") then
            text = dungeon .. ": " .. bossText
        end
        local isQuest = text:find("^Quest: ") ~= nil
        if isQuest then text = text:sub(8) end
        if isQuest or st.quests or st.questInLog then text = "|cffffd100Quest:|r " .. text end
        if st.boss then text = ns.BOSS_ICON .. text end
        st.rateTag:SetText(rate and ns.FormatChance(rate) or "")
        st.src:SetText(ns.AnnotateCost(text))
    end
    local clickable = not two and (st.boss or st.quests or st.questInLog) ~= nil
    st.srcHit:SetShown(on and clickable)
    if st.sparkle2 then ns.ShowSparkle(st.sparkle2, two, 32) end
    st.name:SetText("|cff888888...|r")
    fillItemButton(st, st.btn, d, "n1")
    if two then fillItemButton(st, st.btn2, d2, "n2") end
end

-- slots: { { slot =, places = { [1] = row, [2] = row, [3] = row }, done = bool }, ... }
local function fillPodium(slots)
    ns._podiumSlots = slots   -- (tools/uitest.lua)
    local holiday = ns.HolidayOn()
    for i, e in ipairs(slots) do
        local card = podiumCards[i] or createCard(i)
        card:Show()
        card.title:SetText(e.slot .. (e.weaponChoice and (e.slot == "Two Hand"
            and "  |cffaaaaaa(instead of one-handers)|r" or "  |cffaaaaaa(instead of a two-hander)|r") or ""))
        card.entry = e
        card.wear:SetText(ns.PAIRED_SLOTS[e.slot] and "wear 2" or "")
        for place = 1, 3 do
            fillStep(card, card.steps[place], place, e.places[place], holiday, place == 1 and e.second or nil)
        end
        card:SetAlpha(1)   -- finished slots keep full color; the green tick shows they are done
        local tint = e.ownedPlace and PLACE_TINT[e.ownedPlace]
        if tint then card.bg:SetColorTexture(tint[1], tint[2], tint[3], tint[4] + 0.06)
        else card.bg:SetColorTexture(0, 0, 0, 0.35) end
        celebrateIfNewlyDone((ns.char.selectedClass or "") .. ":" .. (ns.char.selectedSpec or "") .. "|card|" .. e.slot, e.done, card)
        setTwinkles(card, e)
        card:Show()
    end
    for i = #slots + 1, #podiumCards do
        podiumCards[i]:Hide()
        local st1 = podiumCards[i].steps[1]
        if st1.sparkle then ns.ShowSparkle(st1.sparkle, false) end
        if st1.sparkle2 then ns.ShowSparkle(st1.sparkle2, false) end
    end
    scrollChild:SetHeight(math.max(1, layoutPodium()))
end

function ns.PodiumCards() return podiumCards end   -- for tools/uitest.lua

local function hidePodium()
    for _, card in ipairs(podiumCards) do
        card:Hide()
        if card.steps[1].sparkle then ns.ShowSparkle(card.steps[1].sparkle, false) end
        if card.steps[1].sparkle2 then ns.ShowSparkle(card.steps[1].sparkle2, false) end
    end
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

    ns.UpdateSpecBar()
    phaseButton:SetText(ns.PhaseLabel(phase))
    classButton:SetText(classColorHex(ns.char.selectedClass) .. className(ns.char.selectedClass) .. "|r")
    specButton:SetText(ns.char.selectedSpec or "")
    slotButton:SetText("Slot: " .. (ns.char.selectedSlot or "All"))
    -- An upcoming phase's planning page replaces the list
    local preview = ns.char.previewPhase and ns.Previews and ns.Previews[ns.char.previewPhase]
    if preview and ns.Phases[preview.id] then preview, ns.char.previewPhase = nil, nil end   -- its lists arrived
    if preview then
        phaseButton:SetText(preview.label)
        ns.UpdateListTabs(nil, guide)
        frame.listScroll:Hide()
        frame.raidPane:Hide()
        for _, h in pairs(frame.headers or {}) do h:Hide() end
        countText:SetText("")
        ns.ShowPreview(frame.previewPane, preview)
        frame.previewPane:Show()
        return
    end
    frame.previewPane:Hide()
    -- About tab: version, links, patch notes
    if ns.char.listMode == "about" then
        ns.UpdateListTabs("about", guide)
        frame.listScroll:Hide()
        frame.raidPane:Hide()
        for _, h in pairs(frame.headers or {}) do h:Hide() end
        countText:SetText("")
        ns.ShowAboutPage(frame.previewPane)
        frame.previewPane:Show()
        return
    end
    -- Pet tab (hunters): the pet page replaces the item list
    -- the Pet tab is for your own hunter (whatever class the browser shows)
    local function playerIsHunter() local _, c = UnitClass("player"); return c == "HUNTER" end
    if ns.char.listMode == "pet" and not playerIsHunter() then ns.char.listMode = "ranked" end
    if ns.char.listMode == "pet" then
        ns.UpdateListTabs("pet", guide)
        frame.listScroll:Hide()
        frame.raidPane:Hide()
        for _, h in pairs(frame.headers or {}) do h:Hide() end
        countText:SetText("")
        local _, mySpec = ns.GetActiveSpec()
        ns.ShowPetPage(frame.previewPane, mySpec)
        frame.previewPane:Show()
        return
    end
    -- Raid Check tab: the report replaces the item list
    if ns.char.listMode == "raid" then
        ns.UpdateListTabs("raid", guide)
        frame.listScroll:Hide()
        for _, h in pairs(frame.headers or {}) do h:Hide() end
        countText:SetText("")
        frame.raidPane:Show()
        frame.raidPane.view.refresh()
        return
    end
    frame.raidPane:Hide()
    frame.listScroll:Show()

    -- the Gear tab (1st / 2nd / 3rd place) replaces the BiS and Realistic tabs
    if not ns.char.rankedSeen then
        ns.char.rankedSeen = true
        if ns.char.listMode == "bis" or ns.char.listMode == "realistic" then ns.char.listMode = "ranked" end
    end
    ns.UpdateHolidayDecor()
    local mode = "ranked"
    if ns.char.listMode == "bis" then mode = "bis"
    elseif ns.char.listMode == "realistic" and guide.realistic then mode = "realistic"
    elseif ns.char.listMode == "enchants" and guide.enchants then mode = "enchants"
    elseif ns.char.listMode == "consumables" and guide.consumables then mode = "consumables" end
    local gearList = mode == "bis" or mode == "realistic" or mode == "ranked"
    frame.podiumOn = mode == "ranked" and ns.char.gearView == "podium"
    viewButton:SetShown(mode == "ranked" and not frame.compact)
    viewButton:SetText(frame.podiumOn and "View: Podium" or "View: List")
    local realistic = mode == "realistic"
    ns.UpdateListTabs(mode, guide)
    -- (headers are set in ns.LayoutHeaders)
    if frame.layoutMode ~= mode then
        frame.layoutMode = mode
        local onSize = frame:GetScript("OnSizeChanged")
        if onSize then onSize(frame, frame:GetWidth(), frame:GetHeight()) end
    end
    ns.LayoutHeaders()
    -- alternatives belong to the BiS list; "hide finished slots" to the gear lists
    altLabel:SetText(mode == "ranked" and "2nd & 3rd" or "Alternatives")
    if mode ~= "bis" and mode ~= "ranked" then altCheck:Disable(); altLabel:SetAlpha(0.4) else altCheck:Enable(); altLabel:SetAlpha(1) end
    if mode == "consumables" then doneCheck:Disable(); doneLabel:SetAlpha(0.4) else doneCheck:Enable(); doneLabel:SetAlpha(1) end
    missingCheck:SetChecked(ns.char.missingOnly)
    altCheck:SetChecked(ns.char.showAlts ~= false)
    doneCheck:SetChecked(ns.char.hideDone)
    -- podium cards always show every place, so "2nd & 3rd" hides there and
    -- "Hide finished" moves up next to "Missing only"
    if not frame.compact then
        altCheck:SetShown(not frame.podiumOn)
        altLabel:SetShown(not frame.podiumOn)
        doneCheck:ClearAllPoints()
        doneCheck:SetPoint("LEFT", frame.podiumOn and frame.mcLabel or altLabel, "RIGHT", 10, 0)
    end

    -- Done slots. Each main row has a key ("Head#1", "Finger#2"...) that is the
    -- same in the BiS and Realistic lists, so a slot can be done with a piece
    -- from either list. A key is done when you tick it, or automatically when
    -- you own enough of that slot's BiS / Realistic picks.
    local specKey = (ns.char.selectedClass or "") .. ":" .. (ns.char.selectedSpec or "")
    local canMark = gearList or mode == "enchants"
    local listRows
    if mode == "ranked" then
        listRows = ns.GetRankedRows(guide)
        -- the best place you own in each slot (tints the slot gold / silver / bronze)
        local best = {}
        for _, r in ipairs(listRows) do
            if r.place and not r.isPre and ns.Owned[r.id] then
                best[r.slot] = math.min(best[r.slot] or 9, r.place)
            end
        end
        for _, r in ipairs(listRows) do
            r.ownedPlace = (not r.isAlt) and best[r.slot] or nil
        end
    else
        listRows = ns.GetGuideRows(guide, mode == "bis" and ns.char.showAlts ~= false, mode)
    end
    local seenSlot = {}
    for _, r in ipairs(listRows) do
        if not r.isAlt and canMark then
            local n = (r.slot == "Ammo" or r.slot == "Quiver") and 1 or ((seenSlot[r.slot] or 0) + 1)   -- one ammo / quiver slot
            seenSlot[r.slot] = n
            r.doneKey = (mode == "enchants" and "E:" or "") .. r.slot .. "#" .. n
        end
    end
    -- signature per key: the items the BiS and Realistic lists (or the enchant
    -- list) have for that slot, so a list update clears outdated ticks
    local sigs = {}
    if canMark then
        local function collect(rows, prefix, into)
            local seen = {}
            for _, r in ipairs(rows) do
                if not r.isAlt then
                    local n = (r.slot == "Ammo" or r.slot == "Quiver") and 1 or ((seen[r.slot] or 0) + 1)
                    seen[r.slot] = n
                    local key = prefix .. r.slot .. "#" .. n
                    into[key] = (into[key] and (into[key] .. ",") or "") .. r.id
                end
            end
        end
        if gearList then
            local b, rl = {}, {}
            collect(ns.GetGuideRows(guide, false, "bis"), "", b)
            if guide.realistic then collect(ns.GetGuideRows(guide, false, "realistic"), "", rl) end
            for key, ids in pairs(b) do sigs[key] = ids .. "|" .. (rl[key] or "") end
            for key, ids in pairs(rl) do sigs[key] = sigs[key] or ("|" .. ids) end
        else
            collect(ns.GetGuideRows(guide, false, "enchants"), "E:", sigs)
        end
    end
    local auto = {}
    local ownedForSlot = {}   -- [slot] = { { id, list = "bis"/"realistic" }, ... } you own
    if gearList then
        local seen = {}
        for _, m in ipairs({ "bis", "realistic" }) do
            for _, r in ipairs(ns.GetGuideRows(guide, false, m)) do
                if not r.isAlt and ns.Owned[r.id] and not seen[r.id] then
                    seen[r.id] = true
                    ownedForSlot[r.slot] = ownedForSlot[r.slot] or {}
                    table.insert(ownedForSlot[r.slot], { id = r.id, list = m })
                end
            end
        end
        for slot, list in pairs(ownedForSlot) do
            for k = 1, #list do auto[slot .. "#" .. k] = true end
        end
        -- which owned item makes each row done: its own item if you have it,
        -- otherwise one from the other list (e.g. BiS equipped, seen on Realistic)
        local used = {}
        for _, r in ipairs(listRows) do
            if r.doneKey then r.doneBy = nil end
            if r.doneKey and ns.Owned[r.id] then used[r.id] = true end
        end
        for _, r in ipairs(listRows) do
            if r.doneKey and not ns.Owned[r.id] and auto[r.doneKey] then
                for _, e in ipairs(ownedForSlot[r.slot] or {}) do
                    if not used[e.id] then used[e.id] = true; r.doneBy = e; break end
                end
            end
        end
    end
    if mode == "enchants" and ns.SlotEnchant then
        -- an enchanted slot counts as done
        for _, r in ipairs(listRows) do
            if r.doneKey and select(2, ns.SlotEnchant(r.slot)) then auto[r.doneKey] = true end
        end
    end
    local slotKeys, slotDone = {}, {}
    local clearedSlots = {}
    for _, r in ipairs(listRows) do
        if r.doneKey then
            r.autoDone = auto[r.doneKey] or false
            -- a tick (true) or untick (false) overrides the automatic state
            r.doneSig = sigs[r.doneKey]
            local mark, cleared = ns.ResolveDoneMark(specKey, r.doneKey, r.doneSig)
            if cleared then table.insert(clearedSlots, r.slot) end
            if mark ~= nil then r.isDone = mark else r.isDone = r.autoDone end
            slotKeys[r.slot] = slotKeys[r.slot] or {}
            table.insert(slotKeys[r.slot], r)
        end
    end
    if #clearedSlots > 0 and ns.Print then
        ns.Print("The lists changed for " .. table.concat(clearedSlots, ", ")
            .. ": those slots were unticked so you can check the new picks.")
    end
    for slot, list in pairs(slotKeys) do
        local all = true
        for _, r in ipairs(list) do if not r.isDone then all = false end end
        slotDone[slot] = all
    end

    -- Enchants tab: slots where you have the BiS or Realistic item (any of
    -- equipped / bags / bank), i.e. you could enchant it now
    local gearForSlot = {}
    if mode == "enchants" then
        for _, m in ipairs({ "bis", "realistic" }) do
            for _, r in ipairs(ns.GetGuideRows(guide, false, m)) do
                if not r.isAlt and ns.Owned[r.id] then gearForSlot[r.slot] = true end
            end
        end
    end

    local list = {}
    local have, total = 0, 0
    for _, r in ipairs(listRows) do
        if not r.isAlt then
            total = total + 1
            if mode == "consumables" then
                -- stocked: at least as many as you want to keep
                local target = ns.ConsumeTarget(r.id, r.slot)
                local _, total = ns.ConsumeCount(r.id)
                if target == 0 then total, target = 1, 1 end
                if total >= target then have = have + 1 end
            elseif (canMark and r.isDone) or (not canMark and ns.Owned[r.id]) then have = have + 1 end
        end
    end
    local hiddenSlots = {}   -- finished slots "Hide finished" is hiding
    for _, r in ipairs(listRows) do
        local owned = ns.Owned[r.id] ~= nil
        if mode == "consumables" then
            -- "Missing only" here means: fewer than you want to keep
            local target = ns.ConsumeTarget(r.id, r.slot)
            local _, total = ns.ConsumeCount(r.id)
            owned = total >= target
        end
        local slotOk = ns.char.selectedSlot == "All" or r.slot == ns.char.selectedSlot or mode == "consumables"
        local hidden = ns.char.hideDone and canMark and (r.doneKey and r.isDone or (not r.doneKey and slotDone[r.slot]))
        if hidden and not r.isAlt and slotOk then hiddenSlots[r.slot] = true end
        -- a Tier 0 piece you own stays visible under its missing Tier 0.5
        -- upgrade, so you can see you're ready to turn it in
        if r.isPre and owned and r.upgrade and not ns.Owned[r.upgrade] then owned = false end
        -- 2nd / 3rd place show when "2nd & 3rd" is ticked or the slot is opened
        local closed = r.isExtra and ns.char.showAlts == false
            and not (ns.char.expandedSlots and ns.char.expandedSlots[r.slot])
        if slotOk and not hidden and not closed and not (ns.char.missingOnly and owned) then
            r.isNew = (mode == "bis" or mode == "ranked") and (not r.isAlt) and prevSet ~= nil and not prevSet[r.id]
            r.specKey = specKey
            if gearList and not r.isAlt then
                r.enchantID, r.enchantNote, r.enchantSource = enchantFor(guide, r.slot)
            else
                r.enchantID, r.enchantNote, r.enchantSource = nil, nil, nil
            end
            r.craft = (mode == "consumables" or mode == "enchants") and ns.Crafting and ns.Crafting[r.id] or nil
            r.craftTab = (mode == "consumables" or mode == "enchants") or nil
            if mode == "enchants" then
                r.gearReady = gearForSlot[r.slot] or false
                r.enchanted = r.gearReady and ns.SlotEnchant and select(2, ns.SlotEnchant(r.slot)) or false
            end
            table.insert(list, r)
        end
    end

    if gearList or mode == "enchants" or mode == "consumables" then list = ns.SortRows(list) end
    if frame.podiumOn then
        -- one card per slot, with every place (whatever "2nd & 3rd" says)
        for i = 1, #rows do rows[i]:Hide() end
        local slots, bySlot = {}, {}
        for _, r in ipairs(listRows) do
            if r.place and not r.isPre then
                local e = bySlot[r.slot]
                if not e then
                    e = { slot = r.slot, places = {}, done = slotDone[r.slot], allOwned = true,
                          weaponChoice = r.weaponChoice, ownedPlace = r.ownedPlace }
                    bySlot[r.slot] = e
                    table.insert(slots, e)
                end
                if r.place == 1 and e.places[1] and not r.isAlt then
                    e.second = e.second or r   -- rings / trinkets: two 1st place picks
                else
                    e.places[r.place] = e.places[r.place] or r
                end
                if not r.isAlt and not ns.Owned[r.id] then e.allOwned = false end
            end
        end
        local shownSlots = {}
        for _, e in ipairs(slots) do
            local slotOk = ns.char.selectedSlot == "All" or e.slot == ns.char.selectedSlot
            local hidden = ns.char.hideDone and e.done
            if hidden and slotOk then hiddenSlots[e.slot] = true end
            if slotOk and not hidden and not (ns.char.missingOnly and e.allOwned) then
                table.insert(shownSlots, e)
            end
        end
        fillPodium(shownSlots)
    else
        hidePodium()
        -- Enchants / Consumables (full width): taller rows, one material per line
        local tall = (mode == "enchants" or mode == "consumables") and not frame.compact
        local y = 0
        for i, data in ipairs(list) do
            local row = rows[i] or createRow(i)
            local h = tall and craftRowHeight(data) or ROW_HEIGHT
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -y)
            row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
            row:SetHeight(h)
            fillRow(row, data)
            y = y + h
        end
        for i = #list + 1, #rows do rows[i]:Hide() end
        scrollChild:SetHeight(math.max(1, y))
    end

    countText:SetText(string.format(mode == "consumables" and "Stocked %d / %d" or "Done %d / %d", have, total))
    -- say how many finished slots are tucked away, so nothing seems missing
    local nHidden = 0
    for _ in pairs(hiddenSlots) do nHidden = nHidden + 1 end
    if doneLabel then
        doneLabel:SetText(nHidden > 0 and ("Hide finished |cff33ff33(" .. nHidden .. " hidden)|r") or "Hide finished")
    end
    frame.hiddenCount = nHidden
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
    elseif mode == "ranked" then
        text = text .. "  |  1st place: BiS list. 2nd / 3rd: "
            .. (guide.altSource or info.altSource or "alternatives") .. " and the Realistic set"
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

-- Consumable counts change without the owned list changing (using a potion,
-- buying more), so the Consumables tab redraws on bag changes itself.
local stockPending = false
ns.On("BAG_UPDATE_DELAYED", function()
    if stockPending or not frame or not frame:IsShown()
        or (ns.char.listMode ~= "consumables" and ns.char.listMode ~= "enchants") then return end
    stockPending = true
    C_Timer.After(0.5, function() stockPending = false; ns.RefreshBrowser() end)
end)

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
        root:CreateTitle("Your specs")
        for _, f in ipairs(ns.GetMySpecList()) do
            local label = classColorHex(f.class) .. f.spec .. " " .. className(f.class) .. "|r" .. (f.mine and "  |cffffd100(you)|r" or "")
            root:CreateRadio(label,
                function() return ns.char.selectedClass == f.class and ns.char.selectedSpec == f.spec end,
                function() ns.char.selectedClass, ns.char.selectedSpec = f.class, f.spec; ns.RefreshBrowser() end)
        end
        local cls, spec = ns.char.selectedClass, ns.char.selectedSpec
        local mc, ms = ns.GetActiveSpec()
        if cls and spec and not (cls == mc and spec == ms) then
            if ns.IsSavedSpec(cls, spec) then
                root:CreateButton("Remove " .. spec .. " " .. className(cls) .. " from your specs",
                    function() ns.RemoveSavedSpec(cls, spec); ns.RefreshBrowser() end)
            elseif #ns.GetSavedSpecs() < ns.MAX_SAVED_SPECS then
                root:CreateButton("Save " .. spec .. " " .. className(cls) .. " to your specs",
                    function() ns.SaveSpec(cls, spec); ns.RefreshBrowser() end)
            end
        end
        root:CreateDivider()
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
                function() return not ns.char.previewPhase and selectedPhase() == p.id end,
                function()
                    -- remember "latest" as nil so new phases are picked up automatically
                    ns.char.selectedPhase = (p.id ~= ns.LatestPhase()) and p.id or nil
                    ns.char.previewPhase = nil
                    ns.RefreshBrowser()
                end)
        end
        -- upcoming phases: planning page until their lists exist
        local any = false
        for _, p in ipairs(ns.PreviewList or {}) do
            if not ns.Phases[p.id] then
                if not any then root:CreateDivider(); root:CreateTitle("Coming up"); any = true end
                root:CreateRadio(p.label .. " - " .. (p.subtitle or "coming soon") .. "  |cffaaaaaa(planning)|r",
                    function() return ns.char.previewPhase == p.id end,
                    function() ns.char.previewPhase = p.id; ns.RefreshBrowser() end)
            end
        end
    end)
end

-- List tabs along the bottom edge of the window (like the character panel)
local LIST_TABS = {
    { mode = "ranked",      text = "Gear",        tip = "1st, 2nd and 3rd place for each slot. 1st place is the best pre-raid item; 2nd and 3rd are good picks that are often easier to get." },
    { mode = "enchants",    text = "Enchants",    tip = "The enchant, arcanum or armor kit for each slot." },
    { mode = "consumables", text = "Consumables", tip = "Raid shopping list: flask, elixirs, food, weapon oil or stone and potions." },
    { mode = "raid",        text = "Raid Check",  tip = "Is your character ready to raid? Hit, defense, empty slots, enchants and your gear's stats against the BiS set." },
    { mode = "pet",         text = "Pet",         tip = "Hunters: which pet to bring to raids for your spec, and whether your current pet is the one.", hunter = true },
    { mode = "about",       text = "About",       tip = "Version, links and patch notes: what's new in each update." },
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
            ns.char.previewPhase = nil   -- leave the planning page
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
    local have = { ranked = true, bis = true, realistic = guide and guide.realistic ~= nil,
                   enchants = guide and guide.enchants ~= nil, consumables = guide and guide.consumables ~= nil,
                   raid = true, pet = true, about = true }
    for i, info in ipairs(LIST_TABS) do
        local tab = listTabs[i]
        -- the Pet tab is only there for hunters; the shown tabs close up
        if info.hunter then tab:SetShown(select(2, UnitClass("player")) == "HUNTER") end
        if i > 1 then
            local prev
            for j = i - 1, 1, -1 do if listTabs[j]:IsShown() then prev = listTabs[j] break end end
            tab:ClearAllPoints()
            if prev then tab:SetPoint("LEFT", prev, "RIGHT", 3, 0)
            else tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 12, 2) end
        end
        if tab.skinBg then
            local c = info.mode == mode and SLEEK.tabOn or SLEEK.tab
            tab.skinBg:SetColorTexture(c[1], c[2], c[3], c[4])
        end
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
-- Holiday theme: Christmas lights along the top, holly by the title and a
-- snowy strip of trees and a moose in the footer
----------------------------------------------------------------------
-- one 256x64 tile (4 bulbs on a drooping wire) shown at 72x18 inside the title bar
local LIGHT_TILE_W, LIGHT_H = 72, 18
local LIGHT_RIGHT_GAP = 64   -- keeps the lights clear of the buttons at the top right
-- the footer scene is a wide strip (32:1); the window shows its middle part
local SCENE_FULL_W, SCENE_H, FOOTER_RIGHT = 1280, 40, 228

-- a string of lights hung inside the title bar, on both sides of the title:
-- the wire, and two sets of bulbs that blink in turn. side is "left" / "right";
-- UpdateHolidayDecor places and sizes each piece around the title text.
local function lightLayer(d, file, level, side)
    local t = d:CreateTexture(nil, "OVERLAY", nil, level)
    t:SetTexture(ns.TEXTURES .. file, "REPEAT", "CLAMP")
    t:SetHeight(LIGHT_H)
    t.side = side
    return t
end

-- a small, faraway sleigh: drawn behind the trees and the moose, high in the sky
local SANTA_W, SANTA_SPEED = 72, 55   -- sleigh size and pixels per second

-- one flight from the right end of the footer scene to the left end
local function santaFlyBy(d)
    if not d or not d.santa or not d.scene:IsShown() or not frame:IsShown() then return end
    if d.santaFly:IsPlaying() then return end
    local w = d.scene:GetWidth() or 0
    if w < SANTA_W * 2 then return end
    local dist = w - SANTA_W
    local secs = dist / SANTA_SPEED
    d.santa:ClearAllPoints()
    d.santa:SetPoint("BOTTOMRIGHT", d.scene, "BOTTOMRIGHT", 0, 22)
    d.santaMove:SetOffset(-dist, math.random(-1, 3))
    d.santaMove:SetDuration(secs)
    d.santaOut:SetStartDelay(math.max(0, secs - 0.6))
    d.santa:Show()
    d.santaFly:Play()
end

-- random gaps between flights, 45 seconds to 2.5 minutes; the first one
-- comes shortly after the window opens
local function scheduleSanta(d, soon)
    if not (C_Timer and C_Timer.After) then return end
    d.santaToken = (d.santaToken or 0) + 1
    local token = d.santaToken
    C_Timer.After(soon and math.random(6, 15) or math.random(45, 150), function()
        if d.santaToken ~= token then return end
        if ns.HolidayOn() then santaFlyBy(d) end
        scheduleSanta(d)
    end)
end
ns.SantaFlyBy = function() if frame and frame.holiday then santaFlyBy(frame.holiday) end end

local function createHolidayDecor()
    local d = CreateFrame("Frame", nil, frame)
    d:SetAllPoints()
    d:SetFrameLevel(frame:GetFrameLevel() + 20)
    d.lights, d.blinks = {}, {}
    for _, side in ipairs({ "left", "right" }) do
        table.insert(d.lights, lightLayer(d, "lights_wire", 1, side))
        for i, file in ipairs({ "lights_a", "lights_b" }) do
            local t = lightLayer(d, file, 2, side)
            table.insert(d.lights, t)
            local g = t:CreateAnimationGroup()
            g:SetLooping("BOUNCE")
            local blink = g:CreateAnimation("Alpha")
            if i == 1 then blink:SetFromAlpha(1); blink:SetToAlpha(0.25)
            else blink:SetFromAlpha(0.25); blink:SetToAlpha(1) end
            blink:SetDuration(0.8)
            table.insert(d.blinks, g)
        end
    end
    d.holly = d:CreateTexture(nil, "OVERLAY")
    d.holly:SetTexture(ns.TEXTURES .. "holly")
    d.holly:SetSize(18, 18)
    if frame.titleText then d.holly:SetPoint("RIGHT", frame.titleText, "LEFT", -4, 0) end
    d.scene = d:CreateTexture(nil, "ARTWORK")
    d.scene:SetTexture(ns.TEXTURES .. "scene")
    d.scene:SetHeight(SCENE_H)
    d.scene:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 6)
    d.scene:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -FOOTER_RIGHT, 6)
    -- the lights in the moose's antlers blink in two sets, like the top string
    d.sceneLights = {}
    for i, file in ipairs({ "scene_a", "scene_b" }) do
        local t = d:CreateTexture(nil, "OVERLAY")
        t:SetTexture(ns.TEXTURES .. file)
        t:SetAllPoints(d.scene)
        local g = t:CreateAnimationGroup()
        g:SetLooping("BOUNCE")
        local blink = g:CreateAnimation("Alpha")
        if i == 1 then blink:SetFromAlpha(1); blink:SetToAlpha(0.1)
        else blink:SetFromAlpha(0.1); blink:SetToAlpha(1) end
        blink:SetDuration(0.8)
        table.insert(d.blinks, g)
        table.insert(d.sceneLights, t)
    end
    -- Santa's sleigh flies across the footer sky now and then
    local santa = d:CreateTexture(nil, "ARTWORK", nil, -2)   -- under the scene (ARTWORK 0)
    santa:SetTexture(ns.TEXTURES .. "santa")
    santa:SetSize(SANTA_W, SANTA_W / 4)
    santa:Hide()
    d.santa = santa
    local fly = santa:CreateAnimationGroup()
    d.santaMove = fly:CreateAnimation("Translation")
    d.santaMove:SetOrder(1)
    local fadeIn = fly:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(0.85); fadeIn:SetDuration(0.6); fadeIn:SetOrder(1)
    d.santaOut = fly:CreateAnimation("Alpha")
    d.santaOut:SetFromAlpha(0.85); d.santaOut:SetToAlpha(0); d.santaOut:SetDuration(0.6); d.santaOut:SetOrder(1)
    fly:SetScript("OnFinished", function() santa:Hide() end)
    d.santaFly = fly
    return d
end

function ns.UpdateHolidayDecor()
    if not frame then return end
    local on = ns.HolidayOn and ns.HolidayOn() or false
    if on and not frame.holiday then frame.holiday = createHolidayDecor() end
    local w = frame:GetWidth() or 0
    local d = frame.holiday
    if d then
        d:SetShown(on)
        -- fill the title bar on both sides of the title (and its holly)
        local titleW = (frame.titleText and frame.titleText:GetStringWidth()) or 200
        local leftW = math.max(0, math.floor(w / 2 - titleW / 2 - 22 - 10 - 4))
        local rightX = math.floor(w / 2 + titleW / 2 + 10)
        local rightW = math.max(0, math.floor(w - LIGHT_RIGHT_GAP - rightX))
        for _, t in ipairs(d.lights) do
            local x, tw = 4, leftW
            if t.side == "right" then x, tw = rightX, rightW end
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -2)
            t:SetWidth(math.max(1, tw))
            t:SetShown(tw >= LIGHT_TILE_W / 2)
            t:SetTexCoord(0, math.max(0.5, tw / LIGHT_TILE_W), 0, 1)
        end
        for _, g in ipairs(d.blinks) do
            if on then
                if not g:IsPlaying() then g:Play() end
            else
                g:Stop()
            end
        end
        -- crop the strip from the middle so it fills the footer without stretching
        local frac = math.min(1, math.max(0.1, (w - 8 - FOOTER_RIGHT) / SCENE_FULL_W))
        local l, r = 0.5 - frac / 2, 0.5 + frac / 2
        d.scene:SetTexCoord(l, r, 0, 1)
        d.scene:SetShown(on and not frame.compact)
        if on and not d.santaScheduled then
            d.santaScheduled = true
            scheduleSanta(d, true)
        elseif not on then
            d.santaScheduled = nil
            d.santaToken = (d.santaToken or 0) + 1
            d.santaFly:Stop(); d.santa:Hide()
        end
        for _, t in ipairs(d.sceneLights) do
            t:SetTexCoord(l, r, 0, 1)
            t:SetShown(on and not frame.compact)
        end
    end
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
local function createFrame()
    frame = CreateFrame("Frame", "ForeverBiSFrame", UIParent, "BasicFrameTemplateWithInset")
    frame.sleek = ns.db.windowStyle ~= "classic"
    if frame.sleek then skinFrame(frame) end
    frame:SetSize(savedWidth(), ns.db.windowHeight or HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("MEDIUM")   -- same layer as the game's windows: whichever you click comes to the front
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

    if type(frame.CloseButton) == "table" then
        frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)   -- works in combat
    end
    -- the raid panel by the character window gives way while the browser is open
    local function sync()
        if ns.UpdateRaidCompanion then ns.UpdateRaidCompanion() end
        ns.UpdateCompact()   -- (on hide: leave compact mode so the next open is normal size)
    end
    frame:HookScript("OnShow", sync)
    frame:HookScript("OnHide", sync)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText(ns.title .. "  -  WoW Forever")
    frame.titleText = title

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
    createSpecBar()

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
    frame.mcLabel = mcLabel
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
        GameTooltip:AddLine("Hides a slot once it's done: you own one of its picks, or you ticked it done.", 1, 1, 1, true)
        if (frame.hiddenCount or 0) > 0 then
            GameTooltip:AddLine(frame.hiddenCount .. " finished slot" .. (frame.hiddenCount == 1 and " is" or "s are")
                .. " hidden right now. Untick to see " .. (frame.hiddenCount == 1 and "it" or "them") .. ".", 0.2, 1, 0.2, true)
        end
        GameTooltip:Show()
    end)
    doneCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
    doneLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    doneLabel:SetPoint("LEFT", doneCheck, "RIGHT", 2, 0)
    doneLabel:SetText("Hide finished")

    -- Gear tab: list rows or podium cards
    viewButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    viewButton:SetSize(110, 22)
    viewButton:SetPoint("LEFT", doneLabel, "RIGHT", 14, 0)
    viewButton:SetScript("OnClick", function()
        ns.char.gearView = (ns.char.gearView == "podium") and "list" or "podium"
        ns.RefreshBrowser()
    end)
    viewButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Switch view")
        GameTooltip:AddLine("List: one row per item with dungeon, boss and drop chance.", 1, 1, 1, true)
        GameTooltip:AddLine("Podium: a card per slot with 1st, 2nd and 3rd place side by side.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    viewButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- holiday theme switch: click for on / off, right-click for automatic
    local holidayButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    holidayButton:SetSize(26, 22)
    holidayButton:SetPoint("LEFT", viewButton, "RIGHT", 6, 0)
    holidayButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    holidayButton.icon = holidayButton:CreateTexture(nil, "OVERLAY")
    holidayButton.icon:SetTexture(ns.TEXTURES .. "holly")
    holidayButton.icon:SetSize(18, 18)
    holidayButton.icon:SetPoint("CENTER")
    local function holidayLook()
        local on = ns.HolidayOn()
        holidayButton.icon:SetDesaturated(not on)
        holidayButton.icon:SetAlpha(on and 1 or 0.5)
    end
    holidayButton:SetScript("OnClick", function(self, button)
        if button == "RightButton" then ns.db.holidayTheme = "auto"
        else ns.db.holidayTheme = ns.HolidayOn() and "off" or "on" end
        holidayLook()
        ns.RefreshBrowser()
        if GameTooltip:IsOwned(self) then self:GetScript("OnEnter")(self) end
    end)
    holidayButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        local mode = ns.db.holidayTheme or "auto"
        GameTooltip:AddLine("Holiday theme: " .. (mode == "auto" and "automatic" or mode))
        GameTooltip:AddLine("Christmas lights, snow, a tree, snowman and gingerbread trophies, and Santa now and then.", 1, 1, 1, true)
        GameTooltip:AddLine("Click: turn it " .. (ns.HolidayOn() and "off" or "on"), 0.2, 1, 0.2)
        GameTooltip:AddLine("Right-click: automatic (on from the day before Thanksgiving to Jan 2)", 0.2, 1, 0.2)
        GameTooltip:Show()
    end)
    holidayButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    holidayButton:SetScript("OnShow", holidayLook)
    holidayLook()
    frame.holidayButton = holidayButton
    frame.wideOnly = { missingCheck, mcLabel, altCheck, altLabel, doneCheck, doneLabel }   -- "where to get it" stays

    countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("TOPRIGHT", -40, -62)

    -- column headers
    -- column headers; the gear tabs' headers sort the list when clicked
    local function header(key, text, x)
        local b = CreateFrame("Button", nil, frame)
        b:SetSize(100, 16)
        b:SetPoint("TOPLEFT", x, -62)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT")
        fs:SetText(text)
        b.label, b.baseText, b.sortKey = fs, text, key
        b.SetText = function(self, t) self.baseText = t; self.label:SetText(t); self:SetWidth(math.max(40, (self.label:GetStringWidth() or 60) + 14)) end
        if key then
            b:SetScript("OnClick", function()
                if ns.char.sortBy == key then ns.char.sortDesc = not ns.char.sortDesc
                else ns.char.sortBy, ns.char.sortDesc = key, (key == "drop") end
                ns.RefreshBrowser()
            end)
            b:SetScript("OnEnter", function(self)
                self.label:SetTextColor(1, 1, 1)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                local name = (self.baseText or text):gsub(" [%^v]$", "")
                GameTooltip:AddLine("Click to sort by " .. name:lower())
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function(self) self.label:SetTextColor(1, 0.82, 0); GameTooltip:Hide() end)
        end
        b:SetText(text)
        return b
    end
    frame.headers = {
        item = header("slot", "ITEM", 18),
        dungeon = header("dungeon", "DUNGEON", 300),
        source = header("boss", "BOSS / SOURCE", 420),
        drop = header("drop", "DROP", 600),
        avoid = header(nil, "ENCHANT", 660),
    }
    headerSource = frame.headers.source
    headerAvoid = frame.headers.avoid
    table.insert(frame.wideOnly, headerAvoid)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -78)
    scroll:SetPoint("BOTTOMRIGHT", -32, 44)
    frame.listScroll = scroll

    -- Raid Check tab content
    local raidPane = CreateFrame("Frame", nil, frame)
    raidPane:SetPoint("TOPLEFT", 0, -44)
    raidPane:SetPoint("BOTTOMRIGHT", 0, 40)
    raidPane:Hide()
    raidPane.view = ns.CreateRaidView(raidPane, -12, 4, 600)
    frame.raidPane = raidPane

    -- Upcoming phase planning page
    local previewPane = CreateFrame("Frame", nil, frame)
    previewPane:SetPoint("TOPLEFT", 0, -44)
    previewPane:SetPoint("BOTTOMRIGHT", 0, 40)
    previewPane:Hide()
    local pScroll = CreateFrame("ScrollFrame", nil, previewPane, "UIPanelScrollFrameTemplate")
    pScroll:SetPoint("TOPLEFT", 16, -24)
    pScroll:SetPoint("BOTTOMRIGHT", -34, 6)
    local pChild = CreateFrame("Frame", nil, pScroll)
    pChild:SetSize(600, 400)
    pScroll:SetScrollChild(pChild)
    previewPane.text = pChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    previewPane.text:SetPoint("TOPLEFT", 0, 0)
    previewPane.text:SetJustifyH("LEFT")
    previewPane.text:SetJustifyV("TOP")
    previewPane.text:SetSpacing(3)
    previewPane.child, previewPane.scroll = pChild, pScroll
    frame.previewPane = previewPane
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
        if frame.raidPane then frame.raidPane.view.setWidth(math.max(300, w - 60)) end
        if self.sourceText then self.sourceText:SetWidth(w - 240) end
        ns.UpdateHolidayDecor()
        ns.LayoutHeaders()
        for _, row in ipairs(rows) do
            if row:IsShown() then layoutRow(row) end
        end
        if self.podiumOn then scrollChild:SetHeight(math.max(1, layoutPodium())) end
    end)
    scroll:SetScrollChild(scrollChild)

    -- footer
    frame.sourceText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.sourceText:SetPoint("BOTTOMLEFT", 16, 12)
    frame.sourceText:SetWidth(savedWidth() - 240)
    frame.sourceText:SetHeight(26)
    frame.sourceText:SetJustifyH("LEFT")
    frame.sourceText:SetJustifyV("MIDDLE")
    -- the footer stays clean: the source note lives in the Guide link tooltip
    frame.sourceText:Hide()

    local guideLink = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    guideLink:SetSize(110, 22)
    guideLink:SetPoint("BOTTOMRIGHT", -26, 12)
    guideLink:SetText("Guide link")
    guideLink:SetScript("OnEnter", function(self)
        local note = frame.sourceText:GetText()
        if not note or note == "" then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Sources", 1, 0.82, 0)
        GameTooltip:AddLine(note, 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    guideLink:SetScript("OnLeave", function() GameTooltip:Hide() end)
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

    if frame.sleek then
        title:SetFontObject("GameFontNormal")
        for _, b in ipairs({ phaseButton, classButton, specButton, slotButton, viewButton, holidayButton, guideLink, settings }) do skinButton(b) end
        for _, tab in ipairs(listTabs or {}) do skinButton(tab, SLEEK.tab) end
    end
    frame:SetScript("OnShow", function() ns.RefreshOwned(); ns.RefreshBrowser() end)
    -- apply the saved size to the columns once
    frame:GetScript("OnSizeChanged")(frame, frame:GetWidth(), frame:GetHeight())
end

-- Planning page for an upcoming phase: countdown, raids, your tier set,
-- timeline, how to get ready, and what isn't known yet
local function daysUntil(d)
    if not (d and time) then return nil end
    local ok, target = pcall(time, { year = d.year, month = d.month, day = d.day, hour = 12 })
    local ok2, now = pcall(time)
    if not (ok and ok2 and target and now) then return nil end
    return math.ceil((target - now) / 86400)
end

function ns.ShowPreview(pane, p)
    local w = math.max(300, (pane:GetWidth() or 640) - 60)
    pane.child:SetWidth(w)
    pane.text:SetWidth(w)
    local G, W, D = "|cffffd100", "|cffffffff", "|cffaaaaaa"
    local out = {}
    local function add(s) table.insert(out, s) end
    local days = daysUntil(p.opens)
    add("|cffffd100" .. p.label .. "|r  " .. W .. (p.subtitle or "") .. "|r"
        .. (days and days > 0 and ("   |cff33ff33" .. days .. " day" .. (days == 1 and "" or "s") .. " to go|r") or ""))
    add(D .. "Planning page: the gear lists for this phase aren't out yet.|r")
    add(" ")
    add(G .. "Raids|r")
    for _, r in ipairs(p.raids or {}) do
        add(W .. r[1] .. "|r  " .. D .. "(" .. r[2] .. ")|r  " .. r[3])
    end
    -- your tier set
    local cls, spec = ns.char.selectedClass, ns.char.selectedSpec
    local set = ns.TierSets and (ns.TierSets[(cls or "") .. ":" .. (spec or "")] or ns.TierSets[(cls or "") .. ":*"])
    if set then
        add(" ")
        add(G .. "Your tier set|r  " .. D .. "(" .. className(cls) .. ", " .. (spec or "") .. ")|r")
        add(W .. set.name .. "|r: Head, Shoulder, Chest, Hands, Legs and Feet, bonuses at 2 / 3 / 4 / 5 pieces.")
        add("Raid pieces are item level 65 (bind on pickup). Shoulder, Hands, Legs and Feet can also be crafted at item level 61 (bind on equip).")
    end
    add(" ")
    add(G .. "Timeline|r")
    for _, t in ipairs(p.timeline or {}) do
        add((t.done and "|cff33ff33" or W) .. t[1] .. "|r   " .. (t.done and D or "") .. t[2] .. (t.done and "|r" or ""))
    end
    add(" ")
    add(G .. "Get ready|r")
    for _, r in ipairs(p.ready or {}) do add("-  " .. r) end
    if p.unknown then
        add(" ")
        add(G .. "Not known yet|r")
        add(D .. p.unknown .. "|r")
    end
    if p.sources then add(" "); add(D .. p.sources .. "|r") end
    pane.text:SetText(table.concat(out, "\n"))
    pane.child:SetHeight((pane.text:GetStringHeight() or 400) + 20)
end

-- About tab: what the addon is, version, links and the patch notes
local function mdToGame(s)
    -- **bold** -> white, `code` -> gold
    s = s:gsub("%*%*(.-)%*%*", "|cffffffff%1|r")
    s = s:gsub("`(.-)`", "|cffffd100%1|r")
    return s
end

-- TL;DR of a patch note: its bold title ("**Holiday button:** a holly...")
-- or, without one, its first sentence
local function tldr(note)
    local title = note:match("^%*%*(.-)%*%*")
    if title then
        title = title:gsub(":%s*$", "")
    else
        title = note:match("^(.-[%.!?])%s") or note
        title = title:gsub("%*%*", ""):gsub("`", "")
        if #title > 90 then title = title:sub(1, 87):gsub("%s+%S*$", "") .. "..." end
    end
    return title
end
ns.PatchTLDR = tldr   -- (tools/uitest.lua)

function ns.ShowAboutPage(pane)
    local w = math.max(300, (pane:GetWidth() or 640) - 60)
    pane.child:SetWidth(w)
    pane.text:SetWidth(w)
    local G, W, D = "|cffffd100", "|cffffffff", "|cffaaaaaa"
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version = meta and meta(ns.name, "Version") or "?"
    if version == "@project-version@" then version = "development build" end
    local out = {}
    local function add(s) table.insert(out, s) end
    add(G .. "Forever Best In Slot|r  " .. D .. "version " .. version .. "|r")
    add("Pre-raid best-in-slot gear, enchants, consumables and a raid check for every spec in WoW Forever.")
    add(" ")
    add(D .. "Made by|r " .. W .. "Zaibrax|r")
    add(D .. "Download and comments:|r CurseForge, \"WoW Forever BiS Gear\"")
    add(D .. "Report a wrong item:|r leave a comment on the CurseForge page")
    add(D .. "Commands:|r " .. G .. "/bis|r opens this window,  " .. G .. "/bis raid|r the raid check,  "
        .. G .. "/bis spec|r what the game says your spec is,  " .. G .. "/bis holiday|r the holiday theme")
    add(" ")
    add(G .. "Patch notes|r  " .. D .. "(the short version; full notes on CurseForge)|r")
    local shown = 0
    for _, v in ipairs(ns.PatchNotes or {}) do
        shown = shown + 1
        if shown > 12 then
            add(" ")
            add(D .. "Older versions: see the changelog on CurseForge or GitHub.|r")
            break
        end
        add(" ")
        add(G .. v.version .. "|r")
        for _, n in ipairs(v.notes) do add("|cffaaaaaa-|r  " .. W .. tldr(n) .. "|r") end
    end
    pane.text:SetText(table.concat(out, "\n"))
    pane.child:SetHeight((pane.text:GetStringHeight() or 400) + 20)
    if pane.scroll and pane.scroll.SetVerticalScroll then pane.scroll:SetVerticalScroll(0) end
end

-- The pet you have out: level, loyalty, happiness, training points and its
-- skills' ranks against the highest ranks. Each part is read only if this
-- client has the call for it. Returns { lines = {...}, issues = n } or nil.
local function petSkills()
    local skills = {}
    local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) or BOOKTYPE_PET or "pet"
    local okN, n = pcall(function()
        if HasPetSpells then return (HasPetSpells()) end
        if C_SpellBook and C_SpellBook.HasPetSpells then return (C_SpellBook.HasPetSpells()) end
    end)
    n = okN and tonumber(n) or 0
    for i = 1, n do
        local ok, name, sub = pcall(function()
            if C_SpellBook and C_SpellBook.GetSpellBookItemName then return C_SpellBook.GetSpellBookItemName(i, bank) end
            return GetSpellBookItemName(i, bank)
        end)
        if ok and name then
            local rank = tonumber(tostring(sub or ""):match("(%d+)"))
            if not skills[name] or (rank and rank > (skills[name] or 0)) then skills[name] = rank or 0 end
        end
    end
    return skills
end

function ns.PetTrainingCheck()
    if not (UnitExists and UnitExists("pet")) then return nil end
    local out, issues = {}, 0
    local function good(t) table.insert(out, "|cff33ff33" .. t .. "|r") end
    local function fix(t) table.insert(out, "|cffffaa33" .. t .. "|r"); issues = issues + 1 end
    local pl, me = UnitLevel("pet"), UnitLevel("player")
    if pl and me and pl > 0 then
        if pl < me then fix("Level " .. pl .. ": level it to " .. me .. " to keep up with raid bosses.") else good("Level " .. pl .. ".") end
    end
    if GetPetLoyalty then
        local ok, loyalty = pcall(GetPetLoyalty)
        if ok and type(loyalty) == "string" and loyalty ~= "" then
            if loyalty:find("Best Friend") then good("Loyalty: Best Friend (full training points).")
            else fix("Loyalty: " .. loyalty .. ". Keep feeding it and fighting with it; Best Friend gives 300 training points at level 60.") end
        end
    end
    if GetPetHappiness then
        local ok, happy = pcall(GetPetHappiness)
        if ok and happy then
            if happy >= 3 then good("Happy.") else fix((happy == 2 and "Content" or "Unhappy") .. ": feed it before the pull (you can't feed in combat).") end
        end
    end
    if GetPetTrainingPoints then
        local ok, total, spent = pcall(GetPetTrainingPoints)
        if ok and total then
            local free = (total or 0) - (spent or 0)
            if free > 0 then fix(free .. " training points unspent: Great Stamina first, then its family skill.")
            elseif free < 0 then fix("Training points " .. free .. ": its loyalty will catch up as it levels.")
            else good("All training points spent.") end
        end
    end
    local skills = petSkills()
    local any = false
    local names = {}
    for name in pairs(skills) do table.insert(names, name) end
    table.sort(names)
    for _, name in ipairs(names) do
        local best = ns.PetBestRank and ns.PetBestRank[name]
        local rank = skills[name]
        if best and rank and rank > 0 then
            any = true
            if rank >= best.rank then
                good(name .. " rank " .. rank .. ": the best rank.")
            elseif best.trainer then
                fix(name .. " rank " .. rank .. ": buy rank " .. best.rank .. " from a Pet Trainer.")
            else
                local f = best.from and best.from[1]
                local where = f and (f[1] .. " (level " .. f[2] .. ", " .. f[3] .. (f[4] and (" " .. f[4]) or "") .. ")") or "a level 50+ beast"
                local more = best.from and #best.from > 1 and ("; also " .. best.from[2][1] .. " in " .. best.from[2][3]) or ""
                fix(name .. " rank " .. rank .. ": rank " .. best.rank .. " from " .. where .. more .. ".")
            end
        end
    end
    if next(skills) then
        local family = UnitCreatureFamily and UnitCreatureFamily("pet")
        local function teach(skill)
            local best = ns.PetBestRank[skill]
            local f = best and best.from and best.from[1]
            return f and (" Rank " .. best.rank .. " from " .. f[1] .. " (" .. f[3] .. ").") or ""
        end
        if family and ns.BiteFamilies and ns.BiteFamilies[family] and not skills["Bite"] then
            fix("No Bite: a " .. family .. " can learn it, and it's most of a raid pet's damage." .. teach("Bite"))
        end
        if family and ns.ClawFamilies and ns.ClawFamilies[family] and not skills["Claw"] then
            fix("No Claw: a " .. family .. " can learn it." .. teach("Claw"))
        end
        if not skills["Great Stamina"] then fix("No Great Stamina: buy it from a Pet Trainer; rank 10 (185 points) is the best use of a raid pet's points.") end
        local gs, na = skills["Great Stamina"] or 0, skills["Natural Armor"] or 0
        if na > 6 and gs < 10 then
            fix("Natural Armor rank " .. na .. " but Great Stamina only " .. gs .. ": for raids, unlearn some armor at a Pet Trainer and put the points into Great Stamina.")
        end
    end
    if not any and not next(skills) then table.insert(out, "|cffaaaaaaCan't read your pet's skills here; open its spellbook to check ranks.|r") end
    return { lines = out, issues = issues }
end

-- Pet tab: the raid pet for a hunter spec, and whether yours matches
function ns.PetVerdict(spec)
    local rec = ns.HunterPets and ns.HunterPets[spec]
    if not rec then return nil end
    local family = UnitCreatureFamily and UnitCreatureFamily("pet")
    local status
    if not family then status = rec.lone and "lone" or "none"
    else
        status = "other"
        for i, f in ipairs(rec.picks) do
            if f == family then status = (i == 1) and "best" or "good" end
        end
    end
    return rec, family, status
end

function ns.ShowPetPage(pane, spec)
    local w = math.max(300, (pane:GetWidth() or 640) - 60)
    pane.child:SetWidth(w)
    pane.text:SetWidth(w)
    local G, W, D, OK, BAD = "|cffffd100", "|cffffffff", "|cffaaaaaa", "|cff33ff33", "|cffffaa33"
    local out = {}
    local function add(s) table.insert(out, s) end
    local rec, family, status = ns.PetVerdict(spec)
    if not rec then pane.text:SetText("") return end
    add(G .. "Raid pet for " .. (spec or "") .. " Hunter|r")
    add(W .. "Bring: " .. table.concat(rec.picks, " or ") .. "|r" .. (rec.lone and (D .. "   (or no pet, with the Lone Wolf talent)|r") or ""))
    add(rec.why)
    if rec.also then add(D .. "Also: " .. rec.also .. "|r") end
    add(" ")
    -- your pet right now
    local name = UnitName and UnitName("pet")
    if status == "best" then add(OK .. "Your pet: " .. (name or family) .. " (" .. family .. ") - the top pick.|r")
    elseif status == "good" then add(OK .. "Your pet: " .. (name or family) .. " (" .. family .. ") - a good pick.|r")
    elseif status == "other" then add(BAD .. "Your pet: " .. (name or family) .. " (" .. family .. "). For raids, a " .. rec.picks[1] .. " is better.|r")
    elseif status == "lone" then add(D .. "No pet out. Fine with Lone Wolf; otherwise call your " .. rec.picks[1] .. ".|r")
    else add(D .. "No pet out. Call your pet to check it here.|r") end
    -- the pet you have out: training and upkeep
    local check = ns.PetTrainingCheck()
    if check then
        add(" ")
        add(G .. "Your pet's training|r" .. (check.issues > 0 and ("  |cffffaa33" .. check.issues .. " to improve|r") or "  |cff33ff33ready|r"))
        for _, l in ipairs(check.lines) do add("-  " .. l) end
    end
    add(" ")
    add(G .. "Raid pet training|r")
    for _, t in ipairs(ns.PetRaidTraining or {}) do add("-  " .. t) end
    add(" ")
    add(G .. "Where to learn the best ranks|r  " .. D .. "(tame the beast, let it teach you, then Beast Training)|r")
    for _, skill in ipairs({ "Bite", "Claw", "Dash", "Dive", "Furious Howl", "Charge", "Lightning Breath", "Scorpid Poison" }) do
        local best = ns.PetBestRank and ns.PetBestRank[skill]
        if best and best.from then
            local spots = {}
            for _, f in ipairs(best.from) do
                table.insert(spots, f[1] .. " " .. D .. "(" .. f[2] .. ", " .. f[3] .. (f[4] and (" " .. f[4]) or "") .. ")|r")
            end
            add(W .. skill .. " " .. best.rank .. "|r:  " .. table.concat(spots, ";  "))
        end
    end
    add(D .. "Growl 7, Great Stamina 10, Natural Armor 10 and resistances 4: bought from a Pet Trainer. These are the best ranks found in Forever so far; level 56+ beasts may teach higher ones.|r")
    add(" ")
    add(G .. "What each family brings|r")
    local shown = {}
    local order = {}
    for _, f in ipairs(rec.picks) do table.insert(order, f) end
    for _, f in ipairs({ "Cat", "Wolf", "Raptor", "Bear", "Tallstrider", "Spider", "Carrion Bird", "Crocolisk", "Wind Serpent" }) do table.insert(order, f) end
    for _, f in ipairs(order) do
        local info = ns.PetFamilies[f]
        if info and not shown[f] then
            shown[f] = true
            add(W .. f .. "|r  " .. D .. "(" .. info[1] .. " tier)|r  " .. G .. info[2] .. "|r: " .. info[3])
        end
    end
    if ns.PetTames and #ns.PetTames > 0 then
        add(" ")
        add(G .. "Worth taming|r")
        for _, t in ipairs(ns.PetTames) do
            add(W .. t.name .. "|r  " .. D .. "(" .. t.family .. ", level " .. t.level .. ", " .. t.zone .. ")|r  " .. t.note)
        end
    end
    add(" ")
    add(D .. "Guides don't agree on every pick yet; there's been little level 60 raid testing. Sources: playhub.com, warcrafttavern.com, exitlag.com.|r")
    pane.text:SetText(table.concat(out, "\n"))
    pane.child:SetHeight((pane.text:GetStringHeight() or 400) + 20)
end

function ns.ToggleBrowser()
    if not frame then createFrame() end
    if frame:IsShown() then frame:Hide() else frame:Show(); frame:Raise() end
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
end

-- Compact: right of the raid check panel if it's open, else right of the
-- character window
local function anchorCompact()
    local raid = _G.ForeverBiSRaidFrame
    local anchor = (ns.RaidPanelShown and ns.RaidPanelShown() and raid) or CharacterFrame
    local gap = 4
    if anchor == CharacterFrame and ns.CharacterOverhang then gap = gap + ns.CharacterOverhang() end   -- past its side buttons
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", gap, 0)
end

-- Compact while both windows are open (and the setting is on)
function ns.UpdateCompact()
    if not frame then return end
    local charOpen = CharacterFrame and CharacterFrame:IsShown()
    setCompact((frame:IsShown() and charOpen and ns.db.compactWithCharacter) and true or false)
    if frame.compact then anchorCompact() end
end
-- (the character window's show / hide hooks are in Raid.lua: they place the
-- raid panel first, then call ns.UpdateCompact)
