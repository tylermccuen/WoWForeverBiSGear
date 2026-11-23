local _, ns = ...

--[[
    Raid check: is the character's gear ready for raiding?

    Hard targets (pass / fail), from WoW Forever guides:
      * Hit vs raid bosses: 8% melee / ranged (one weapon, special attacks),
        17% spells (conquestcapped.com hit cap guide, Oct 2026 beta).
        Healers are skipped because heals can't miss.
      * Defense 440 for tanks (uncrittable vs raid bosses; warcrafttavern.com).
      * Every slot filled and every slot on the spec's enchant list enchanted.

    Soft targets (no published numbers): crit, healing, spell damage, attack
    power, stamina... are compared against the stats on the spec's pre-raid
    BiS list, so "90%" means your gear has 90% of what the BiS set gives.
]]

ns.RaidTargets = {
    hitMelee = 8,   -- melee, ranged, tanks (threat)
    hitSpell = 17,  -- casters
    hitDualWieldWhite = 27, -- shown as info only
    defense = 440,
}

-- role per spec
local ROLE = {
    ["WARRIOR:Arms"] = "melee", ["WARRIOR:Fury"] = "melee", ["WARRIOR:Protection"] = "tank",
    ["PALADIN:Holy"] = "healer", ["PALADIN:Protection"] = "tank", ["PALADIN:Retribution"] = "melee",
    ["HUNTER:Beast Mastery"] = "ranged", ["HUNTER:Marksmanship"] = "ranged", ["HUNTER:Survival"] = "ranged",
    ["ROGUE:Assassination"] = "melee", ["ROGUE:Combat"] = "melee", ["ROGUE:Subtlety"] = "melee",
    ["PRIEST:Discipline"] = "healer", ["PRIEST:Holy"] = "healer", ["PRIEST:Shadow"] = "caster",
    ["SHAMAN:Elemental"] = "caster", ["SHAMAN:Enhancement"] = "melee", ["SHAMAN:Restoration"] = "healer",
    ["MAGE:Arcane"] = "caster", ["MAGE:Fire"] = "caster", ["MAGE:Frost"] = "caster",
    ["WARLOCK:Affliction"] = "caster", ["WARLOCK:Demonology"] = "caster", ["WARLOCK:Destruction"] = "caster",
    ["DRUID:Balance"] = "caster", ["DRUID:Feral"] = "melee", ["DRUID:Feral Tank"] = "tank", ["DRUID:Restoration"] = "healer",
}
function ns.SpecRole(class, spec) return ROLE[(class or "") .. ":" .. (spec or "")] end

-- item stat keys (GetItemStats) grouped by what they mean; matched by substring
local STAT_GROUPS = {
    { key = "stam",  label = "Stamina",          match = { "STAMINA" } },
    { key = "str",   label = "Strength",         match = { "STRENGTH" } },
    { key = "agi",   label = "Agility",          match = { "AGILITY" } },
    { key = "int",   label = "Intellect",        match = { "INTELLECT" } },
    { key = "spi",   label = "Spirit",           match = { "SPIRIT" } },
    { key = "ap",    label = "Attack power",     match = { "ATTACK_POWER" } },
    { key = "heal",  label = "Healing",          match = { "HEALING" } },
    { key = "spell", label = "Spell damage",     match = { "SPELL_DAMAGE", "SPELL_POWER" } },
    { key = "hit",   label = "Hit",              match = { "HIT" } },
    { key = "crit",  label = "Crit",             match = { "CRIT" } },
    { key = "mp5",   label = "Mana per 5",       match = { "MANA_REGENERATION", "POWER_REGEN0" } },
    { key = "def",   label = "Defense",          match = { "DEFENSE" } },
}
local ROLE_STATS = {
    tank   = { "stam", "def", "str", "agi", "hit" },
    healer = { "heal", "int", "mp5", "spi", "crit" },
    caster = { "spell", "hit", "crit", "int" },
    melee  = { "str", "agi", "ap", "hit", "crit" },
    ranged = { "agi", "ap", "hit", "crit", "int" },
}

