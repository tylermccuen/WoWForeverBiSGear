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
-- Hit and crit come from "Equip: +1%" effects, not plain item stats, so they're
-- left out here; the live hit / crit percentages at the top cover them.
local ROLE_STATS = {
    tank   = { "stam", "def", "str", "agi" },
    healer = { "heal", "int", "mp5", "spi" },
    caster = { "spell", "int", "stam" },
    melee  = { "str", "agi", "ap", "stam" },
    ranged = { "agi", "ap", "int", "stam" },
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

-- Sum of "Improves your chance to hit with ranged weapons by x%" on equipped gear
local function enchantOf(link)
    if not link then return nil end
    local e = link:match("item:%-?%d+:(%-?%d*)")
    return tonumber(e) or 0
end

-- What's enchanted on an equipped item. The tooltip's "Enchanted: ..." line
-- is the most reliable source; the enchant ID in the item link is the backup.
-- Returns text (or nil), enchanted (boolean).
local ENCHANT_PREFIX = (ENCHANTED_TOOLTIP_LINE and ENCHANTED_TOOLTIP_LINE:match("^(.-)%%s")) or "Enchanted: "
-- Reading an item's tooltip builds a large table, so results are kept per
-- slot until the item there changes. The link includes the enchant, so a new
-- enchant also counts as a change.
local tipCache = {}   -- [inv] = { link = ..., enchant = text, enchanted = bool, rangedHit = n }

local function tipInfo(inv)
    local ok, link = pcall(GetInventoryItemLink, "player", inv)
    if not ok then link = nil end
    local c = tipCache[inv]
    if c and c.link == link then return c end
    c = { link = link, enchanted = false, rangedHit = 0 }
    tipCache[inv] = c
    if not link then return c end
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local okT, data = pcall(C_TooltipInfo.GetInventoryItem, "player", inv)
        if okT and type(data) == "table" and type(data.lines) == "table" then
            for _, l in ipairs(data.lines) do
                local t = l.leftText
                if type(t) == "string" then
                    if not c.enchant and t:sub(1, #ENCHANT_PREFIX) == ENCHANT_PREFIX then
                        c.enchant, c.enchanted = t:sub(#ENCHANT_PREFIX + 1), true
                    end
                    local pct = t:match("hit with ranged weapons by ([%d%.]+)%%")
                    if pct then c.rangedHit = c.rangedHit + (tonumber(pct) or 0) end
                end
            end
        end
    end
    if not c.enchanted then
        local id = enchantOf(link)
        if id and id ~= 0 then c.enchanted = true end
    end
    return c
end

function ns.RangedOnlyHit()
    local total = 0
    for inv = 1, 19 do total = total + tipInfo(inv).rangedHit end
    return total
end

-- Live character stats (each call guarded: the Forever API may differ)
function ns.PlayerRaidStats()
    local s = {}
    -- Hit = "+x% hit" effects (Get*HitModifier) + hit stat on gear (combat
    -- rating), per attack type, like the character panel's Hit Chance tooltip.
    local function hitFor(modifierFn, rating)
        local mod = num(modifierFn)
        local cr = rating and num(GetCombatRatingBonus, rating)
        if mod == nil and cr == nil then return nil end
        return (mod or 0) + (cr or 0)
    end
    s.hitMelee  = hitFor(GetHitModifier, CR_HIT_MELEE)
    s.hitRanged = hitFor(GetHitModifier, CR_HIT_RANGED)
    -- "+x% hit with ranged weapons" gear (e.g. Sash of the Grand Hunt) isn't in
    -- the modifier the API returns, so add it from the equipped items' tooltips
    local extra = ns.RangedOnlyHit()
    if extra > 0 then s.hitRanged = (s.hitRanged or 0) + extra end
    s.hitSpell  = hitFor(GetSpellHitModifier or GetHitModifier, CR_HIT_SPELL)
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

-- Equipped item's enchant for an inventory slot: text (or nil), enchanted
local INV_OF = INV
function ns.SlotEnchant(slot)
    local inv = INV_OF[slot]
    if not inv then return nil, false end
    local c = tipInfo(inv)
    if not c.link then return nil, false end
    return c.enchant, c.enchanted
end

local function itemNameOf(id)
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
    if not name and GetItemInfo then name = GetItemInfo(id) end
    if not name and ns.WithItem then ns.WithItem(id, function() end) end   -- cache it for next time
    return name or ("item " .. id)
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
    local report = { class = class, spec = spec, role = role, lines = {}, passed = 0, failed = 0,
                     tiles = {}, enchants = {}, bars = {} }
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
        local kind = role == "caster" and "Spell" or role == "ranged" and "Ranged" or "Melee"
        local hit = role == "caster" and st.hitSpell or role == "ranged" and st.hitRanged or st.hitMelee
        if hit then
            local txt = string.format("%s hit %.2f%% (raid bosses need %d%%)", kind, hit, need)
            line(hit + 0.001 >= need and "pass" or "fail", txt)
            table.insert(report.tiles, { label = kind .. " hit", value = string.format("%.1f%%", hit),
                progress = hit / need, ok = hit + 0.001 >= need, note = string.format("Need %d%% for raid bosses", need) })
        else
            line("info", string.format("Hit: couldn't read it. Raid bosses need %d%%: check the Hit Chance tooltip in your character panel.", need))
            table.insert(report.tiles, { label = kind .. " hit", value = "?", note = string.format("Need %d%%: see character panel", need) })
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
            table.insert(report.tiles, { label = "Defense", value = tostring(st.defense), progress = st.defense / T.defense,
                ok = st.defense >= T.defense, note = string.format("Need %d to be uncrittable", T.defense) })
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
    report.emptyTile = { label = "Gear slots", value = #empty == 0 and "All filled" or (#empty .. " empty"), ok = #empty == 0,
        bad = #empty > 0, note = #empty == 0 and "No empty slots" or table.concat(empty, ", ") }
    -- Enchants, one line per slot on the spec's enchant list
    if guide.enchants then
        line("head", "Enchants")
        -- an item is worth enchanting once it is a 1st or 2nd place pick:
        -- you'll wear it a good while, so the enchant won't be wasted
        local firstIds = {}
        for _, r in ipairs(ns.GetRankedRows(guide)) do
            if r.place and r.place <= 2 then firstIds[r.id] = true end
        end
        local seen = {}
        for _, row in ipairs(guide.enchants) do
            local slot, inv = row[1], INV[row[1]]
            if inv and not seen[inv] and equipped[inv] then
                seen[inv] = true
                local text, enchanted = ns.SlotEnchant(slot)
                if enchanted then
                    line("pass", slot .. ": " .. (text or "enchanted"))
                    table.insert(report.enchants, { slot = slot, ok = true, text = text or "enchanted" })
                else
                    local bisName = itemNameOf(row[2]):gsub("^Enchant ", "")
                    local id = tonumber((equipped[inv] or ""):match("item:(%d+)"))
                    if id and firstIds[id] then
                        line("fail", slot .. ": ready to enchant  |cff999999(" .. bisName .. ")|r")
                        table.insert(report.enchants, { slot = slot, ok = false, ready = true,
                            text = "ready: " .. bisName })
                    else
                        line("info", slot .. ": not enchanted, but an upgrade is coming  |cff999999(" .. bisName .. ")|r")
                        table.insert(report.enchants, { slot = slot, ok = false, ready = false,
                            text = bisName .. " after your upgrade" })
                    end
                end
            end
        end
    end

    -- Gear places: in each slot, is what you wear a 1st, 2nd or 3rd place pick?
    -- (rings and trinkets count twice, since you wear two)
    line("head", "Your gear by place")
    local need, worn = {}, {}
    for _, r in ipairs(ns.GetRankedRows(guide)) do
        if r.slot ~= "Ammo" and r.slot ~= "Quiver" and not r.isPre then
            if not r.isExtra and not r.isAlt then need[r.slot] = (need[r.slot] or 0) + 1 end
            if r.place and ns.Owned[r.id] == "equipped" then
                worn[r.slot] = worn[r.slot] or {}
                table.insert(worn[r.slot], r.place)
            end
        end
    end
    local placed, total = { 0, 0, 0 }, 0
    for slot, n in pairs(need) do
        total = total + n
        local list = worn[slot] or {}
        table.sort(list)
        for i = 1, math.min(n, #list) do placed[list[i]] = placed[list[i]] + 1 end
    end
    report.places, report.placeTotal = placed, total
    for place = 1, 3 do
        local name = ns.PLACE_NAMES[place] .. " place"
        line(place == 1 and placed[1] == total and "pass" or "info",
            string.format("%s items equipped: %d / %d", name, placed[place], total))
        table.insert(report.bars, { label = name, text = placed[place] .. " / " .. total,
            progress = total > 0 and placed[place] / total or 0, kind = "place" .. place })
    end
    local unranked = total - placed[1] - placed[2] - placed[3]
    if unranked > 0 then line("info", string.format("%d slot%s with no ranked item yet", unranked, unranked == 1 and "" or "s")) end

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
    -- tiles for the live numbers
    if st.crit then table.insert(report.tiles, { label = "Crit", value = string.format("%.1f%%", st.crit), note = "No cap" }) end
    local powerLabel, power
    if role == "healer" then powerLabel, power = "Healing", st.heal
    elseif role == "caster" then powerLabel, power = "Spell damage", st.spell
    elseif role == "ranged" then powerLabel, power = "Ranged attack power", st.rap
    else powerLabel, power = "Attack power", st.ap end
    if power then table.insert(report.tiles, { label = powerLabel, value = tostring(power), note = "Live from your character" }) end
    if role == "tank" and st.health then table.insert(report.tiles, { label = "Health", value = tostring(st.health), note = "Live from your character" }) end
    if (role == "healer" or role == "caster") and st.mana and st.mana > 0 then
        table.insert(report.tiles, { label = "Mana", value = tostring(st.mana), note = "Live from your character" })
    end
    table.insert(report.tiles, report.emptyTile)

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
                if not any then line("head", "Gear stats vs the 1st place set"); any = true end
                local m = mine[key] or 0
                local pct = math.floor(m / b * 100 + 0.5)
                local label
                for _, g in ipairs(STAT_GROUPS) do if g.key == key then label = g.label end end
                line(pct >= 90 and "pass" or "info", string.format("%s: %d of %d (%d%%)", label, m, b, pct))
                table.insert(report.bars, { label = label, text = string.format("%d / %d", m, b), progress = m / b, kind = "stat" })
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

-- A "view" is a set of widgets that shows a report: { summary, body, child,
-- runToken }. There are two: the Raid Check tab in the browser and the panel
-- next to the character window.
local views = {}
local panel   -- the character-window panel

local READY_ICON = "Interface\\RaidFrame\\ReadyCheck-Ready"
local NOT_ICON = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local WAIT_ICON = "Interface\\RaidFrame\\ReadyCheck-Waiting"
local GOLD = { 1, 0.82, 0 }

local function barColor(p, kind)
    if kind == "count" then return 0.25, 0.55, 1 end
    -- gold / silver / bronze, like the place trophies
    if kind == "place1" then return 0.94, 0.71, 0.16 end
    if kind == "place2" then return 0.76, 0.8, 0.84 end
    if kind == "place3" then return 0.79, 0.48, 0.24 end
    if p >= 0.9 then return 0.2, 0.8, 0.2 end
    if p >= 0.5 then return 1, 0.75, 0.1 end
    return 0.9, 0.25, 0.2
end

local function newBar(parent)
    local bg = parent:CreateTexture(nil, "ARTWORK")
    bg:SetColorTexture(0, 0, 0, 0.55)
    bg:SetHeight(6)
    local fill = parent:CreateTexture(nil, "OVERLAY")
    fill:SetHeight(6)
    fill:SetPoint("TOPLEFT", bg, "TOPLEFT")
    return { bg = bg, fill = fill,
        set = function(self, p, r, g, b, width)
            p = math.max(0, math.min(1, p or 0))
            self.fill:SetColorTexture(r, g, b, 0.95)
            self.fill:SetWidth(math.max(1, width * p))
            self.fill:SetShown(p > 0)
        end }
end

-- Widgets are created once per view and re-used; get(pool, i, make) returns the i-th
local function get(pool, i, make)
    if not pool[i] then pool[i] = make() end
    return pool[i]
end

local function render(view, report)
    local c = view.child
    local W = math.max(260, view.width or 600)
    local wide = W >= 520
    local y = -2

    -- banner
    local b = view.banner
    local ready = report.failed == 0
    -- next to the character window the panel is narrow: smaller title, shorter button
    local narrow = W < 420
    b.title:SetFontObject(narrow and "GameFontNormal" or "GameFontNormalLarge")
    b.refresh:SetWidth(narrow and 64 or 80)
    b.bg:SetColorTexture(ready and 0.1 or 0.55, ready and 0.45 or 0.08, ready and 0.1 or 0.08, 0.45)
    b.icon:SetTexture(ready and READY_ICON or NOT_ICON)
    if ready then
        b.title:SetText("|cff33ff33Raid ready|r")
    else
        b.title:SetText(string.format("|cffff5555%d thing%s to fix before raid|r", report.failed, report.failed == 1 and "" or "s"))
    end
    local className = report.class and ((LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[report.class]) or report.class) or ""
    b.sub:SetText(((report.spec or "?") .. " " .. className):gsub("^%s+", "") .. ", " .. (report.role or "?"))
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", c, "TOPLEFT", 0, y)
    b:SetSize(W, 46)
    y = y - 46 - 10

    -- tiles
    local tiles = report.tiles or {}
    local perRow = wide and math.min(math.max(#tiles, 1), 5) or 2
    local gap = 8
    local tileW = (W - gap * (perRow - 1)) / perRow
    local tileH = 74
    for i, t in ipairs(tiles) do
        local tile = get(view.tiles, i, function()
            local f = CreateFrame("Frame", nil, c)
            f.bg = f:CreateTexture(nil, "BACKGROUND")
            f.bg:SetAllPoints()
            f.bg:SetColorTexture(1, 1, 1, 0.06)
            f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            f.label:SetPoint("TOPLEFT", 8, -6)
            f.label:SetTextColor(0.75, 0.75, 0.75)
            f.value = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            f.value:SetPoint("TOPLEFT", 8, -22)
            f.note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            f.note:SetPoint("BOTTOMLEFT", 8, 6)
            f.note:SetJustifyH("LEFT")
            f.note:SetWordWrap(false)
            f.bar = newBar(f)
            f.bar.bg:SetPoint("TOPLEFT", 8, -46)
            return f
        end)
        local row, col = math.floor((i - 1) / perRow), (i - 1) % perRow
        tile:ClearAllPoints()
        tile:SetPoint("TOPLEFT", c, "TOPLEFT", col * (tileW + gap), y - row * (tileH + gap))
        tile:SetSize(tileW, tileH)
        tile.label:SetText(t.label)
        tile.label:SetWidth(tileW - 16)
        tile.value:SetText(t.value)
        if t.ok then tile.value:SetTextColor(0.2, 1, 0.2)
        elseif t.bad or (t.progress and not t.ok) then tile.value:SetTextColor(1, 0.35, 0.3)
        else tile.value:SetTextColor(1, 1, 1) end
        tile.note:SetText(t.note or "")
        tile.note:SetWidth(tileW - 16)
        tile.bar.bg:SetWidth(tileW - 16)
        if t.progress then
            tile.bar.bg:Show()
            local r, g, bb = t.ok and 0.2 or 0.9, t.ok and 0.8 or 0.25, t.ok and 0.2 or 0.2
            tile.bar:set(t.progress, r, g, bb, tileW - 16)
        else
            tile.bar.bg:Hide(); tile.bar.fill:Hide()
        end
        tile:Show()
    end
    for i = #tiles + 1, #view.tiles do view.tiles[i]:Hide() end
    local tileRows = math.ceil(#tiles / perRow)
    y = y - tileRows * (tileH + gap) - 6

    -- two sections: enchants and gear vs BiS (side by side when wide)
    local colW = wide and (W - 16) / 2 or W
    local leftY, rightY = y, y
    local rightX = wide and (colW + 16) or 0
    local function heading(fs, text, x, yy)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", c, "TOPLEFT", x, yy)
        fs:SetText(text)
        fs:Show()
        return yy - 20
    end

    -- enchants
    local ench = report.enchants or {}
    local done = 0
    local ready = 0
    for _, e in ipairs(ench) do
        if e.ok then done = done + 1 elseif e.ready then ready = ready + 1 end
    end
    view.enchHead:SetShown(#ench > 0)
    if #ench > 0 then
        leftY = heading(view.enchHead, "Enchants  |cffaaaaaa" .. done .. " / " .. #ench .. "|r"
            .. (ready > 0 and ("   |cff33ff33" .. ready .. " ready to enchant|r") or ""), 0, leftY)
    end
    -- ready to enchant first, then ones waiting on an upgrade, then done
    local function rank(e) return e.ok and 3 or (e.ready and 1 or 2) end
    table.sort(ench, function(a, bb) return rank(a) < rank(bb) end)
    for i, e in ipairs(ench) do
        local fs = get(view.enchLines, i, function()
            local f = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            f:SetJustifyH("LEFT")
            f:SetWordWrap(false)
            return f
        end)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", c, "TOPLEFT", 0, leftY)
        fs:SetWidth(colW)
        local icon = "|T" .. (e.ok and READY_ICON or e.ready and NOT_ICON or WAIT_ICON) .. ":14:14|t "
        local color = e.ok and "|cffaaaaaa" or e.ready and "|cff66ff66" or "|cff888888"
        fs:SetText(icon .. e.slot .. "  " .. color .. e.text .. "|r")
        fs:Show()
        leftY = leftY - 18
    end
    for i = #ench + 1, #view.enchLines do view.enchLines[i]:Hide() end

    -- gear vs BiS
    if not wide then rightY = leftY - 10 end
    local bars = report.bars or {}
    view.gearHead:SetShown(#bars > 0)
    if #bars > 0 then rightY = heading(view.gearHead, "Your gear vs 1st place", rightX, rightY) end
    for i, bar in ipairs(bars) do
        local row = get(view.bars, i, function()
            local f = { label = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"),
                        value = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") }
            f.value:SetJustifyH("RIGHT")
            f.value:SetTextColor(0.7, 0.7, 0.7)
            f.bar = newBar(c)
            return f
        end)
        row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", c, "TOPLEFT", rightX, rightY)
        row.label:SetText(bar.label); row.label:Show()
        row.value:ClearAllPoints(); row.value:SetPoint("TOPRIGHT", c, "TOPLEFT", rightX + colW, rightY)
        row.value:SetText(bar.text); row.value:Show()
        row.bar.bg:ClearAllPoints(); row.bar.bg:SetPoint("TOPLEFT", c, "TOPLEFT", rightX, rightY - 15)
        row.bar.bg:SetWidth(colW); row.bar.bg:Show()
        local r, g, bb = barColor(bar.progress or 0, bar.kind)
        row.bar:set(bar.progress, r, g, bb, colW)
        rightY = rightY - 30
    end
    for i = #bars + 1, #view.bars do
        local row = view.bars[i]
        row.label:Hide(); row.value:Hide(); row.bar.bg:Hide(); row.bar.fill:Hide()
    end

    -- notes that don't fit a tile (dual wield, can't-read messages)
    local notes = {}
    for _, l in ipairs(report.lines) do
        if l.status == "info" and (l.text:find("^Dual wielding") or l.text:find("couldn't read") or l.text:find("^Loading") or l.text:find("^No BiS list")) then
            table.insert(notes, l.text)
        end
    end
    local bottom = math.min(leftY, rightY) - 8
    view.notes:ClearAllPoints()
    view.notes:SetPoint("TOPLEFT", c, "TOPLEFT", 0, bottom)
    view.notes:SetWidth(W)
    view.notes:SetText(table.concat(notes, "\n"))
    bottom = bottom - (view.notes:GetStringHeight() or 0) - 10
    c:SetHeight(-bottom + 10)
end

local function refreshView(view)
    if not (view and view.frame:IsVisible()) then return end
    -- each run gets a token so a slow earlier run can't overwrite a newer one
    view.runToken = (view.runToken or 0) + 1
    local token = view.runToken
    local ok, err = pcall(ns.RunRaidCheck, function(report)
        if view.runToken ~= token then return end
        view.last = report
        local ok2, err2 = pcall(render, view, report)
        view.lastError = (not ok2) and tostring(err2) or nil
        if not ok2 then view.body:SetText("|cffff5555Raid check error:|r " .. tostring(err2)) end
    end)
    if not ok then
        view.summary:SetText("|cffff5555Raid check couldn't run|r")
        view.body:SetText("Please send this to the addon author:\n\n" .. tostring(err))
    end
end

function ns.RefreshRaidCheck()
    for _, v in ipairs(views) do refreshView(v) end
end

-- Build a report view inside a frame: summary line, Refresh button, scrolling
-- body and a footer with the targets' sources.
function ns.CreateRaidView(parent, top, bottom, width)
    local view = { frame = parent, width = width, tiles = {}, enchLines = {}, bars = {} }

    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, top)
    scroll:SetPoint("BOTTOMRIGHT", -32, bottom + 22)
    view.child = CreateFrame("Frame", nil, scroll)
    view.child:SetSize(width, 400)
    scroll:SetScrollChild(view.child)

    -- banner (status + Refresh)
    local b = CreateFrame("Frame", nil, view.child)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(26, 26)
    b.icon:SetPoint("LEFT", 10, 0)
    local refresh = CreateFrame("Button", nil, b, "UIPanelButtonTemplate")
    refresh:SetSize(80, 22)
    refresh:SetPoint("RIGHT", -10, 0)
    refresh:SetText("Refresh")
    refresh:SetScript("OnClick", function() view.refresh() end)
    b.refresh = refresh
    -- title and spec line stop at the Refresh button instead of running under it
    b.title = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    b.title:SetPoint("TOPLEFT", 44, -7)
    b.title:SetPoint("RIGHT", refresh, "LEFT", -6, 0)
    b.title:SetJustifyH("LEFT")
    b.title:SetWordWrap(false)
    b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.sub:SetPoint("TOPLEFT", 44, -27)
    b.sub:SetPoint("RIGHT", refresh, "LEFT", -6, 0)
    b.sub:SetJustifyH("LEFT")
    b.sub:SetWordWrap(false)
    b.sub:SetTextColor(0.8, 0.8, 0.8)
    view.banner = b
    -- the summary line some code still writes to
    view.summary = b.title

    view.enchHead = view.child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.gearHead = view.child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.notes = view.child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.notes:SetJustifyH("LEFT")
    view.notes:SetTextColor(0.75, 0.75, 0.75)
    -- plain text area for errors
    view.body = view.notes

    local foot = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    foot:SetPoint("BOTTOMLEFT", 16, bottom)
    foot:SetPoint("BOTTOMRIGHT", -16, bottom)
    foot:SetJustifyH("LEFT")
    foot:SetText("Hit: 8% melee/ranged, 17% spells (conquestcapped.com). Tanks: 440 defense.")
    foot:SetWordWrap(true)
    foot:Hide()   -- footers stay clean

    view.refresh = function() refreshView(view) end
    view.setWidth = function(w)
        view.width = w
        view.child:SetWidth(w)
        if view.last then
            local ok, err = pcall(render, view, view.last)
            view.lastError = (not ok) and tostring(err) or nil
        end
    end
    table.insert(views, view)
    return view
end

----------------------------------------------------------------------
-- Panel attached to the character window
----------------------------------------------------------------------
local function createPanel()
    panel = CreateFrame("Frame", "ForeverBiSRaidFrame", UIParent, "BasicFrameTemplateWithInset")
    panel:SetWidth(380)
    panel:SetFrameStrata("MEDIUM")
    panel:SetToplevel(true)
    panel:EnableMouse(true)
    panel:Hide()
    -- close for now (it comes back next time the character window opens)
    if type(panel.CloseButton) == "table" then
        panel.CloseButton:SetScript("OnClick", function()
            panel:Hide()
            if ns.UpdateCompact then ns.UpdateCompact() end   -- browser moves next to the character window
        end)
    end
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText("Raid check")
    panel.view = ns.CreateRaidView(panel, -30, 12, 330)
    panel:SetScript("OnShow", function() panel.view.refresh() end)
end

function ns.RaidPanelShown()
    return panel ~= nil and panel:IsShown()
end

-- How far things stick out past the character window's right edge (Forever
-- puts a column of side buttons there), so our windows sit beyond them.
local function rightOverhang(char)
    local edge = char.GetRight and char:GetRight()
    if not edge then return 0 end
    local far = edge
    local function look(f)
        if f == panel or f == _G.ForeverBiSFrame then return end
        if f.IsShown and f:IsShown() and f.GetRight then
            local r = f:GetRight()
            local l = f.GetLeft and f:GetLeft()
            -- only things that start at or near the edge (not huge overlays)
            if r and l and r > far and l > edge - 60 and r - edge < 160 then far = r end
        end
    end
    local function scan(parent, depth)
        if not parent.GetChildren then return end
        for _, f in ipairs({ parent:GetChildren() }) do
            look(f)
            if depth > 0 then scan(f, depth - 1) end
        end
    end
    pcall(scan, char, 1)
    -- side buttons parented elsewhere but anchored to the character window
    if UIParent and UIParent.GetChildren then
        pcall(function()
            for _, f in ipairs({ UIParent:GetChildren() }) do
                if f.GetNumPoints and (f:GetNumPoints() or 0) > 0 then
                    local _, rel = f:GetPoint(1)
                    if rel == char then look(f) end
                end
            end
        end)
    end
    return math.max(0, far - edge)
end
ns.CharacterOverhang = function() return CharacterFrame and rightOverhang(CharacterFrame) or 0 end

local function placePanel(char)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", char, "TOPRIGHT", 4 + rightOverhang(char), 0)
end

-- Show beside the character window while it's open (setting on by default)
function ns.UpdateRaidCompanion()
    local char = CharacterFrame
    if not char then return end
    -- With the browser open, the shrunk browser goes beside the character
    -- window on its own; the raid panel only shows when the browser is closed.
    local browser = _G.ForeverBiSFrame
    local browserOpen = browser and browser:IsShown() and ns.db.compactWithCharacter
    local want = char:IsShown() and ns.db.raidWithCharacter ~= false and not browserOpen
    if want then
        if not panel then createPanel() end
        panel:SetScale(ns.db.windowScale or 1)
        placePanel(char)
        -- the side buttons may be laid out a moment after the window opens
        C_Timer.After(0.05, function()
            if panel:IsShown() and char:IsShown() then
                placePanel(char)
                if ns.UpdateCompact then ns.UpdateCompact() end
            end
        end)
        local cs, ps = char:GetEffectiveScale(), panel:GetEffectiveScale()
        local ratio = (cs and ps and ps > 0) and cs / ps or 1
        panel:SetHeight(math.max(420, (char:GetHeight() or 420) * ratio))
        panel:Show()
    elseif panel then
        panel:Hide()
    end
    if ns.UpdateCompact then ns.UpdateCompact() end   -- the browser lines up beside it
end

-- /bis raid: open the browser on the Raid Check tab
function ns.ToggleRaidCheck()
    ns.char.listMode = "raid"
    local browser = _G.ForeverBiSFrame
    if not browser or not browser:IsShown() then ns.ToggleBrowser() else ns.RefreshBrowser() end
end

ns.On("PLAYER_LOGIN", function()
    if CharacterFrame and CharacterFrame.HookScript then
        CharacterFrame:HookScript("OnShow", ns.UpdateRaidCompanion)
        CharacterFrame:HookScript("OnHide", ns.UpdateRaidCompanion)
    end
end)

ns.On("PLAYER_EQUIPMENT_CHANGED", function()
    C_Timer.After(0.6, ns.RefreshRaidCheck)   -- after the owned-items refresh
end)
