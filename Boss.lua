local _, ns = ...

--[[
    Boss popup: clicking a boss in "Where to get it" shows a small window with
    the boss's 3D model (so you recognise it in the dungeon), its dungeon and
    the items on your lists that drop from it.

    Boss names come from the source text ("Stratholme: Baron Rivendare",
    "Drop: Gyth (Upper Blackrock Spire)") and are matched against the boss
    list in Data/Bosses.lua (NPC and model IDs from kovarel.com / wowhead.com).
    WoW Forever has no Dungeon Journal, so the model is shown directly.
]]

local bossIndex          -- lower-case boss name -> entry from ns.Bosses
local SKULL = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14:14|t "

local function buildIndex()
    bossIndex = {}
    for name, b in pairs(ns.Bosses or {}) do
        bossIndex[name:lower()] = { name = name, npc = b[1], display = b[2], instance = b[3] }
    end
end

-- Boss named in a source string, if it is in the boss list
function ns.FindBoss(source)
    if type(source) ~= "string" or source == "" then return nil end
    if source:find("[Qq]uest") or source:find("^Vendor") then return nil end
    if not bossIndex then buildIndex() end
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
    win:SetSize(320, 440)
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
    scroll:SetPoint("BOTTOMRIGHT", -32, 14)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(260, 200)
    scroll:SetScrollChild(child)
    win.text = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    win.text:SetPoint("TOPLEFT")
    win.text:SetWidth(258)
    win.text:SetJustifyH("LEFT")
    win.text:SetSpacing(3)
    win.child = child

end

function ns.ShowBoss(boss)
    if not boss then return end
    if not win then createWindow() end
    win.boss = boss
    win.title:SetText(boss.name)
    win.instance:SetText(boss.instance or "")

    -- model: by model (display) ID, or by NPC ID
    win.model:ClearModel()
    if boss.display then
        win.model:SetDisplayInfo(boss.display)
    elseif boss.npc then
        win.model:SetCreature(boss.npc)
    end
    win.model.facing = 0
    win.model:SetFacing(0)

    local parts = {}
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