local INV = { Head = 1, Neck = 2, Shoulder = 3, Back = 15, Chest = 5, Wrist = 9, Hands = 10, Waist = 6,
              Legs = 7, Feet = 8, ["Main Hand"] = 16, ["Two Hand"] = 16, ["Off Hand"] = 17, Ranged = 18 }
local SLOT_NAMES = { [1] = "Head", [2] = "Neck", [3] = "Shoulder", [5] = "Chest", [6] = "Waist", [7] = "Legs",
                     [8] = "Feet", [9] = "Wrist", [10] = "Hands", [11] = "Finger 1", [12] = "Finger 2",
                     [13] = "Trinket 1", [14] = "Trinket 2", [15] = "Back", [16] = "Main Hand", [17] = "Off Hand",
                     [18] = "Ranged" }

local function num(f, ...)
    if type(f) ~= "function" then return nil end
    local ok, a, b, c = pcall(f, ...)
    if ok and type(a) == "number" then return a, b, c end
end

local function maxOf(...)
    local best
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) == "number" and (not best or v > best) then best = v end
    end
    return best
end

-- Live character stats (each call guarded: the Forever API may differ)
function ns.PlayerRaidStats()
    local s = {}
    local crBonus = GetCombatRatingBonus
    s.hit = maxOf(num(GetHitModifier), num(GetSpellHitModifier),
                  CR_HIT_MELEE and num(crBonus, CR_HIT_MELEE), CR_HIT_SPELL and num(crBonus, CR_HIT_SPELL))
    local spellCrit, spellDmg
    for school = 2, 7 do
        spellCrit = maxOf(spellCrit, num(GetSpellCritChance, school))
        spellDmg = maxOf(spellDmg, num(GetSpellBonusDamage, school))
    end
    s.crit = maxOf(num(GetCritChance), num(GetRangedCritChance), spellCrit)
    s.spell = spellDmg
    s.heal = num(GetSpellBonusHealing)
    local base, pos, neg = num(UnitAttackPower, "player")
    if base then s.ap = base + (pos or 0) + (neg or 0) end
    local rb, rpos, rneg = num(UnitRangedAttackPower, "player")
    if rb then s.rap = rb + (rpos or 0) + (rneg or 0) end
    local defBase, defMod = num(UnitDefense, "player")
    if defBase then s.defense = defBase + (defMod or 0) end
    s.health = num(UnitHealthMax, "player")
    s.mana = num(UnitPowerMax, "player", 0)
    local armorBase, armorEff = num(UnitArmor, "player")
    s.armor = armorEff or armorBase
    return s
end

local function itemStats(link)
    local f = (C_Item and C_Item.GetItemStats) or GetItemStats
    if not f or not link then return nil end
    local ok, t = pcall(f, link)
    if ok and type(t) == "table" then return t end
end

local function addStats(into, stats)
    if not stats then return end
    for k, v in pairs(stats) do
        if type(v) == "number" then
            local upper = tostring(k):upper()
            for _, g in ipairs(STAT_GROUPS) do
                for _, m in ipairs(g.match) do
                    if upper:find(m, 1, true) then
                        into[g.key] = (into[g.key] or 0) + v
                        break
                    end
                end
            end
        end
    end
end

local function enchantOf(link)
    if not link then return nil end
    local e = link:match("item:%-?%d+:(%-?%d*)")
    return tonumber(e) or 0
end

local function isWeaponOffhand(link)
    if not link then return false end
    local _, _, _, loc = C_Item.GetItemInfoInstant(link)
    return loc == "INVTYPE_WEAPON" or loc == "INVTYPE_WEAPONOFFHAND"
end

local function twoHanded(link)
    if not link then return false end
    local _, _, _, loc = C_Item.GetItemInfoInstant(link)
    return loc == "INVTYPE_2HWEAPON"
end

