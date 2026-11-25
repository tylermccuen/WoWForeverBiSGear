local _, ns = ...

--[[
    Phase 1: the first raids (open December 9, 2026)
      Barrow Deeps (10 players, 8 bosses, under Mount Hyjal, entrance in eastern Ashenvale)
      Hyjal Summit (20 players, tier sets, first legendary)
      Onyxia's Lair (40 players, needs the attunement)

    Internal phase id 2; the Pre-raid lists are id 1. This file only
    registers the phase once it holds at least one spec's list, so the
    Phase button doesn't offer an empty "Phase 1" before the lists exist.
    Specs left out keep showing their Pre-raid list.

    Research notes: tools/data/phase1_research.md
]]

local SRC = "TBD"   -- guide site the raid lists come from

-- Tier 1 sets (set IDs from conquestcapped.com). Six pieces each: Head,
-- Shoulder, Chest, Hands, Legs, Feet. Raid pieces are item level 65; the
-- Shoulder / Hands / Legs / Feet also come crafted at item level 61.
ns.TierSets = {
    ["DRUID:Balance"]        = { set = 2114, name = "Grovekeeper Eclipse" },
    ["DRUID:Feral"]          = { set = 2115, name = "Grovekeeper Ferocity" },
    ["DRUID:Feral Tank"]     = { set = 2113, name = "Grovekeeper Rage" },
    ["DRUID:Restoration"]    = { set = 2112, name = "Grovekeeper Raiment" },
    ["HUNTER:*"]             = { set = 2101, name = "Wildstalker Armor" },
    ["MAGE:*"]               = { set = 2098, name = "Manaflare Regalia" },
    ["PALADIN:Holy"]         = { set = 2107, name = "Justice Armor" },
    ["PALADIN:Protection"]   = { set = 2108, name = "Justice Battleplate" },
    ["PALADIN:Retribution"]  = { set = 2106, name = "Justice Battlegear" },
    ["PRIEST:Holy"]          = { set = 2104, name = "Vestments of Conviction" },
    ["PRIEST:Discipline"]    = { set = 2104, name = "Vestments of Conviction" },
    ["PRIEST:Shadow"]        = { set = 2105, name = "Raiments of Conviction" },
    ["ROGUE:*"]              = { set = 2099, name = "Grimstitch Armor" },
    ["SHAMAN:Elemental"]     = { set = 2111, name = "The Spiritcaller's Storm" },
    ["SHAMAN:Enhancement"]   = { set = 2110, name = "The Spiritcaller's Rage" },
    ["SHAMAN:Restoration"]   = { set = 2109, name = "The Spiritcaller" },
    ["WARLOCK:*"]            = { set = 2100, name = "Demonheart Raiment" },
    ["WARRIOR:Arms"]         = { set = 2102, name = "Battlegear of Glory" },
    ["WARRIOR:Fury"]         = { set = 2102, name = "Battlegear of Glory" },
    ["WARRIOR:Protection"]   = { set = 2103, name = "Battleplate of Glory" },
}

local guides = {
    -- { class = "HUNTER", spec = "Marksmanship", url = SRC, items = {
    --     { "Head", 0, "Hyjal Summit: Boss" },
    -- } },
}

if #guides > 0 then
    ns.RegisterPhase({
        id       = 2,
        label    = "Phase 1",
        subtitle = "Barrow Deeps, Hyjal Summit, Onyxia's Lair",
        source   = SRC,
        checked  = "YYYY-MM-DD",
        guides   = guides,
    })
end
