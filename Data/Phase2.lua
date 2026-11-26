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

-- Until the lists exist, "Phase 1" is a planning page in the Phase menu.
ns.RegisterPreview({
    id       = 2,
    label    = "Phase 1",
    subtitle = "raids open Dec 9, 2026",
    opens    = { year = 2026, month = 12, day = 9 },
    raids = {
        { "Barrow Deeps", "10 players", "8 bosses, under Mount Hyjal (tunnels start in eastern Ashenvale). No attunement." },
        { "Hyjal Summit", "20 players", "Tier set pieces and the first legendary." },
        { "Onyxia's Lair", "40 players", "Needs the Onyxia attunement." },
    },
    timeline = {
        { "Nov 4, 2026", "Launch: level 60 and dungeons (Pre-raid lists)", done = true },
        { "Dec 9, 2026", "Phase 1: Barrow Deeps, Hyjal Summit and Onyxia's Lair open" },
        { "Dec 15 - Jan 2", "Feast of Winter Veil (the addon's holiday theme)" },
        { "Winter 2026", "Hardcore servers" },
        { "Spring 2027", "2 new raids (10 and 20 players), 2 new dungeons, 2 new class / race combos, new zone and quests, PvP refresh" },
        { "Summer 2027", "A revamped iconic raid, a new raid, 2 new dungeons, profession and legacy updates, PvP refresh" },
    },
    ready = {
        "Do the Onyxia attunement before Dec 9.",
        "Start Guardians of Hyjal reputation: Friendly (plus the quest Friendly Advice) unlocks the crafted tier Legs pattern; more slots need more reputation.",
        "Crafted tier needs 300 Tailoring (cloth), Leatherworking (leather, mail) or Blacksmithing (plate), and a camp station (Blueprint, near a Campfire).",
        "Patterns are sold by Aisarra Nightmeadow in Mount Hyjal for Malleable Essence of Nature, which comes from disenchanting Hyjal Summit and Barrow Deeps loot.",
        "Stock up: Consumables tab. Enchant what you'll keep: Enchants tab. Check hit and enchants: Raid Check tab.",
    },
    unknown = "Blizzard hasn't published the raid loot tables, and Forever hides an item's stats until someone loots it, so no guide has raid BiS lists yet. The Phase 1 lists will be added to the addon in the days after the raids open.",
    sources = "Dates: Blizzard's WoW Forever roadmap (via icy-veins.com). Raids and tier sets: conquestcapped.com, lfcarry.com.",
})

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
