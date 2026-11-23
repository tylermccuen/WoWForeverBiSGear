local _, ns = ...

local category
local panel

local function checkbox(parent, label, tip, get, set, anchor, yOff)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff or -6)
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.label:SetText(label)
    cb:SetScript("OnShow", function(self) self:SetChecked(get()) end)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    if tip then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(label)
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return cb
end

local function presetLabel(key)
    for _, p in ipairs(ns.LinkPresets) do if p.key == key then return p.label end end
    return key
end

local function buildPanel()
    panel = CreateFrame("Frame")
    panel.name = ns.title

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ns.title)

    local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    local latest = ns.Phases[ns.LatestPhase()]
    sub:SetText("Current: " .. latest.label .. (latest.subtitle and (" - " .. latest.subtitle) or "")
        .. "  |  Data: " .. (latest.source or "?") .. ", checked " .. (latest.checked or "?"))

    local c1 = checkbox(panel, "Show BiS info on item tooltips", nil,
        function() return ns.db.showTooltip end,
        function(v) ns.db.showTooltip = v end, sub, -14)
    local c2 = checkbox(panel, "Only show my own class on tooltips", nil,
        function() return ns.db.tooltipOwnClass end,
        function(v) ns.db.tooltipOwnClass = v end, c1)
    local c3 = checkbox(panel, "Show tooltip info during combat",
        "Off by default. In combat some item data is hidden from addons, so lines may be missing anyway.",
        function() return ns.db.tooltipInCombat end,
        function(v) ns.db.tooltipInCombat = v end, c2)
    local c3b = checkbox(panel, "Tooltips: include older phases",
        "Off: tooltips only list specs the item is BiS for in the current phase. On: also list older phases, tagged P1, P2...",
        function() return ns.db.tooltipPhases == "all" end,
        function(v) ns.db.tooltipPhases = v and "all" or "current" end, c3)
    local c3c = checkbox(panel, "Show \"BiS for you\" verdict for my spec",
        "Adds a green line when an item is on your own spec's BiS list. Your spec is the one picked in the browser for your class, otherwise your active specialization.",
        function() return ns.db.showVerdict end,
        function(v) ns.db.showVerdict = v end, c3b)
    local c3d = checkbox(panel, "Also show \"Not BiS\" and my BiS item on other gear",
        "On gear that isn't on your list, shows what your BiS item for that slot is (uncommon quality and above).",
        function() return ns.db.showNotBis end,
        function(v) ns.db.showNotBis = v end, c3c)
    local c4 = checkbox(panel, "Show minimap button", nil,
        function() return not ns.db.minimap.hide end,
        function(v) ns.db.minimap.hide = not v; ns.UpdateMinimap() end, c3d)
    local c5 = checkbox(panel, "Shrink the browser next to the character window",
        "When you open your character window, the browser gets narrower and moves beside it so you can compare your gear. It goes back to normal when you close the character window.",
        function() return ns.db.compactWithCharacter end,
        function(v) ns.db.compactWithCharacter = v; if ns.UpdateCompact then ns.UpdateCompact() end end, c4)
    local c6 = checkbox(panel, "Announce new BiS items in guild chat",
        "When you loot or receive an item that's on your spec's BiS list for the first time, posts it with the item link in guild chat.",
        function() return ns.db.announceGuild end,
        function(v) ns.db.announceGuild = v end, c5)

    -- Link site
    local linkHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    linkHeader:SetPoint("TOPLEFT", c6, "BOTTOMLEFT", 0, -18)
    linkHeader:SetText("Copy-paste link")

    local siteButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    siteButton:SetSize(200, 24)
    siteButton:SetPoint("TOPLEFT", linkHeader, "BOTTOMLEFT", 0, -8)

    local tmplLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tmplLabel:SetPoint("TOPLEFT", siteButton, "BOTTOMLEFT", 0, -12)
    tmplLabel:SetText("Custom template ({id} = item ID, {name} = item name):")

    local tmpl = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    tmpl:SetSize(460, 22)
    tmpl:SetPoint("TOPLEFT", tmplLabel, "BOTTOMLEFT", 6, -4)
    tmpl:SetAutoFocus(false)

    local preview = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    preview:SetPoint("TOPLEFT", tmpl, "BOTTOMLEFT", -6, -8)
    preview:SetWidth(520)
    preview:SetJustifyH("LEFT")

    local function refresh()
        siteButton:SetText(presetLabel(ns.db.linkPreset))
        tmpl:SetText(ns.db.customTemplate or "")
        if ns.db.linkPreset == "custom" then tmpl:Enable() else tmpl:Disable() end
        preview:SetText("Example: " .. ns.GetItemURL(13392, "The Postmaster's Seal"))
    end

    tmpl:SetScript("OnEnterPressed", function(self)
        ns.db.customTemplate = self:GetText()
        self:ClearFocus()
        refresh()
    end)
    tmpl:SetScript("OnEditFocusLost", function(self)
        ns.db.customTemplate = self:GetText()
        refresh()
    end)
    tmpl:SetScript("OnEscapePressed", function(self) self:ClearFocus(); refresh() end)

    siteButton:SetScript("OnClick", function(self)
        MenuUtil.CreateContextMenu(self, function(_, root)
            for _, p in ipairs(ns.LinkPresets) do
                root:CreateRadio(p.label,
                    function() return ns.db.linkPreset == p.key end,
                    function() ns.db.linkPreset = p.key; refresh() end)
            end
        end)
    end)

    -- Window size
    local scaleLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -20)
    scaleLabel:SetText("Browser window size")
    local prev = scaleLabel
    for i, s in ipairs({ { "Small", 0.9 }, { "Normal", 1 }, { "Large", 1.15 } }) do
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(80, 22)
        if i == 1 then b:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -8)
        else b:SetPoint("LEFT", prev, "RIGHT", 6, 0) end
        b:SetText(s[1])
        b:SetScript("OnClick", function()
            ns.db.windowScale = s[2]
            ns.SetBrowserScale(s[2])
        end)
        prev = b
    end

    panel:SetScript("OnShow", refresh)
    return panel
end

function ns.InitOptions()
    local p = buildPanel()
    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(p, ns.title)
        Settings.RegisterAddOnCategory(category)
    end
end

function ns.OpenOptions()
    if category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    end
end
