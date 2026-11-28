local _, ns = ...

--[[
    Boss popup: clicking a boss in "Where to get it" shows a small window with
    the boss's 3D model (so you recognise it in the dungeon) and its dungeon.

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

local function createWindow()
    win = CreateFrame("Frame", "ForeverBiSBossFrame", UIParent, "BasicFrameTemplateWithInset")
    win:SetSize(320, 360)
    win:SetPoint("CENTER", 0, 40)
    win:SetFrameStrata("MEDIUM")
    win:SetToplevel(true)
    win:EnableMouse(true)
    win:SetMovable(true)
    win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    tinsert(UISpecialFrames, "ForeverBiSBossFrame")
    ns.RegisterGamepadFrame(win)
    -- close with a plain Hide(): the template's close button goes through the
    -- protected panel manager, which can be blocked in combat
    if type(win.CloseButton) == "table" then
        win.CloseButton:SetScript("OnClick", function() win:Hide() end)
    end
    -- right-click anywhere closes it too
    win:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then self:Hide() end end)

    win.title = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    win.title:SetPoint("TOP", 0, -5)

    win.instance = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.instance:SetPoint("TOP", 0, -32)

    -- model (drag to turn)
    local model = CreateFrame("PlayerModel", nil, win)
    model:SetPoint("TOPLEFT", 12, -52)
    model:SetPoint("BOTTOMRIGHT", -12, 12)
    model:EnableMouse(true)
    model.facing = 0
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self.dragX = GetCursorPosition() end
    end)
    model:SetScript("OnMouseUp", function(self, button)
        self.dragX = nil
        if button == "RightButton" then win:Hide() end
    end)
    model:SetScript("OnHide", function(self) self.dragX = nil end)
    model:SetScript("OnUpdate", function(self)
        if self.dragX and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            self.dragX = nil   -- released outside the model
        end
        if self.dragX then
            local x = GetCursorPosition()
            self.facing = self.facing + (x - self.dragX) * 0.02
            self.dragX = x
            self:SetFacing(self.facing)
        end
    end)
    win.model = model
    -- forget the model on close so the next boss never starts from the old one
    win:HookScript("OnHide", function() model:ClearModel(); win.boss = nil end)
    local bg = model:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.35)

end

function ns.ShowBoss(boss)
    if not boss then return end
    if not win then createWindow() end
    -- clicking the boss that's already shown closes the window
    if win:IsShown() and win.boss and win.boss.name == boss.name then
        win:Hide()
        return
    end
    win.boss = boss
    win.title:SetText(boss.name)
    win.instance:SetText(boss.instance or "")

    -- A model set while the window is hidden is ignored and the last one
    -- comes back when it shows, so show first, then set the model, and set it
    -- again a moment later (creature data may still be loading).
    win:Show()
    win:Raise()
    local function apply()
        if not win:IsShown() or win.boss ~= boss then return end
        win.model:ClearModel()
        if boss.display then
            win.model:SetDisplayInfo(boss.display)
        elseif boss.npc then
            win.model:SetCreature(boss.npc)
        end
        win.model.facing = 0
        win.model:SetFacing(0)
    end
    apply()
    C_Timer.After(0.1, apply)
    C_Timer.After(0.6, apply)
end