--[[
    Run the check. cb(report) is called once the BiS items' data is loaded.
    report = { spec, class, role, lines = { {status = "pass"|"fail"|"info"|"head", text = ...}, ... },
               passed, failed }
]]
function ns.RunRaidCheck(cb)
    local class, spec = ns.GetMySpec()
    local guide = spec and ns.GetGuide(class, spec, ns.LatestPhase())
    local role = ns.SpecRole(class, spec)
    local report = { class = class, spec = spec, role = role, lines = {}, passed = 0, failed = 0 }
    local function line(status, text)
        table.insert(report.lines, { status = status, text = text })
        if status == "pass" then report.passed = report.passed + 1
        elseif status == "fail" then report.failed = report.failed + 1 end
    end
    if not guide or not role then
        line("info", "No BiS list for your spec yet.")
        cb(report)
        return
    end

    local T = ns.RaidTargets
    local st = ns.PlayerRaidStats()

    -- equipped links
    local equipped = {}
    for inv = 0, 19 do
        local ok, link = pcall(GetInventoryItemLink, "player", inv)
        if ok and link then equipped[inv] = link end
    end

    line("head", "Hard targets")
    -- Hit
    if role ~= "healer" then
        local need = role == "caster" and T.hitSpell or T.hitMelee
        if st.hit then
            local txt = string.format("Hit chance %.1f%% (raid bosses need %d%%)", st.hit, need)
            line(st.hit + 0.001 >= need and "pass" or "fail", txt)
        else
            line("info", string.format("Hit: couldn't read it. Raid bosses need %d%%: check the Hit Chance tooltip in your character panel.", need))
        end
        if role == "melee" and isWeaponOffhand(equipped[17]) then
            line("info", string.format("Dual wielding: special attacks need %d%%, auto attacks about %d%% to never miss.", T.hitMelee, T.hitDualWieldWhite))
        end
    end
    -- Defense
    if role == "tank" then
        if st.defense then
            line(st.defense >= T.defense and "pass" or "fail",
                string.format("Defense %d (uncrittable by raid bosses at %d)", st.defense, T.defense))
        else
            line("info", "Defense: couldn't read it. Tanks need 440 to be uncrittable by raid bosses.")
        end
    end
    -- Empty slots
    local empty = {}
    for inv = 1, 18 do
        local name = SLOT_NAMES[inv]
        if name and not equipped[inv] then
            local skip = (inv == 17 and twoHanded(equipped[16]))
                or (inv == 18 and class ~= "HUNTER" and class ~= "WARRIOR" and class ~= "ROGUE")
            if not skip then table.insert(empty, name) end
        end
    end
    line(#empty == 0 and "pass" or "fail", #empty == 0 and "No empty gear slots" or ("Empty slots: " .. table.concat(empty, ", ")))
    -- Enchants
    if guide.enchants then
        local missing, seen = {}, {}
        for _, row in ipairs(guide.enchants) do
            local inv = INV[row[1]]
            if inv and not seen[inv] then
                seen[inv] = true
                local link = equipped[inv]
                if link and enchantOf(link) == 0 then table.insert(missing, row[1]) end
            end
        end
        line(#missing == 0 and "pass" or "fail",
            #missing == 0 and "Every slot on your enchant list is enchanted" or ("Not enchanted: " .. table.concat(missing, ", ")))
    end

    -- BiS / Realistic pieces equipped
    line("head", "Your gear vs the lists")
    local function countEquipped(rows)
        local have, total = 0, 0
        for _, r in ipairs(rows) do
            if not r.isAlt and r.slot ~= "Ammo" then
                total = total + 1
                if ns.Owned[r.id] == "equipped" then have = have + 1 end
            end
        end
        return have, total
    end
    local h, t = countEquipped(ns.GetGuideRows(guide, false, "bis"))
    line("info", string.format("BiS items equipped: %d / %d", h, t))
    if guide.realistic then
        local rh, rt = countEquipped(ns.GetGuideRows(guide, false, "realistic"))
        line("info", string.format("Realistic items equipped: %d / %d", rh, rt))
    end

    -- live stats
    local shown = {}
    if st.crit then table.insert(shown, string.format("Crit %.1f%%", st.crit)) end
    if role == "healer" and st.heal then table.insert(shown, "Healing " .. st.heal) end
    if role == "caster" and st.spell then table.insert(shown, "Spell damage " .. st.spell) end
    if (role == "melee" or role == "tank") and st.ap then table.insert(shown, "Attack power " .. st.ap) end
    if role == "ranged" and st.rap then table.insert(shown, "Ranged attack power " .. st.rap) end
    if st.health then table.insert(shown, "Health " .. st.health) end
    if (role == "healer" or role == "caster") and st.mana and st.mana > 0 then table.insert(shown, "Mana " .. st.mana) end
    if role == "tank" and st.armor then table.insert(shown, "Armor " .. st.armor) end
    if #shown > 0 then line("info", table.concat(shown, "  |  ")) end

    -- Gear stats vs the BiS set (async: BiS item data may need loading)
    local bisIds = {}
    for _, r in ipairs(ns.GetGuideRows(guide, false, "bis")) do
        if not r.isAlt and r.slot ~= "Ammo" and r.slot ~= "Quiver" then table.insert(bisIds, r.id) end
    end
    local mine, bis = {}, {}
    for inv = 1, 18 do addStats(mine, itemStats(equipped[inv])) end

    -- Draw the hard checks right away; the stat comparison follows once the
    -- BiS items' data has loaded (or after 3 seconds with what has loaded).
    local loadingLine = { status = "info", text = "Loading item stats..." }
    table.insert(report.lines, loadingLine)
    cb(report)
    table.remove(report.lines)

    local pending = #bisIds
    local finished = false
    local function finish()
        if finished then return end
        finished = true
        local wanted = ROLE_STATS[role] or {}
        local any = false
        for _, key in ipairs(wanted) do
            local b = bis[key]
            if b and b > 0 then
                if not any then line("head", "Gear stats vs pre-raid BiS"); any = true end
                local m = mine[key] or 0
                local pct = math.floor(m / b * 100 + 0.5)
                local label
                for _, g in ipairs(STAT_GROUPS) do if g.key == key then label = g.label end end
                line(pct >= 90 and "pass" or "info", string.format("%s: %d of %d (%d%%)", label, m, b, pct))
            end
        end
        if not any then
            line("info", "Couldn't read item stats to compare with the BiS set.")
        end
        cb(report)
    end
    if pending == 0 then finish() return end
    if C_Timer and C_Timer.After then C_Timer.After(3, finish) end
    for _, id in ipairs(bisIds) do
        ns.WithItem(id, function(item)
            if finished then return end
            if item then addStats(bis, itemStats(item:GetItemLink())) end
            pending = pending - 1
            if pending == 0 then finish() end
        end)
    end
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
local ICON = {
    pass = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t ",
    fail = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14|t ",
    info = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:14:14|t ",
}

local panel, body, summary

local function render(report)
    if not panel then return end
    local parts = {}
    for _, l in ipairs(report.lines) do
        if l.status == "head" then
            table.insert(parts, (#parts > 0 and "\n" or "") .. "|cffffd100" .. l.text .. "|r")
        else
            table.insert(parts, (ICON[l.status] or "") .. l.text)
        end
    end
    body:SetText(table.concat(parts, "\n"))
    local who = (report.spec or "?") .. " (" .. (report.role or "?") .. ")"
    if report.failed == 0 then
        summary:SetText("|cff33ff33Raid ready|r  -  " .. who)
    else
        summary:SetText(string.format("|cffff5555%d thing%s to fix|r  -  %s", report.failed, report.failed == 1 and "" or "s", who))
    end
    panel.scrollChild:SetHeight((body:GetStringHeight() or 0) + 20)
end

function ns.RefreshRaidCheck()
    if not (panel and panel:IsShown()) then return end
    -- each run gets a token so a slow earlier run can't overwrite a newer one
    panel.runToken = (panel.runToken or 0) + 1
    local token = panel.runToken
    local ok, err = pcall(ns.RunRaidCheck, function(report)
        if panel.runToken ~= token then return end
        local ok2, err2 = pcall(render, report)
        if not ok2 then
            body:SetText("|cffff5555Raid check error:|r " .. tostring(err2))
        end
    end)
    if not ok then
        summary:SetText("|cffff5555Raid check couldn't run|r")
        body:SetText("Please send this to the addon author:\n\n" .. tostring(err))
    end
end

-- The panel is a companion docked to the right edge of the browser window:
-- it opens and closes with the browser and moves with it.
local function createPanel()
    panel = CreateFrame("Frame", "ForeverBiSRaidFrame", UIParent, "BasicFrameTemplateWithInset")
    panel:SetWidth(380)
    panel:SetFrameStrata("HIGH")
    panel:EnableMouse(true)
    panel:Hide()
    -- the template's close button turns the companion off
    if type(panel.CloseButton) == "table" then
        panel.CloseButton:SetScript("OnClick", function()
            ns.db.raidCompanion = false
            panel:Hide()
        end)
    end

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText("Raid check")

    summary = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summary:SetPoint("TOPLEFT", 16, -36)
    summary:SetPoint("RIGHT", -100, 0)
    summary:SetJustifyH("LEFT")

    local refresh = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    refresh:SetSize(80, 22)
    refresh:SetPoint("TOPRIGHT", -14, -30)
    refresh:SetText("Refresh")
    refresh:SetScript("OnClick", ns.RefreshRaidCheck)

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -62)
    scroll:SetPoint("BOTTOMRIGHT", -32, 34)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(330, 400)
    scroll:SetScrollChild(child)
    panel.scrollChild = child

    body = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", 2, -2)
    body:SetWidth(326)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(4)

    local foot = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    foot:SetPoint("BOTTOMLEFT", 16, 12)
    foot:SetPoint("BOTTOMRIGHT", -16, 12)
    foot:SetJustifyH("LEFT")
    foot:SetText("Hit: 8% melee/ranged, 17% spells (conquestcapped.com). Tanks: 440 defense.")
    foot:SetWordWrap(true)

    panel:SetScript("OnShow", ns.RefreshRaidCheck)
end

-- Dock to the browser and show / hide with it
function ns.UpdateRaidCompanion()
    local browser = _G.ForeverBiSFrame
    if not browser then return end
    if not panel then createPanel() end
    panel:SetScale(browser:GetScale())
    panel:ClearAllPoints()
    -- dock on the right, or on the left when there's no room on the right
    local right, screen = browser:GetRight(), UIParent:GetRight()
    local bs, us = browser:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local scale = (bs and us and us > 0) and bs / us or 1
    local width = panel:GetWidth() or 380
    if right and screen and (right + width) * scale > screen then
        panel:SetPoint("TOPRIGHT", browser, "TOPLEFT", 3, 0)
        panel:SetPoint("BOTTOMRIGHT", browser, "BOTTOMLEFT", 3, 0)
    else
        panel:SetPoint("TOPLEFT", browser, "TOPRIGHT", -3, 0)
        panel:SetPoint("BOTTOMLEFT", browser, "BOTTOMRIGHT", -3, 0)
    end
    if browser:IsShown() and ns.db.raidCompanion ~= false then
        if panel:IsShown() then ns.RefreshRaidCheck() else panel:Show() end
    else
        panel:Hide()
    end
end

function ns.ToggleRaidCheck()
    local browser = _G.ForeverBiSFrame
    if not browser or not browser:IsShown() then
        ns.db.raidCompanion = true
        ns.ToggleBrowser()          -- opening the browser brings the companion with it
        ns.UpdateRaidCompanion()
        return
    end
    ns.db.raidCompanion = (ns.db.raidCompanion == false)
    ns.UpdateRaidCompanion()
end

ns.On("PLAYER_EQUIPMENT_CHANGED", function()
    if panel and panel:IsShown() then
        C_Timer.After(0.6, ns.RefreshRaidCheck)   -- after the owned-items refresh
    end
end)
