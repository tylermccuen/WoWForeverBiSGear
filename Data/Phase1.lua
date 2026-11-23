local _, ns = ...

--[[
    PHASE 1 - Pre-raid (level 60) Best-in-Slot lists for World of Warcraft: Forever.

    Lists:    wowtbc.gg WoW Forever BiS lists ("Realistic" view, hand-picked,
              one item per slot), collected 23 November 2026. Cross-checked
              against conquestcapped.com guides (updated 22 Nov 2026) where
              available; both agree on the core of each list.
    Item IDs: verified one by one against Forever item databases (kovarel.com,
              the Wowhead Forever links on timesaver.gg, and the ID tables on
              conquestcapped.com) - not taken from Classic.

    Row format:  { slot, itemID, source [, hordeItemID, hordeSource] }
    When a Horde ID is given, the first item is the Alliance pick.
    See UPDATING.md for how to add a new phase.
]]

local SRC = "https://wowtbc.gg/warcraftforever/bis-list/"

-- Dungeon Set 2 (Tier 0.5) questline stages, both factions
local D2_WRIST = "Dungeon Set 2 quest: An Earnest Proposition"
local D2_HANDS = "Dungeon Set 2 quest: Just Compensation"
local D2_LEGS  = "Dungeon Set 2 quest: Anthion's Parting Words"
local D2_HEAD  = "Dungeon Set 2 quest: Saving the Best for Last"

local PIX50  = "Pix Xizzix (Booty Bay): 50 Tarnished Undermine Real"
local PIX75  = "Pix Xizzix (Booty Bay): 75 Tarnished Undermine Real"
local PIX100 = "Pix Xizzix (Booty Bay): 100 Tarnished Undermine Real"
local PIX125 = "Pix Xizzix (Booty Bay): 125 Tarnished Undermine Real"
local AV_EX  = "Stormpike Guard / Frostwolf Clan (Exalted)"
local LW, BS, TAILOR = "Crafted: Leatherworking", "Crafted: Blacksmithing", "Crafted: Tailoring"

-- Shared rows
local MARK        = { "Neck",    15411,  "Quest: In Dreams (Western Plaguelands)" }
local NACREOUS    = { "Neck",    22403,  "Stratholme: Cannon Master Willey" }
local TOOTH_GNARR = { "Neck",    13141,  "Upper Blackrock Spire: General Drakkisath" }
local HORN_VEHAN  = { "Neck",    275736, "Quest: Work Well Done (Mount Hyjal)" }
local BLACK_BARON = { "Back",    13340,  "Stratholme: Baron Rivendare" }
local ARCANOWEAVE = { "Back",    272411, PIX75 }
local HIDE_WILD   = { "Back",    18510,  LW }
local STALWART_CL = { "Back",    272415, PIX75 }
local DONJULIO    = { "Finger",  19325,  AV_EX }
local CUTTHROAT   = { "Finger",  272408, PIX75 }
local CHANNELER   = { "Finger",  272406, PIX75 }
local RUNEBAND    = { "Finger",  22339,  "Upper Blackrock Spire: Lord Valthalak" }
local MENDING     = { "Finger",  22334,  "Stratholme: Grand Crusader Dathrohan" }
local FORDRING    = { "Finger",  16058,  "Quest: In Dreams (Western Plaguelands)" }
local BREADTH     = { "Trinket", 13965,  "Quest: For The Horde! / General Drakkisath's Demise" }
local WYRMTHALAK  = { "Trinket", 22321,  "Lower Blackrock Spire: Overlord Wyrmthalak" }
local EYE_BEAST   = { "Trinket", 13968,  "Quest: For The Horde! / General Drakkisath's Demise" }
local WEAKNESS    = { "Trinket", 272438, PIX125 }
local SERENITY    = { "Trinket", 272439, PIX125 }
local ADAPTIVE    = { "Trinket", 272437, PIX125 }
local SMOLDERWEB  = { "Trinket", 13213,  "Lower Blackrock Spire: Mother Smolderweb" }
local SAGEBLADE   = { "Main Hand", 22383, BS }
local GIFT_MAGI   = { "Main Hand", 13360, "Stratholme: Balnazzar" }
local WITCHBLADE  = { "Main Hand", 13964, "Scholomance: Darkmaster Gandling" }
local THERAZANE   = { "Off Hand", 19315, AV_EX }
local LEI         = { "Off Hand", 19312, AV_EX }
local IMMOVABLE   = { "Off Hand", 19321, AV_EX }
local PENELOPE    = { "Off Hand", 15805, "Quest: Kirtonos the Herald (Scholomance)" }
local BLOODSEEKER = { "Ranged",  19107,  "Alterac Valley quest: Korrak the Bloodrager / Hero of the Stormpike / Hero of the Frostwolf" }
local BONECREEPER = { "Wand",    13938,  "Scholomance: Darkmaster Gandling" }
local LIVING      = { "Head",    252561, LW }
local BDH         = { "Head",    252605, LW }
local SPELLWEAVER = { "Head",    22267,  "Upper Blackrock Spire: General Drakkisath" }
local DAWN        = { "Chest",   252483, LW }
local TIMBER_TUN  = { "Chest",   252484, LW }
local ROBE_VOID   = { "Chest",   14153,  TAILOR }
local DARK_SUMMON = { "Chest",   280057, "Blackmaw Hold: Impaan the Imprisoner" }
local DEV_GLOVES  = { "Hands",   15063,  LW }
local DEV_LEGS    = { "Legs",    15062,  LW }
local ARCHMAGE_BT = { "Waist",   18405,  TAILOR }
local IRONFEATHER = { "Legs",    252486, LW }
local TORMENT     = { "Legs",    22342,  "Upper Blackrock Spire: Lord Valthalak" }
local OMNICAST    = { "Feet",    11822,  "Blackrock Depths: Golem Lord Argelmach" }
local TIMBER_MANT = { "Shoulder", 19050, TAILOR }
local NETHERPEARL = { "Wrist",   254067, TAILOR }
local LIBRAM_FERV = { "Relic",   23203,  "World drop" }
local STORM_TOTEM = { "Relic",   272432, PIX50 }
-- Songstone of Ironforge (Alliance) and Eye of Orgrimmar (Horde) have the same stats
local SONGSTONE   = { "Finger",  12543,  "Quest: The Princess's Surprise (Blackrock Depths)", 12545, "Quest: The Princess Saved? (Blackrock Depths)" }

local guides = {
    -- WARRIOR
    { class = "WARRIOR", spec = "Arms", url = SRC .. "arms-warrior/", items = {
        { "Head",     12640,  BS },
        MARK,
        { "Shoulder", 20517,  "Quest: Voodoo Feathers (Sunken Temple)" },
        BLACK_BARON,
        TIMBER_TUN,
        { "Wrist",    12936,  "Upper Blackrock Spire: Warchief Rend Blackhand" },
        { "Hands",    226861, D2_HANDS },
        { "Waist",    272403, PIX100 },
        { "Legs",     22385,  BS },
        { "Feet",     226857, D2_LEGS },
        DONJULIO,
        { "Finger",   13098,  "Upper Blackrock Spire: General Drakkisath" },
        BREADTH,
        WYRMTHALAK,
        { "Two Hand", 12790,  BS },
        BLOODSEEKER,
    } },
    { class = "WARRIOR", spec = "Fury", url = SRC .. "fury-warrior/", items = {
        { "Head",     12640,  BS },
        MARK,
        { "Shoulder", 22241,  "Blackrock Depths: Warder Stilgiss" },
        BLACK_BARON,
        TIMBER_TUN,
        { "Wrist",    12936,  "Upper Blackrock Spire: Warchief Rend Blackhand" },
        { "Hands",    226861, D2_HANDS },
        { "Waist",    272403, PIX100 },
        { "Legs",     22385,  BS },
        { "Feet",     226857, D2_LEGS },
        DONJULIO,
        { "Finger",   260219, "Quest: Blackmaw Reclamation (Blackmaw Hold)" },
        WYRMTHALAK,
        BREADTH,
        { "Main Hand", 22384, BS },
        { "Off Hand",  10847, "Sunken Temple: Shade of Eranikus" },
        BLOODSEEKER,
    } },
    { class = "WARRIOR", spec = "Protection", url = SRC .. "protection-warrior/", items = {
        { "Head",     226869, D2_HEAD },
        HORN_VEHAN,
        { "Shoulder", 226867, D2_LEGS },
        STALWART_CL,
        { "Chest",    226862, D2_HEAD },
        { "Wrist",    13951,  "Scholomance: Darkmaster Gandling" },
        { "Hands",    226870, D2_HANDS },
        { "Waist",    13142,  "Upper Blackrock Spire: General Drakkisath" },
        { "Legs",     226868, D2_LEGS },
        { "Feet",     226857, D2_LEGS },
        DONJULIO,
        CUTTHROAT,
        ADAPTIVE,
        { "Trinket",  18466,  "Quest: Codex of Defense (Dire Maul)" },
        { "Main Hand", 11684, "Blackrock Depths: Emperor Dagran Thaurissan" },
        IMMOVABLE,
        { "Ranged",   280020, "The Shaper's Terrace: Thunderhoof" },
    } },

    -- PALADIN
    { class = "PALADIN", spec = "Holy", url = SRC .. "holy-paladin/", items = {
        LIVING,
        TOOTH_GNARR,
        { "Shoulder", 226979, D2_LEGS },
        HIDE_WILD,
        { "Chest",    226984, D2_HEAD },
        { "Wrist",    226977, D2_WRIST },
        { "Hands",    226982, D2_HANDS },
        { "Waist",    226978, D2_HANDS },
        { "Legs",     250600, BS },
        { "Feet",     226983, D2_LEGS },
        FORDRING,
        MENDING,
        SERENITY,
        { "Trinket",  18472,  "Quest: The Light and How To Swing It (Dire Maul)" },
        { "Main Hand", 22315, "Dire Maul East: Isalien" },
        LEI,
        { "Relic",    272436, PIX50 },
    } },
    { class = "PALADIN", spec = "Protection", url = SRC .. "protection-paladin/", items = {
        { "Head",     250599, BS },
        NACREOUS,
        { "Shoulder", 226969, D2_LEGS },
        ARCANOWEAVE,
        { "Chest",    226992, D2_HEAD },
        { "Wrist",    226985, D2_WRIST },
        { "Hands",    226990, D2_HANDS },
        { "Waist",    226971, D2_HANDS },
        { "Legs",     226988, D2_LEGS },
        { "Feet",     226991, D2_LEGS },
        DONJULIO,
        RUNEBAND,
        ADAPTIVE,
        BREADTH,
        SAGEBLADE,
        IMMOVABLE,
        LIBRAM_FERV,
    } },
    { class = "PALADIN", spec = "Retribution", url = SRC .. "retribution-paladin/", items = {
        { "Head",     226976, D2_HEAD },
        MARK,
        { "Shoulder", 226969, D2_LEGS },
        ARCANOWEAVE,
        TIMBER_TUN,
        { "Wrist",    226970, D2_WRIST },
        { "Hands",    12632,  LW },
        ARCHMAGE_BT,
        { "Legs",     250598, BS },
        { "Feet",     226974, D2_LEGS },
        DONJULIO,
        { "Finger",   22433,  "Scholomance: Darkmaster Gandling" },
        SMOLDERWEB,
        -- Rune of the Guard Captain is a Horde quest; the Alliance version of that quest chain gives Cleansed Vilebranch Medallion
        { "Trinket",  270275, "Quest: Saving Sharpbeak (The Hinterlands, Alliance)", 19120, "Quest: Job Opening: Guard Captain of Revantusk Village (Horde)" },
        { "Two Hand", 12592,  "Upper Blackrock Spire: General Drakkisath" },
        LIBRAM_FERV,
    } },

    -- HUNTER
    { class = "HUNTER", spec = "Beast Mastery", url = SRC .. "beast-mastery-hunter/", items = {
        BDH,
        MARK,
        { "Shoulder", 18686,  "Scholomance: Rattlegore" },
        { "Back",     272414, PIX75 },
        DAWN,
        { "Wrist",    18296,  "Dire Maul: trash drop" },
        DEV_GLOVES,
        { "Waist",    22232,  "Lower Blackrock Spire: Urok Doomhowl" },
        DEV_LEGS,
        { "Feet",     226881, D2_LEGS },
        DONJULIO,
        CUTTHROAT,
        BREADTH,
        WYRMTHALAK,
        { "Two Hand", 274419, "Barkskin Burrow reputation (Revered)" },
        { "Ranged",   13023,  "World drop" },
    } },
    { class = "HUNTER", spec = "Marksmanship", url = SRC .. "marksmanship-hunter/", items = {
        BDH,
        MARK,
        { "Shoulder", 18686,  "Scholomance: Rattlegore" },
        BLACK_BARON,
        DAWN,
        { "Wrist",    18296,  "Dire Maul: trash drop" },
        DEV_GLOVES,
        { "Waist",    22232,  "Lower Blackrock Spire: Urok Doomhowl" },
        DEV_LEGS,
        { "Feet",     13967,  "Scholomance: Kirtonos the Herald" },
        DONJULIO,
        CUTTHROAT,
        BREADTH,
        WYRMTHALAK,
        { "Main Hand", 280021, "The Shaper's Terrace: Direhorn Matriarch" },
        { "Off Hand",  286613, "Un'Goro Crater: King Mosh (rare spawn)" },
        { "Ranged",    13023,  "World drop" },
    } },
    { class = "HUNTER", spec = "Survival", url = SRC .. "survival-hunter/", items = {
        BDH,
        MARK,
        { "Shoulder", 18742,  "Stratholme: trash drop" },
        BLACK_BARON,
        DAWN,
        { "Wrist",    18375,  "Dire Maul West: Prince Tortheldrin" },
        DEV_GLOVES,
        { "Waist",    272397, PIX100 },
        DEV_LEGS,
        { "Feet",     226881, D2_LEGS },
        DONJULIO,
        CUTTHROAT,
        WYRMTHALAK,
        BREADTH,
        { "Two Hand", 13285,  "Lower Blackrock Spire: Spirestone Battle Lord" },
        BLOODSEEKER,
    } },

    -- ROGUE
    { class = "ROGUE", spec = "Assassination", url = SRC .. "assassination-rogue/", items = {
        { "Head",     226829, D2_HEAD },
        MARK,
        { "Shoulder", 15058,  LW },
        BLACK_BARON,
        { "Chest",    226825, D2_HEAD },
        { "Wrist",    226830, D2_WRIST },
        { "Hands",    21278,  LW },
        { "Waist",    272395, PIX100 },
        { "Legs",     15057,  LW },
        { "Feet",     226831, D2_LEGS },
        DONJULIO,
        CUTTHROAT,
        WYRMTHALAK,
        BREADTH,
        { "Main Hand", 12590, "Upper Blackrock Spire: Warchief Rend Blackhand" },
        { "Off Hand",  18392, "Dire Maul West: Prince Tortheldrin" },
        BLOODSEEKER,
    } },
    { class = "ROGUE", spec = "Combat", url = SRC .. "combat-rogue/", items = {
        { "Head",     226829, D2_HEAD },
        MARK,
        { "Shoulder", 226826, D2_LEGS },
        BLACK_BARON,
        DAWN,
        { "Wrist",    226830, D2_WRIST },
        DEV_GLOVES,
        { "Waist",    272395, PIX100 },
        DEV_LEGS,
        { "Feet",     226831, D2_LEGS },
        DONJULIO,
        CUTTHROAT,
        WYRMTHALAK,
        BREADTH,
        { "Main Hand", 6622,   "World drop" },
        { "Off Hand",  280012, "The Shaper's Terrace: Tor'Rel" },
        BLOODSEEKER,
    } },
    { class = "ROGUE", spec = "Subtlety", url = SRC .. "subtlety-rogue/", items = {
        { "Head",     226829, D2_HEAD },
        MARK,
        { "Shoulder", 226826, D2_LEGS },
        BLACK_BARON,
        DAWN,
        { "Wrist",    226830, D2_WRIST },
        DEV_GLOVES,
        { "Waist",    272395, PIX100 },
        DEV_LEGS,
        { "Feet",     226831, D2_LEGS },
        DONJULIO,
        CUTTHROAT,
        WYRMTHALAK,
        BREADTH,
        { "Main Hand", 12590, "Upper Blackrock Spire: Warchief Rend Blackhand" },
        { "Off Hand",  18392, "Dire Maul West: Prince Tortheldrin" },
        BLOODSEEKER,
    } },

    -- PRIEST
    { class = "PRIEST", spec = "Discipline", url = SRC .. "discipline-priest/", items = {
        { "Head",     226947, D2_HEAD },
        { "Neck",     18723,  "Stratholme: Ramstein the Gorger" },
        { "Shoulder", 14139,  TAILOR },
        HIDE_WILD,
        { "Chest",    226945, D2_HEAD },
        { "Wrist",    226949, D2_WRIST },
        { "Hands",    226950, D2_HANDS },
        { "Waist",    272394, PIX100 },
        { "Legs",     226946, D2_LEGS },
        { "Feet",     226952, D2_LEGS },
        MENDING,
        { "Finger",   272407, PIX75 },
        SERENITY,
        { "Trinket",  18469,  "Quest: Holy Bologna: What the Light Won't Tell You (Dire Maul)" },
        GIFT_MAGI,
        LEI,
        { "Wand",     22254,  "Blackrock Depths: trash drop" },
    } },
    { class = "PRIEST", spec = "Holy", url = SRC .. "holy-priest/", items = {
        { "Head",     226947, D2_HEAD },
        { "Neck",     18723,  "Stratholme: Ramstein the Gorger" },
        { "Shoulder", 14139,  TAILOR },
        HIDE_WILD,
        { "Chest",    226945, D2_HEAD },
        { "Wrist",    226949, D2_WRIST },
        { "Hands",    226950, D2_HANDS },
        { "Waist",    272394, PIX100 },
        { "Legs",     226946, D2_LEGS },
        { "Feet",     226952, D2_LEGS },
        MENDING,
        { "Finger",   272407, PIX75 },
        SERENITY,
        { "Trinket",  18469,  "Quest: Holy Bologna: What the Light Won't Tell You (Dire Maul)" },
        GIFT_MAGI,
        LEI,
        { "Wand",     22254,  "Blackrock Depths: trash drop" },
    } },
    { class = "PRIEST", spec = "Shadow", url = SRC .. "shadow-priest/", items = {
        SPELLWEAVER,
        NACREOUS,
        { "Shoulder", 226955, D2_LEGS },
        ARCANOWEAVE,
        DARK_SUMMON,
        NETHERPEARL,
        { "Hands",    14146,  TAILOR },
        ARCHMAGE_BT,
        TORMENT,
        { "Feet",     226959, D2_LEGS },
        RUNEBAND,
        CHANNELER,
        WEAKNESS,
        EYE_BEAST,
        { "Main Hand", 18372, "Dire Maul West: Immol'thar" },
        { "Off Hand",  19309, AV_EX },
        { "Wand",      13396, "Stratholme: Skul (rare)" },
    } },

    -- SHAMAN
    { class = "SHAMAN", spec = "Elemental", url = SRC .. "elemental-shaman/", items = {
        { "Head",     227002, D2_HEAD },
        NACREOUS,
        { "Shoulder", 227003, D2_LEGS },
        ARCANOWEAVE,
        DARK_SUMMON,
        { "Wrist",    227001, D2_WRIST },
        { "Hands",    227006, D2_HANDS },
        { "Waist",    227008, D2_HANDS },
        IRONFEATHER,
        { "Feet",     227007, D2_LEGS },
        CHANNELER,
        RUNEBAND,
        EYE_BEAST,
        { "Trinket",  18471,  "Quest: Frost Shock and You (Dire Maul)" },
        WITCHBLADE,
        THERAZANE,
        STORM_TOTEM,
    } },
    { class = "SHAMAN", spec = "Enhancement", url = SRC .. "enhancement-shaman/", items = {
        { "Head",     227021, D2_HEAD },
        MARK,
        { "Shoulder", 227019, D2_LEGS },
        ARCANOWEAVE,
        { "Chest",    227024, D2_HEAD },
        { "Wrist",    227017, D2_WRIST },
        { "Hands",    227022, D2_HANDS },
        { "Waist",    227018, D2_HANDS },
        { "Legs",     252606, LW },
        { "Feet",     14616,  "Scholomance: drop" },
        DONJULIO,
        CHANNELER,
        WYRMTHALAK,
        BREADTH,
        { "Two Hand", 13285,  "Lower Blackrock Spire: Spirestone Battle Lord" },
        STORM_TOTEM,
    } },
    { class = "SHAMAN", spec = "Restoration", url = SRC .. "restoration-shaman/", items = {
        LIVING,
        TOOTH_GNARR,
        { "Shoulder", 227011, D2_LEGS },
        HIDE_WILD,
        { "Chest",    227016, D2_HEAD },
        { "Wrist",    227009, D2_WRIST },
        { "Hands",    227014, D2_HANDS },
        { "Waist",    227010, D2_HANDS },
        { "Legs",     18386,  "Dire Maul West: Illyanna Ravenoak" },
        { "Feet",     227015, D2_LEGS },
        MENDING,
        FORDRING,
        SERENITY,
        { "Trinket",  18471,  "Quest: Frost Shock and You (Dire Maul)" },
        GIFT_MAGI,
        PENELOPE,
        { "Relic",    23200,  "Scholomance: trash drop" },
    } },

    -- MAGE
    { class = "MAGE", spec = "Arcane", url = SRC .. "arcane-mage/", items = {
        { "Head",     226935, D2_HEAD },
        NACREOUS,
        { "Shoulder", 226936, D2_LEGS },
        ARCANOWEAVE,
        { "Chest",    14152,  TAILOR },
        { "Wrist",    226929, D2_WRIST },
        { "Hands",    226930, D2_HANDS },
        ARCHMAGE_BT,
        { "Legs",     226933, D2_LEGS },
        { "Feet",     226931, D2_LEGS },
        CHANNELER,
        SONGSTONE,
        EYE_BEAST,
        SMOLDERWEB,
        SAGEBLADE,
        THERAZANE,
        BONECREEPER,
    } },
    { class = "MAGE", spec = "Fire", url = SRC .. "fire-mage/", items = {
        { "Head",     226935, D2_HEAD },
        NACREOUS,
        { "Shoulder", 226936, D2_LEGS },
        ARCANOWEAVE,
        { "Chest",    14152,  TAILOR },
        { "Wrist",    226929, D2_WRIST },
        { "Hands",    226930, D2_HANDS },
        ARCHMAGE_BT,
        { "Legs",     226933, D2_LEGS },
        { "Feet",     226931, D2_LEGS },
        CHANNELER,
        RUNEBAND,
        WEAKNESS,
        EYE_BEAST,
        SAGEBLADE,
        { "Off Hand", 19311,  AV_EX },
        BONECREEPER,
    } },
    { class = "MAGE", spec = "Frost", url = SRC .. "frost-mage/", items = {
        { "Head",     226935, D2_HEAD },
        NACREOUS,
        { "Shoulder", 226936, D2_LEGS },
        ARCANOWEAVE,
        { "Chest",    14152,  TAILOR },
        { "Wrist",    226929, D2_WRIST },
        { "Hands",    226930, D2_HANDS },
        ARCHMAGE_BT,
        { "Legs",     226933, D2_LEGS },
        { "Feet",     226931, D2_LEGS },
        CHANNELER,
        RUNEBAND,
        WEAKNESS,
        EYE_BEAST,
        SAGEBLADE,
        { "Off Hand", 19310,  AV_EX },
        { "Wand",     19108,  "Alterac Valley quest: Korrak the Bloodrager / Hero of the Stormpike / Hero of the Frostwolf" },
    } },

    -- WARLOCK
    { class = "WARLOCK", spec = "Affliction", url = SRC .. "affliction-warlock/", items = {
        SPELLWEAVER,
        { "Neck",     18691,  "Scholomance: Vectus" },
        TIMBER_MANT,
        ARCANOWEAVE,
        ROBE_VOID,
        NETHERPEARL,
        { "Hands",    18407,  TAILOR },
        ARCHMAGE_BT,
        TORMENT,
        OMNICAST,
        SONGSTONE,
        { "Finger",   13001,  "World drop" },
        WEAKNESS,
        { "Trinket",  18467,  "Quest: Harnessing Shadows (Dire Maul)" },
        SAGEBLADE,
        { "Off Hand", 19309,  AV_EX },
        { "Wand",     13396,  "Stratholme: Skul (rare)" },
    } },
    { class = "WARLOCK", spec = "Demonology", url = SRC .. "demonology-warlock/", items = {
        SPELLWEAVER,
        NACREOUS,
        TIMBER_MANT,
        ARCANOWEAVE,
        ROBE_VOID,
        { "Wrist",    18497,  "Dire Maul: trash drop" },
        { "Hands",    226911, D2_HANDS },
        ARCHMAGE_BT,
        { "Legs",     13170,  "Lower Blackrock Spire: Highlord Omokk" },
        OMNICAST,
        RUNEBAND,
        CHANNELER,
        { "Trinket",  18467,  "Quest: Harnessing Shadows (Dire Maul)" },
        EYE_BEAST,
        SAGEBLADE,
        THERAZANE,
        BONECREEPER,
    } },
    { class = "WARLOCK", spec = "Destruction", url = SRC .. "destruction-warlock/", items = {
        SPELLWEAVER,
        NACREOUS,
        TIMBER_MANT,
        ARCANOWEAVE,
        ROBE_VOID,
        { "Wrist",    18497,  "Dire Maul: trash drop" },
        { "Hands",    226911, D2_HANDS },
        ARCHMAGE_BT,
        { "Legs",     13170,  "Lower Blackrock Spire: Highlord Omokk" },
        OMNICAST,
        CHANNELER,
        RUNEBAND,
        WEAKNESS,
        { "Trinket",  18467,  "Quest: Harnessing Shadows (Dire Maul)" },
        SAGEBLADE,
        THERAZANE,
        BONECREEPER,
    } },

    -- DRUID
    { class = "DRUID", spec = "Balance", url = SRC .. "balance-druid/", items = {
        { "Head",     226773, D2_HEAD },
        NACREOUS,
        { "Shoulder", 226778, D2_LEGS },
        ARCANOWEAVE,
        { "Chest",    226776, D2_HEAD },
        { "Wrist",    226775, D2_WRIST },
        { "Hands",    226777, D2_HANDS },
        ARCHMAGE_BT,
        IRONFEATHER,
        { "Feet",     226774, D2_LEGS },
        RUNEBAND,
        CHANNELER,
        EYE_BEAST,
        WEAKNESS,
        WITCHBLADE,
        THERAZANE,
        { "Relic",    272430, PIX50 },
    } },
    { class = "DRUID", spec = "Feral", url = SRC .. "feral-dps-druid/", items = {
        { "Head",     226792, D2_HEAD },
        MARK,
        { "Shoulder", 16708,  "Stratholme: Cannon Master Willey" },
        BLACK_BARON,
        TIMBER_TUN,
        { "Wrist",    16710,  "World drop" },
        { "Hands",    19049,  LW },
        { "Waist",    272396, PIX100 },
        { "Legs",     15065,  LW },
        { "Feet",     16711,  "Scholomance: Rattlegore" },
        DONJULIO,
        CUTTHROAT,
        BREADTH,
        { "Trinket",  280065, "Blackmaw Hold: Blackmaw Behemoth" },
        { "Two Hand", 19323,  AV_EX },
        { "Relic",    272427, PIX50 },
    } },
    { class = "DRUID", spec = "Feral Tank", url = SRC .. "feral-tank-druid/", items = {
        { "Head",     13404,  "Stratholme: The Unforgiven" },
        HORN_VEHAN,
        { "Shoulder", 226798, D2_LEGS },
        STALWART_CL,
        { "Chest",    226804, D2_HEAD },
        { "Wrist",    226796, D2_WRIST },
        { "Hands",    226802, D2_HANDS },
        { "Waist",    287040, "World drop" },
        { "Legs",     226799, D2_LEGS },
        { "Feet",     226803, D2_LEGS },
        { "Finger",   15855,  "Quest: Hidden Treasures" },
        { "Finger",   260216, "Quest: Blackmaw Reclamation (Blackmaw Hold)" },
        ADAPTIVE,
        WYRMTHALAK,
        { "Two Hand", 18531,  "Dire Maul North: Mizzle the Crafty (tribute chest)" },
        { "Relic",    23198,  "Stratholme: Magistrate Barthilas" },
    } },
    { class = "DRUID", spec = "Restoration", url = SRC .. "restoration-druid/", items = {
        LIVING,
        { "Neck",     10829,  "Sunken Temple: Shade of Eranikus" },
        { "Shoulder", 226785, D2_LEGS },
        { "Back",     18350,  "Dire Maul West: Magister Kalendris" },
        { "Chest",    12462,  "Sunken Temple: Avatar of Hakkar (very rare)" },
        { "Wrist",    226782, D2_WRIST },
        { "Hands",    226784, D2_HANDS },
        { "Waist",    272398, PIX100 },
        { "Legs",     16694,  "Stratholme: Baron Rivendare" },
        { "Feet",     226781, D2_LEGS },
        { "Finger",   275740, "Quest: Work Well Done (Mount Hyjal)" },
        { "Finger",   284079, "Western Plaguelands: Scarlet High Clerist (rare)" },
        { "Trinket",  1713,   "World drop (BoE)" },
        { "Trinket",  280060, "Blackmaw Hold: Bonesnout the Unbroken" },
        GIFT_MAGI,
        PENELOPE,
        { "Relic",    272429, PIX50 },
    } },
}

--[[
    Alternatives: other good picks per slot, shown under the main BiS item in the
    browser (toggle "Alternatives") and on tooltips as "Alternative for you".
    Source: conquestcapped.com WoW Forever BiS guides (updated 22 Nov 2026).
    Same row format as above, plus an optional note = "..." shown next to the source.
]]
-- Faction reputation items (Theramore Expeditionary Force / Darkspear Raiders, Exalted)
local REP = "Theramore Expeditionary Force (Exalted)"
local REP_H = "Darkspear Raiders (Exalted)"
local EPAULETS  = { "Shoulder", 271956, REP, 272106, REP_H }
local SPAULDERS = { "Shoulder", 271959, REP, 272108, REP_H }
local SHGUARDS  = { "Shoulder", 272957, REP, 272958, REP_H }
local MANTLE    = { "Shoulder", 271957, REP, 272107, REP_H }
local PAULDRONS = { "Shoulder", 271955, REP, 272105, REP_H }
local GAUNTLETS = { "Hands",    271940, REP, 272095, REP_H }
local HANDWRAPS = { "Hands",    271945, REP, 272097, REP_H }
local GLOVES    = { "Hands",    271948, REP, 272099, REP_H }

local HOWLERS     = { "Back",    272414, PIX75, note = "1% hit" }
local ELVEN_RING  = { "Finger",  18500,  "Dire Maul North: Mizzle the Crafty (tribute)", note = "1% hit" }
local LODESTONE   = { "Trinket", 18537,  "Dire Maul North: Mizzle the Crafty (tribute)" }
local BEHEMOTH    = { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" }
local CHOSEN      = { "Trinket", 17774,  "Quest: The Pariah's Instructions (Maraudon)" }
local RIPHOOK     = { "Ranged",  12653,  "Lower Blackrock Spire: Shadow Hunter Vosh'gajin" }
local NIGHTFALL   = { "Two Hand", 19169, "Crafted: Blacksmithing (Axesmith)" }
local PAINWEAVER  = { "Finger",  13098,  "Upper Blackrock Spire: General Drakkisath" }
local OBSIDIAN    = { "Off Hand", 18316, "Dire Maul East: Pusillin" }
local AQUEMENTAS  = { "Off Hand", 11904, "Quest: It's Dangerous to Go Alone (Un'Goro Crater)" }
local AEGIS       = { "Off Hand", 22336, "Upper Blackrock Spire: Lord Valthalak" }
local AWARENESS   = { "Finger",  272409, PIX75, note = "9 defense" }
local LIBRAM_LAW  = { "Relic",   272435, PIX50 }
local PENELOPE_A  = { "Off Hand", 15805, "Quest: Kirtonos the Herald (Scholomance)" }

local ALTS = {
    ["WARRIOR:Arms"] = {
        SPAULDERS, HOWLERS, GAUNTLETS,
        { "Finger", 260219, "Quest: Blackmaw Reclamation (Blackmaw Hold)" },
        LODESTONE, NIGHTFALL,
        { "Ranged", 18323, "Dire Maul: Zevrim Thornhoof", note = "1% hit" },
    },
    ["WARRIOR:Fury"] = {
        SPAULDERS, GAUNTLETS,
        { "Waist", 20041, "Arathi Basin: League of Arathor", 20204, "Arathi Basin: The Defilers" },
        CUTTHROAT, LODESTONE,
        { "Main Hand", 11684, "Blackrock Depths: Emperor Dagran Thaurissan" },
        { "Ranged",    18323, "Dire Maul: Zevrim Thornhoof", note = "1% hit" },
    },
    ["WARRIOR:Protection"] = {
        SPAULDERS,
        { "Chest",  226872, D2_HEAD,  note = "Protection version" },
        { "Wrist",  226865, D2_WRIST, note = "Protection version" },
        GAUNTLETS,
        { "Waist",  226866, D2_HANDS, note = "Protection version" },
        { "Feet",   226871, D2_LEGS,  note = "Protection version" },
        AWARENESS,
        { "Finger", 22331,  "Scholomance: Kormok" },
        CHOSEN,
        { "Main Hand", 12590, "Upper Blackrock Spire: Warchief Rend Blackhand" },
        { "Off Hand",  12602, "Upper Blackrock Spire: General Drakkisath" },
        { "Ranged",    16996, "Quest: The Scarlet Oracle, Demetria (Eastern Plaguelands)" },
    },
    ["PALADIN:Holy"] = {
        SHGUARDS,
        { "Chest", 250601, BS },
        HANDWRAPS,
        PENELOPE_A,
    },
    ["PALADIN:Protection"] = {
        { "Head",  226989, D2_HEAD, note = "Protection version" },
        { "Neck",  281636, "Quest: Greater Friend of the Library" },
        MANTLE,
        { "Back",  18495,  "Dire Maul North: Mizzle the Crafty (tribute)", note = "7 defense" },
        { "Waist", 250573, BS, note = "10 defense" },
        AWARENESS,
        { "Finger", 17045, "Quest: Aurius' Reckoning (Stratholme)" },
        CHOSEN,
        AEGIS,
        LIBRAM_LAW,
    },
    ["PALADIN:Retribution"] = {
        { "Chest", 226973, D2_HEAD },
        { "Waist", 226971, D2_HANDS, note = "1% hit" },
        { "Finger", 272406, PIX75, note = "1% hit" },
        WYRMTHALAK,
        NIGHTFALL,
        LIBRAM_LAW,
    },
    ["HUNTER:Beast Mastery"] = {
        EPAULETS,
        { "Wrist", 13211, "Lower Blackrock Spire: Halycon", note = "1% hit" },
        ELVEN_RING,
        BEHEMOTH,
        RIPHOOK,
    },
    ["HUNTER:Marksmanship"] = {
        EPAULETS,
        HOWLERS,
        { "Wrist", 18375, "Dire Maul West: Prince Tortheldrin" },
        ELVEN_RING,
        { "Trinket", 280071, "Blackmaw Hold: Unbound Spirit" },
        { "Off Hand", 12783, "Crafted: Blacksmithing (Weaponsmith)" },
        { "Ranged",   18680, "Scholomance: random drop", note = "rare" },
    },
    ["HUNTER:Survival"] = {
        EPAULETS,
        HOWLERS,
        { "Hands", 13255, "Lower Blackrock Spire: Shadow Hunter Vosh'gajin", note = "3% ranged hit" },
        { "Waist", 22207, "Blackrock Depths: Emperor Dagran Thaurissan", note = "1% ranged hit" },
        { "Legs",  17754, "Maraudon: Lord Vyletongue", note = "1% ranged hit" },
        { "Feet",  13967, "Scholomance: Kirtonos the Herald", note = "1% hit" },
        ELVEN_RING,
        { "Main Hand", 12940, "Upper Blackrock Spire: Warchief Rend Blackhand", note = "dual-wield option" },
        { "Off Hand",  18392, "Dire Maul West: Prince Tortheldrin", note = "dual-wield option" },
        RIPHOOK,
    },
    ["ROGUE:Assassination"] = {
        { "Shoulder", 226826, D2_LEGS },
        { "Chest",    15056,  LW },
        PAINWEAVER,
        LODESTONE,
    },
    ["ROGUE:Combat"] = {
        { "Shoulder", 15058,  LW },
        { "Chest",    226825, D2_HEAD, note = "1.5% hit" },
        { "Hands",    21278,  LW, note = "1% hit" },
        { "Legs",     15057,  LW },
        PAINWEAVER,
        LODESTONE,
        { "Main Hand", 10847, "Sunken Temple: Shade of Eranikus" },
        { "Off Hand",  18392, "Dire Maul West: Prince Tortheldrin" },
    },
    ["ROGUE:Subtlety"] = {
        { "Shoulder", 15058,  LW },
        { "Chest",    226825, D2_HEAD, note = "1.5% hit" },
        { "Hands",    21278,  LW, note = "1% hit" },
        { "Legs",     15057,  LW },
        PAINWEAVER,
        LODESTONE,
        BEHEMOTH,
    },
    ["PRIEST:Discipline"] = { PENELOPE_A },
    ["PRIEST:Holy"]       = { PENELOPE_A },
    ["PRIEST:Shadow"] = {
        { "Wrist",   226953, D2_WRIST, note = "if you are not a Tailor" },
        { "Trinket", 12930,  "Upper Blackrock Spire: Jed Runewatcher" },
        OBSIDIAN,
    },
    ["SHAMAN:Elemental"] = {
        { "Chest", 227004, D2_HEAD },
        ARCHMAGE_BT,
        AEGIS,
        { "Relic", 272433, PIX50 },
    },
    ["SHAMAN:Enhancement"] = {
        BDH,
        EPAULETS,
        HOWLERS,
        TIMBER_TUN,
        { "Wrist",  279256, LW },
        { "Hands",  14615,  "Scholomance: drop" },
        { "Legs",   22748,  "Warsong Gulch: Silverwing Sentinels (Exalted)", 22673, "Warsong Gulch: Warsong Outriders (Exalted)", note = "1% hit" },
        { "Finger", 275981, "The Watchers (Exalted)", note = "1% hit" },
        BEHEMOTH,
        LODESTONE,
        { "Two Hand", 279260, BS },
        { "Relic",    22395,  "Blackrock Depths: Magmus" },
    },
    ["SHAMAN:Restoration"] = { SHGUARDS, HANDWRAPS },
    ["MAGE:Arcane"] = { WEAKNESS, OBSIDIAN },
    ["MAGE:Fire"]   = { OBSIDIAN },
    ["MAGE:Frost"]  = { AQUEMENTAS },
    ["WARLOCK:Affliction"] = {
        { "Finger", 22433, "Scholomance: Darkmaster Gandling" },
        OBSIDIAN,
    },
    ["WARLOCK:Demonology"]  = { WEAKNESS, AQUEMENTAS },
    ["WARLOCK:Destruction"] = { EYE_BEAST, OBSIDIAN },
    ["DRUID:Balance"] = { OBSIDIAN },
    ["DRUID:Feral"] = {
        PAULDRONS,
        { "Wrist", 270124, "Quest: Lethtendris's Web (Dire Maul)" },
        GLOVES,
        { "Feet",  12553,  "Blackrock Depths: Princess Moira Bronzebeard" },
        { "Finger", 22255, "Blackrock Depths: Secret Safe" },
        LODESTONE,
        { "Two Hand", 18420, "Quest: The Treasure of the Shen'dralar (Dire Maul)" },
    },
    ["DRUID:Feral Tank"] = {
        { "Head",  226801, D2_HEAD, note = "tank version" },
        { "Hands", 235044, "Source not confirmed in Forever yet" },
        { "Waist", 226797, D2_HANDS, note = "tank version" },
        CHOSEN,
    },
    -- Restoration Druid: both guides agree on every slot, so no alternatives
}
--[[
    Realistic pre-raid sets: gear most players can finish in a week or two
    (dungeon drops, quests, Tier 0.5 and at most one Pix Xizzix item), shown when
    the browser's list switch is set to "Realistic".
    Source: conquestcapped.com WoW Forever BiS guides, Realistic tab (23 Nov 2026).
]]
local REALISTIC = {
    ["HUNTER:Marksmanship"] = {
        { "Head", 226887, D2_HEAD, note = "1% hit" },                                              -- Beastmaster's Cap
        { "Neck", 22340, "Upper Blackrock Spire: Lord Valthalak", note = "1% hit" },               -- Pendant of Celerity
        { "Shoulder", 226884, D2_LEGS },                                                           -- Beastmaster's Mantle
        { "Back", 13340, "Stratholme: Baron Rivendare" },                                          -- Cape of the Black Baron
        { "Chest", 226886, D2_HEAD },                                                              -- Beastmaster's Tunic
        { "Wrist", 226885, D2_WRIST },                                                             -- Beastmaster's Bindings
        { "Hands", 13963, "Quest: Maxwell's Mission (Lower Blackrock Spire)", 13963, "Quest: Warlord's Command (Lower Blackrock Spire)", note = "1.5% hit" }, -- Voone's Vice Grips
        { "Waist", 22232, "Lower Blackrock Spire: Urok Doomhowl", note = "1% hit" },               -- Marksman's Girdle
        { "Legs", 226882, D2_LEGS },                                                               -- Beastmaster's Pants
        { "Feet", 226881, D2_LEGS },                                                               -- Beastmaster's Treads
        { "Finger", 272408, PIX75, note = "1% hit" },                                              -- Cutthroat's Signet
        { "Finger", 18500, "Dire Maul North: Mizzle the Crafty (tribute)", note = "1% hit" },      -- Tarnished Elven Ring
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" },                                 -- Behemoth Bones
        { "Two Hand", 279910, "Quest: Mapping the Way Forward (The Shaper's Terrace)", 279910, "Quest: The Dark Crystal (The Shaper's Terrace)", note = "1.6% hit" }, -- Beastslayer's Trident
        { "Ranged", 280020, "The Shaper's Terrace: Thunderhoof", note = "0.5% hit" },              -- Deep Jungle Rifle
    },
    ["HUNTER:Beast Mastery"] = {
        { "Head", 226887, D2_HEAD, note = "1% hit" },                                              -- Beastmaster's Cap
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 271956, REP, 272106, REP_H },                                                -- Theramore Epaulets / Darkspear Epaulets
        { "Back", 13340, "Stratholme: Baron Rivendare" },                                          -- Cape of the Black Baron
        { "Chest", 226886, D2_HEAD },                                                              -- Beastmaster's Tunic
        { "Wrist", 13211, "Lower Blackrock Spire: Halycon", note = "1% hit" },                     -- Slashclaw Bracers
        { "Hands", 226883, D2_HANDS },                                                             -- Beastmaster's Gauntlets
        { "Waist", 22232, "Lower Blackrock Spire: Urok Doomhowl", note = "1% hit" },               -- Marksman's Girdle
        { "Legs", 226882, D2_LEGS },                                                               -- Beastmaster's Pants
        { "Feet", 226881, D2_LEGS },                                                               -- Beastmaster's Treads
        { "Finger", 272408, PIX75, note = "1% hit" },                                              -- Cutthroat's Signet
        { "Finger", 18500, "Dire Maul North: Mizzle the Crafty (tribute)", note = "1% hit" },      -- Tarnished Elven Ring
        { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" },                                 -- Behemoth Bones
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Two Hand", 279910, "Quest: Mapping the Way Forward (The Shaper's Terrace)", 279910, "Quest: The Dark Crystal (The Shaper's Terrace)", note = "1.6% hit" }, -- Beastslayer's Trident
        { "Ranged", 280020, "The Shaper's Terrace: Thunderhoof", note = "0.5% hit" },              -- Deep Jungle Rifle
    },
    ["HUNTER:Survival"] = {
        { "Head", 226887, D2_HEAD, note = "1% hit" },                                              -- Beastmaster's Cap
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 12927, "Upper Blackrock Spire: Pyroguard Emberseer", note = "1.5% hit" },    -- Truestrike Shoulders
        { "Back", 13340, "Stratholme: Baron Rivendare" },                                          -- Cape of the Black Baron
        { "Chest", 226886, D2_HEAD },                                                              -- Beastmaster's Tunic
        { "Wrist", 18375, "Dire Maul West: Prince Tortheldrin" },                                  -- Bracers of the Eclipse
        { "Hands", 226883, D2_HANDS },                                                             -- Beastmaster's Gauntlets
        { "Waist", 22207, "Blackrock Depths: Emperor Dagran Thaurissan", note = "1% ranged hit" }, -- Sash of the Grand Hunt
        { "Legs", 226882, D2_LEGS },                                                               -- Beastmaster's Pants
        { "Feet", 13967, "Scholomance: Kirtonos the Herald", note = "1% hit" },                    -- Windreaver Greaves
        { "Finger", 272408, PIX75, note = "1% hit" },                                              -- Cutthroat's Signet
        { "Finger", 18500, "Dire Maul North: Mizzle the Crafty (tribute)", note = "1% hit" },      -- Tarnished Elven Ring
        { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" },                                 -- Behemoth Bones
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Main Hand", 12940, "Upper Blackrock Spire: Warchief Rend Blackhand" },                  -- Dal'Rend's Sacred Charge
        { "Off Hand", 12939, "Upper Blackrock Spire: Warchief Rend Blackhand" },                   -- Dal'Rend's Tribal Guardian
        { "Ranged", 280020, "The Shaper's Terrace: Thunderhoof", note = "0.5% hit" },              -- Deep Jungle Rifle
    },
    ["WARRIOR:Arms"] = {
        { "Head", 20521, "Quest: Voodoo Feathers (Sunken Temple)", note = "1% hit" },              -- Fury Visor
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 226858, D2_LEGS },                                                           -- Spaulders of Heroism
        { "Back", 272414, PIX75, note = "1% hit" },                                                -- Howler's Furs
        { "Chest", 226862, D2_HEAD, note = "1% hit" },                                             -- Breastplate of Heroism
        { "Wrist", 12936, "Upper Blackrock Spire: Warchief Rend Blackhand", note = "1% hit" },     -- Battleborn Armbraces
        { "Hands", 226861, D2_HANDS },                                                             -- Gauntlets of Heroism
        { "Waist", 226864, D2_HANDS },                                                             -- Belt of Heroism
        { "Legs", 226859, D2_LEGS },                                                               -- Legplates of Heroism
        { "Feet", 226857, D2_LEGS, note = "1% hit" },                                              -- Battleboots of Heroism
        { "Finger", 17713, "Maraudon: Princess Theradras", note = "1% hit" },                      -- Blackstone Ring
        { "Finger", 18500, "Dire Maul North: Mizzle the Crafty (tribute)", note = "1% hit" },      -- Tarnished Elven Ring
        { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" },                                 -- Behemoth Bones
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Two Hand", 280018, "The Shaper's Terrace: Thunderhoof" },                               -- Hammer of Thundering Hooves
        { "Ranged", 18323, "Dire Maul: Zevrim Thornhoof", note = "1% hit" },                       -- Satyr's Bow
    },
    ["WARRIOR:Fury"] = {
        { "Head", 20521, "Quest: Voodoo Feathers (Sunken Temple)", note = "1% hit" },              -- Fury Visor
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 226858, D2_LEGS },                                                           -- Spaulders of Heroism
        { "Back", 272414, PIX75, note = "1% hit" },                                                -- Howler's Furs
        { "Chest", 226862, D2_HEAD, note = "1% hit" },                                             -- Breastplate of Heroism
        { "Wrist", 12936, "Upper Blackrock Spire: Warchief Rend Blackhand", note = "1% hit" },     -- Battleborn Armbraces
        { "Hands", 226861, D2_HANDS },                                                             -- Gauntlets of Heroism
        { "Waist", 226864, D2_HANDS },                                                             -- Belt of Heroism
        { "Legs", 226859, D2_LEGS },                                                               -- Legplates of Heroism
        { "Feet", 226857, D2_LEGS, note = "1% hit" },                                              -- Battleboots of Heroism
        { "Finger", 17713, "Maraudon: Princess Theradras", note = "1% hit" },                      -- Blackstone Ring
        { "Finger", 18500, "Dire Maul North: Mizzle the Crafty (tribute)", note = "1% hit" },      -- Tarnished Elven Ring
        { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" },                                 -- Behemoth Bones
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Main Hand", 12940, "Upper Blackrock Spire: Warchief Rend Blackhand" },                  -- Dal'Rend's Sacred Charge
        { "Off Hand", 12939, "Upper Blackrock Spire: Warchief Rend Blackhand" },                   -- Dal'Rend's Tribal Guardian
        { "Ranged", 18323, "Dire Maul: Zevrim Thornhoof", note = "1% hit" },                       -- Satyr's Bow
    },
    ["WARRIOR:Protection"] = {
        { "Head", 226869, D2_HEAD, note = "9 defense" },                                           -- Faceguard of Heroism
        { "Neck", 275736, "Quest: Work Well Done (Mount Hyjal)" },                                 -- Horn of Ve'han
        { "Shoulder", 226867, D2_LEGS },                                                           -- Pauldrons of Heroism
        { "Back", 18495, "Dire Maul North: Mizzle the Crafty (tribute)", note = "7 defense" },     -- Redoubt Cloak
        { "Chest", 226872, D2_HEAD, note = "9 defense" },                                          -- Chestguard of Heroism
        { "Wrist", 226865, D2_WRIST },                                                             -- Wristguards of Heroism
        { "Hands", 226870, D2_HANDS },                                                             -- Handguards of Heroism
        { "Waist", 226866, D2_HANDS },                                                             -- Waistguard of Heroism
        { "Legs", 226868, D2_LEGS },                                                               -- Legguards of Heroism
        { "Feet", 226871, D2_LEGS },                                                               -- Sabatons of Heroism
        { "Finger", 18315, "Dire Maul East: Alzzin the Wildshaper", note = "7 defense" },          -- Ring of Demonic Potency
        { "Finger", 22331, "Scholomance: Kormok", note = "7 defense" },                            -- Band of the Steadfast Hero
        { "Trinket", 272440, PIX125, note = "13 defense" },                                        -- Defender's Grip Stabilizer
        { "Trinket", 11810, "Blackrock Depths: General Angerforge" },                              -- Force of Will
        { "Main Hand", 17705, "Quest: Corruption of Earth and Seed (Maraudon)" },                  -- Thrash Blade
        { "Off Hand", 12602, "Upper Blackrock Spire: General Drakkisath", note = "10 defense" },   -- Draconian Deflector
        { "Ranged", 16996, "Quest: The Scarlet Oracle, Demetria (Eastern Plaguelands)" },          -- Gorewood Bow
    },
    ["PALADIN:Holy"] = {
        { "Head", 226981, D2_HEAD },                                                               -- Soulforge Crown
        { "Neck", 13141, "Upper Blackrock Spire: General Drakkisath" },                            -- Tooth of Gnarr
        { "Shoulder", 226979, D2_LEGS },                                                           -- Soulforge Epaulets
        { "Back", 272413, PIX75 },                                                                 -- Drape of Recovery
        { "Chest", 226984, D2_HEAD },                                                              -- Soulforge Embrace
        { "Wrist", 226977, D2_WRIST },                                                             -- Soulforge Bindings
        { "Hands", 18527, "Dire Maul North: King Gordok" },                                        -- Harmonious Gauntlets
        { "Waist", 18327, "Dire Maul East: Alzzin the Wildshaper" },                               -- Whipvine Cord
        { "Legs", 226980, D2_LEGS },                                                               -- Soulforge Leggings
        { "Feet", 226983, D2_LEGS },                                                               -- Soulforge Treads
        { "Finger", 16058, "Quest: In Dreams (Western Plaguelands)" },                             -- Fordring's Seal
        { "Finger", 13178, "Lower Blackrock Spire: Urok Doomhowl" },                               -- Rosewine Circle
        { "Trinket", 18472, "Quest: The Light and How To Swing It (Dire Maul)" },                  -- Royal Seal (Paladin)
        { "Trinket", 11832, "Blackrock Depths: Ambassador Flamelash" },                            -- Burst of Knowledge
        { "Main Hand", 276404, "Stratholme: Crimson Hammersmith" },                                -- Masterwork Crimson Hammer
        { "Off Hand", 15805, "Quest: Kirtonos the Herald (Scholomance)" },                         -- Penelope's Rose
        { "Relic", 23201, "Scholomance: rare drop" },                                              -- Libram of Divinity
    },
    ["PALADIN:Protection"] = {
        { "Head", 226989, D2_HEAD, note = "4 defense" },                                           -- Soulforge Faceguard
        { "Neck", 275736, "Quest: Work Well Done (Mount Hyjal)" },                                 -- Horn of Ve'han
        { "Shoulder", 226987, D2_LEGS },                                                           -- Soulforge Pauldrons
        { "Back", 18495, "Dire Maul North: Mizzle the Crafty (tribute)", note = "7 defense" },     -- Redoubt Cloak
        { "Chest", 226992, D2_HEAD },                                                              -- Soulforge Chestguards
        { "Wrist", 226985, D2_WRIST },                                                             -- Soulforge Wristguards
        { "Hands", 226990, D2_HANDS },                                                             -- Soulforge Handguards
        { "Waist", 226986, D2_HANDS },                                                             -- Soulforge Waistguard
        { "Legs", 226988, D2_LEGS },                                                               -- Soulforge Legguards
        { "Feet", 226991, D2_LEGS },                                                               -- Soulforge Sabatons
        { "Finger", 272409, PIX75, note = "9 defense" },                                           -- Ring of Awareness
        { "Finger", 18315, "Dire Maul East: Alzzin the Wildshaper", note = "7 defense" },          -- Ring of Demonic Potency
        { "Trinket", 17774, "Quest: The Pariah's Instructions (Maraudon)" },                       -- Mark of the Chosen
        { "Trinket", 11810, "Blackrock Depths: General Angerforge" },                              -- Force of Will
        { "Main Hand", 18048, "Upper Blackrock Spire: Goraluk Anvilcrack", note = "1% hit" },      -- Mastersmith's Hammer
        { "Off Hand", 12602, "Upper Blackrock Spire: General Drakkisath", note = "10 defense" },   -- Draconian Deflector
        { "Relic", 22401, "Dire Maul East: Isalien" },                                             -- Libram of Hope
    },
    ["PALADIN:Retribution"] = {
        { "Head", 226976, D2_HEAD },                                                               -- Soulforge Greathelm
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 226969, D2_LEGS },                                                           -- Soulforge Spaulders
        { "Back", 272411, PIX75, note = "1% hit" },                                                -- Arcanoweave Cloak
        { "Chest", 226973, D2_HEAD },                                                              -- Soulforge Breastplate
        { "Wrist", 226970, D2_WRIST },                                                             -- Soulforge Bracers
        { "Hands", 226975, D2_HANDS },                                                             -- Soulforge Gauntlets
        { "Waist", 226971, D2_HANDS, note = "1% hit" },                                            -- Soulforge Belt
        { "Legs", 226972, D2_LEGS },                                                               -- Soulforge Legplates
        { "Feet", 226974, D2_LEGS },                                                               -- Soulforge Warboots
        { "Finger", 17713, "Maraudon: Princess Theradras", note = "1% hit" },                      -- Blackstone Ring
        { "Finger", 18314, "Dire Maul East: Alzzin the Wildshaper", note = "1% hit" },             -- Ring of Demonic Guile
        { "Trinket", 22321, "Lower Blackrock Spire: Overlord Wyrmthalak" },                        -- Heart of Wyrmthalak
        { "Trinket", 13213, "Lower Blackrock Spire: Mother Smolderweb", note = "1% hit" },         -- Smolderweb's Eye
        { "Two Hand", 280018, "The Shaper's Terrace: Thunderhoof" },                               -- Hammer of Thundering Hooves
        { "Relic", 22401, "Dire Maul East: Isalien" },                                             -- Libram of Hope
    },
    ["ROGUE:Assassination"] = {
        { "Head", 226829, D2_HEAD },                                                               -- Darkmantle Cap
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 226826, D2_LEGS },                                                           -- Darkmantle Spaulders
        { "Back", 13340, "Stratholme: Baron Rivendare" },                                          -- Cape of the Black Baron
        { "Chest", 226825, D2_HEAD, note = "1.5% hit" },                                           -- Darkmantle Tunic
        { "Wrist", 226830, D2_WRIST },                                                             -- Darkmantle Bracers
        { "Hands", 226828, D2_HANDS },                                                             -- Darkmantle Grips
        { "Waist", 226832, D2_HANDS },                                                             -- Darkmantle Belt
        { "Legs", 226827, D2_LEGS },                                                               -- Darkmantle Pants
        { "Feet", 226831, D2_LEGS },                                                               -- Darkmantle Footpads
        { "Finger", 272408, PIX75, note = "1% hit" },                                              -- Cutthroat's Signet
        { "Finger", 13098, "Upper Blackrock Spire: General Drakkisath" },                          -- Painweaver Band
        { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" },                                 -- Behemoth Bones
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Main Hand", 13984, "Quest: The Lich, Ras Frostwhisper (Scholomance)" },                 -- Darrowspike
        { "Off Hand", 18392, "Dire Maul West: Prince Tortheldrin" },                               -- Distracting Dagger
        { "Ranged", 18323, "Dire Maul: Zevrim Thornhoof", note = "1% hit" },                       -- Satyr's Bow
    },
    ["ROGUE:Combat"] = {
        { "Head", 226829, D2_HEAD },                                                               -- Darkmantle Cap
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 226826, D2_LEGS, note = "0.6% hit" },                                        -- Darkmantle Spaulders
        { "Back", 13340, "Stratholme: Baron Rivendare" },                                          -- Cape of the Black Baron
        { "Chest", 226825, D2_HEAD, note = "1.5% hit" },                                           -- Darkmantle Tunic
        { "Wrist", 226830, D2_WRIST },                                                             -- Darkmantle Bracers
        { "Hands", 226828, D2_HANDS },                                                             -- Darkmantle Grips
        { "Waist", 226832, D2_HANDS },                                                             -- Darkmantle Belt
        { "Legs", 226827, D2_LEGS, note = "0.5% hit" },                                            -- Darkmantle Pants
        { "Feet", 226831, D2_LEGS, note = "0.7% hit" },                                            -- Darkmantle Footpads
        { "Finger", 272408, PIX75, note = "1% hit" },                                              -- Cutthroat's Signet
        { "Finger", 13098, "Upper Blackrock Spire: General Drakkisath" },                          -- Painweaver Band
        { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" },                                 -- Behemoth Bones
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Main Hand", 12940, "Upper Blackrock Spire: Warchief Rend Blackhand" },                  -- Dal'Rend's Sacred Charge
        { "Off Hand", 12939, "Upper Blackrock Spire: Warchief Rend Blackhand" },                   -- Dal'Rend's Tribal Guardian
        { "Ranged", 18323, "Dire Maul: Zevrim Thornhoof", note = "1% hit" },                       -- Satyr's Bow
    },
    ["ROGUE:Subtlety"] = {
        { "Head", 226829, D2_HEAD },                                                               -- Darkmantle Cap
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 226826, D2_LEGS, note = "0.6% hit" },                                        -- Darkmantle Spaulders
        { "Back", 13340, "Stratholme: Baron Rivendare" },                                          -- Cape of the Black Baron
        { "Chest", 226825, D2_HEAD, note = "1.5% hit" },                                           -- Darkmantle Tunic
        { "Wrist", 226830, D2_WRIST },                                                             -- Darkmantle Bracers
        { "Hands", 226828, D2_HANDS },                                                             -- Darkmantle Grips
        { "Waist", 226832, D2_HANDS },                                                             -- Darkmantle Belt
        { "Legs", 226827, D2_LEGS, note = "0.5% hit" },                                            -- Darkmantle Pants
        { "Feet", 226831, D2_LEGS, note = "0.7% hit" },                                            -- Darkmantle Footpads
        { "Finger", 272408, PIX75, note = "1% hit" },                                              -- Cutthroat's Signet
        { "Finger", 13098, "Upper Blackrock Spire: General Drakkisath" },                          -- Painweaver Band
        { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" },                                 -- Behemoth Bones
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Main Hand", 18758, "Scholomance: Death Knight Darkreaver (summoned)" },                 -- Specter's Blade
        { "Off Hand", 18392, "Dire Maul West: Prince Tortheldrin" },                               -- Distracting Dagger
        { "Ranged", 18323, "Dire Maul: Zevrim Thornhoof", note = "1% hit" },                       -- Satyr's Bow
    },
    ["PRIEST:Discipline"] = {
        { "Head", 226947, D2_HEAD },                                                               -- Virtuous Crown
        { "Neck", 18723, "Stratholme: Ramstein the Gorger" },                                      -- Animated Chain Necklace
        { "Shoulder", 22234, "Blackrock Depths: Lord Roccor" },                                    -- Mantle of Lost Hope
        { "Back", 272413, PIX75 },                                                                 -- Drape of Recovery
        { "Chest", 226945, D2_HEAD },                                                              -- Virtuous Robe
        { "Wrist", 226949, D2_WRIST },                                                             -- Virtuous Bracers
        { "Hands", 226950, D2_HANDS },                                                             -- Virtuous Mitts
        { "Waist", 18327, "Dire Maul East: Alzzin the Wildshaper" },                               -- Whipvine Cord
        { "Legs", 226946, D2_LEGS },                                                               -- Virtuous Skirt
        { "Feet", 226952, D2_LEGS },                                                               -- Virtuous Sandals
        { "Finger", 16058, "Quest: In Dreams (Western Plaguelands)" },                             -- Fordring's Seal
        { "Finger", 13178, "Lower Blackrock Spire: Urok Doomhowl" },                               -- Rosewine Circle
        { "Trinket", 18469, "Quest: Holy Bologna: What the Light Won't Tell You (Dire Maul)" },    -- Royal Seal (Priest)
        { "Trinket", 11832, "Blackrock Depths: Ambassador Flamelash" },                            -- Burst of Knowledge
        { "Main Hand", 13360, "Stratholme: Balnazzar" },                                           -- Gift of the Elven Magi
        { "Off Hand", 15805, "Quest: Kirtonos the Herald (Scholomance)" },                         -- Penelope's Rose
        { "Wand", 22254, "Blackrock Depths: Secret Safe" },                                        -- Wand of Eternal Light
    },
    ["PRIEST:Holy"] = {
        { "Head", 226947, D2_HEAD },                                                               -- Virtuous Crown
        { "Neck", 18723, "Stratholme: Ramstein the Gorger" },                                      -- Animated Chain Necklace
        { "Shoulder", 226951, D2_LEGS },                                                           -- Virtuous Mantle
        { "Back", 272413, PIX75 },                                                                 -- Drape of Recovery
        { "Chest", 226945, D2_HEAD },                                                              -- Virtuous Robe
        { "Wrist", 226949, D2_WRIST },                                                             -- Virtuous Bracers
        { "Hands", 226950, D2_HANDS },                                                             -- Virtuous Mitts
        { "Waist", 18327, "Dire Maul East: Alzzin the Wildshaper" },                               -- Whipvine Cord
        { "Legs", 226946, D2_LEGS },                                                               -- Virtuous Skirt
        { "Feet", 226952, D2_LEGS },                                                               -- Virtuous Sandals
        { "Finger", 16058, "Quest: In Dreams (Western Plaguelands)" },                             -- Fordring's Seal
        { "Finger", 13178, "Lower Blackrock Spire: Urok Doomhowl" },                               -- Rosewine Circle
        { "Trinket", 18469, "Quest: Holy Bologna: What the Light Won't Tell You (Dire Maul)" },    -- Royal Seal (Priest)
        { "Trinket", 11832, "Blackrock Depths: Ambassador Flamelash" },                            -- Burst of Knowledge
        { "Main Hand", 13360, "Stratholme: Balnazzar" },                                           -- Gift of the Elven Magi
        { "Off Hand", 15805, "Quest: Kirtonos the Herald (Scholomance)" },                         -- Penelope's Rose
        { "Wand", 22254, "Blackrock Depths: Secret Safe" },                                        -- Wand of Eternal Light
    },
    ["PRIEST:Shadow"] = {
        { "Head", 22267, "Upper Blackrock Spire: General Drakkisath", note = "1% hit" },           -- Spellweaver's Turban
        { "Neck", 22403, "Stratholme: Cannon Master Willey", note = "1% hit" },                    -- Nacreous Shell Necklace
        { "Shoulder", 226955, D2_LEGS, note = "1% hit" },                                          -- Virtuous Epaulets
        { "Back", 272411, PIX75, note = "1% hit" },                                                -- Arcanoweave Cloak
        { "Chest", 280057, "Blackmaw Hold: Impaan the Imprisoner", note = "1.8% hit" },            -- Robes of Dark Summons
        { "Wrist", 226953, D2_WRIST },                                                             -- Virtuous Wraps
        { "Hands", 226958, D2_HANDS },                                                             -- Virtuous Hands
        { "Waist", 226954, D2_HANDS },                                                             -- Virtuous Cord
        { "Legs", 226956, D2_LEGS },                                                               -- Virtuous Leggings
        { "Feet", 226959, D2_LEGS },                                                               -- Virtuous Slippers
        { "Finger", 12543, "Quest: The Princess's Surprise (Blackrock Depths)", 12545, "Quest: The Princess Saved? (Blackrock Depths)" }, -- Songstone of Ironforge / Eye of Orgrimmar
        { "Finger", 22433, "Scholomance: Darkmaster Gandling" },                                   -- Don Mauricio's Band of Domination
        { "Trinket", 13968, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Eye of the Beast
        { "Trinket", 12930, "Upper Blackrock Spire: Jed Runewatcher" },                            -- Briarwood Reed
        { "Main Hand", 18372, "Dire Maul West: Immol'thar" },                                      -- Blade of the New Moon
        { "Off Hand", 18316, "Dire Maul East: Pusillin" },                                         -- Obsidian Bauble
        { "Wand", 13396, "Stratholme: Skul (rare)" },                                              -- Skul's Ghastly Touch
    },
    ["SHAMAN:Elemental"] = {
        { "Head", 227002, D2_HEAD },                                                               -- Coif of The Five Thunders
        { "Neck", 22403, "Stratholme: Cannon Master Willey", note = "1% hit" },                    -- Nacreous Shell Necklace
        { "Shoulder", 227003, D2_LEGS, note = "1% hit" },                                          -- Pauldrons of The Five Thunders
        { "Back", 272411, PIX75, note = "1% hit" },                                                -- Arcanoweave Cloak
        { "Chest", 227004, D2_HEAD },                                                              -- Vest of The Five Thunders
        { "Wrist", 227001, D2_WRIST },                                                             -- Bindings of The Five Thunders
        { "Hands", 227006, D2_HANDS, note = "1% hit" },                                            -- Gauntlets of The Five Thunders
        { "Waist", 227008, D2_HANDS },                                                             -- Cord of The Five Thunders
        { "Legs", 227005, D2_LEGS, note = "1% hit" },                                              -- Kilt of The Five Thunders
        { "Feet", 227007, D2_LEGS },                                                               -- Slippers of The Five Thunders
        { "Finger", 12543, "Quest: The Princess's Surprise (Blackrock Depths)", 12545, "Quest: The Princess Saved? (Blackrock Depths)" }, -- Songstone of Ironforge / Eye of Orgrimmar
        { "Finger", 22339, "Upper Blackrock Spire: Lord Valthalak", note = "1% hit" },             -- Rune Band of Wizardry
        { "Trinket", 13968, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Eye of the Beast
        { "Trinket", 18471, "Quest: Frost Shock and You (Dire Maul)" },                            -- Royal Seal (Shaman)
        { "Main Hand", 13964, "Scholomance: Darkmaster Gandling" },                                -- Witchblade
        { "Off Hand", 22336, "Upper Blackrock Spire: Lord Valthalak" },                            -- Draconian Aegis of the Legion
        { "Relic", 228176, "Pix Xizzix (Booty Bay): 15 Tarnished Undermine Real" },                -- Totem of Thunder
    },
    ["SHAMAN:Enhancement"] = {
        { "Head", 227021, D2_HEAD },                                                               -- Face of The Five Thunders
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 227019, D2_LEGS },                                                           -- Spaulders of The Five Thunders
        { "Back", 272414, PIX75, note = "1% hit" },                                                -- Howler's Furs
        { "Chest", 227024, D2_HEAD },                                                              -- Chain of The Five Thunders
        { "Wrist", 227017, D2_WRIST },                                                             -- Bands of The Five Thunders
        { "Hands", 227022, D2_HANDS },                                                             -- Fists of The Five Thunders
        { "Waist", 227018, D2_HANDS, note = "1% hit" },                                            -- Girdle of The Five Thunders
        { "Legs", 12963, "Upper Blackrock Spire: drop", note = "1% hit" },                         -- Blademaster Leggings
        { "Feet", 13967, "Scholomance: Kirtonos the Herald", note = "1% hit" },                    -- Windreaver Greaves
        { "Finger", 17713, "Maraudon: Princess Theradras", note = "1% hit" },                      -- Blackstone Ring
        { "Finger", 18314, "Dire Maul East: Alzzin the Wildshaper", note = "1% hit" },             -- Ring of Demonic Guile
        { "Trinket", 280065, "Blackmaw Hold: Blackmaw Behemoth" },                                 -- Behemoth Bones
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Two Hand", 280018, "The Shaper's Terrace: Thunderhoof" },                               -- Hammer of Thundering Hooves
        { "Relic", 22395, "Blackrock Depths: Magmus" },                                            -- Totem of Rage
    },
    ["SHAMAN:Restoration"] = {
        { "Head", 227013, D2_HEAD },                                                               -- Crown of The Five Thunders
        { "Neck", 13141, "Upper Blackrock Spire: General Drakkisath" },                            -- Tooth of Gnarr
        { "Shoulder", 227011, D2_LEGS },                                                           -- Mantle of The Five Thunders
        { "Back", 272413, PIX75 },                                                                 -- Drape of Recovery
        { "Chest", 227016, D2_HEAD },                                                              -- Tunic of The Five Thunders
        { "Wrist", 227009, D2_WRIST },                                                             -- Bracers of The Five Thunders
        { "Hands", 18527, "Dire Maul North: King Gordok" },                                        -- Harmonious Gauntlets
        { "Waist", 18327, "Dire Maul East: Alzzin the Wildshaper" },                               -- Whipvine Cord
        { "Legs", 227012, D2_LEGS },                                                               -- Leggings of The Five Thunders
        { "Feet", 227015, D2_LEGS },                                                               -- Greaves of The Five Thunders
        { "Finger", 16058, "Quest: In Dreams (Western Plaguelands)" },                             -- Fordring's Seal
        { "Finger", 13178, "Lower Blackrock Spire: Urok Doomhowl" },                               -- Rosewine Circle
        { "Trinket", 18471, "Quest: Frost Shock and You (Dire Maul)" },                            -- Royal Seal (Shaman)
        { "Trinket", 11832, "Blackrock Depths: Ambassador Flamelash" },                            -- Burst of Knowledge
        { "Main Hand", 13360, "Stratholme: Balnazzar" },                                           -- Gift of the Elven Magi
        { "Off Hand", 15805, "Quest: Kirtonos the Herald (Scholomance)" },                         -- Penelope's Rose
        { "Relic", 23200, "Scholomance: Lord Alexei Barov and others" },                           -- Totem of Sustaining
    },
    ["MAGE:Arcane"] = {
        { "Head", 226935, D2_HEAD },                                                               -- Sorcerer's Crown
        { "Neck", 22403, "Stratholme: Cannon Master Willey", note = "1% hit" },                    -- Nacreous Shell Necklace
        { "Shoulder", 226936, D2_LEGS },                                                           -- Sorcerer's Mantle
        { "Back", 272411, PIX75, note = "1% hit" },                                                -- Arcanoweave Cloak
        { "Chest", 226932, D2_HEAD },                                                              -- Sorcerer's Robes
        { "Wrist", 226929, D2_WRIST },                                                             -- Sorcerer's Bindings
        { "Hands", 226930, D2_HANDS, note = "1% hit" },                                            -- Sorcerer's Gauntlets
        { "Waist", 226934, D2_HANDS },                                                             -- Sorcerer's Belt
        { "Legs", 226933, D2_LEGS, note = "1% hit" },                                              -- Sorcerer's Leggings
        { "Feet", 226931, D2_LEGS },                                                               -- Sorcerer's Sandals
        { "Finger", 22339, "Upper Blackrock Spire: Lord Valthalak", note = "1% hit" },             -- Rune Band of Wizardry
        { "Finger", 12543, "Quest: The Princess's Surprise (Blackrock Depths)", 12545, "Quest: The Princess Saved? (Blackrock Depths)" }, -- Songstone of Ironforge / Eye of Orgrimmar
        { "Trinket", 13968, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Eye of the Beast
        { "Trinket", 18468, "Quest: The Arcanist's Cookbook (Dire Maul)" },                        -- Royal Seal (Mage)
        { "Two Hand", 22335, "Upper Blackrock Spire: Lord Valthalak", note = "1% hit" },           -- Lord Valthalak's Staff of Command
        { "Wand", 13938, "Scholomance: Darkmaster Gandling" },                                     -- Bonecreeper Stylus
    },
    ["MAGE:Fire"] = {
        { "Head", 22267, "Upper Blackrock Spire: General Drakkisath", note = "1% hit" },           -- Spellweaver's Turban
        { "Neck", 22403, "Stratholme: Cannon Master Willey", note = "1% hit" },                    -- Nacreous Shell Necklace
        { "Shoulder", 226936, D2_LEGS },                                                           -- Sorcerer's Mantle
        { "Back", 272411, PIX75, note = "1% hit" },                                                -- Arcanoweave Cloak
        { "Chest", 280057, "Blackmaw Hold: Impaan the Imprisoner", note = "1.8% hit" },            -- Robes of Dark Summons
        { "Wrist", 226929, D2_WRIST },                                                             -- Sorcerer's Bindings
        { "Hands", 226930, D2_HANDS, note = "1% hit" },                                            -- Sorcerer's Gauntlets
        { "Waist", 226934, D2_HANDS },                                                             -- Sorcerer's Belt
        { "Legs", 226933, D2_LEGS, note = "1% hit" },                                              -- Sorcerer's Leggings
        { "Feet", 226931, D2_LEGS },                                                               -- Sorcerer's Sandals
        { "Finger", 12543, "Quest: The Princess's Surprise (Blackrock Depths)", 12545, "Quest: The Princess Saved? (Blackrock Depths)" }, -- Songstone of Ironforge / Eye of Orgrimmar
        { "Finger", 22339, "Upper Blackrock Spire: Lord Valthalak", note = "1% hit" },             -- Rune Band of Wizardry
        { "Trinket", 13968, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Eye of the Beast
        { "Trinket", 13213, "Lower Blackrock Spire: Mother Smolderweb", note = "1% hit" },         -- Smolderweb's Eye
        { "Main Hand", 13964, "Scholomance: Darkmaster Gandling" },                                -- Witchblade
        { "Off Hand", 18316, "Dire Maul East: Pusillin" },                                         -- Obsidian Bauble
        { "Wand", 13938, "Scholomance: Darkmaster Gandling" },                                     -- Bonecreeper Stylus
    },
    ["MAGE:Frost"] = {
        { "Head", 22267, "Upper Blackrock Spire: General Drakkisath", note = "1% hit" },           -- Spellweaver's Turban
        { "Neck", 22403, "Stratholme: Cannon Master Willey", note = "1% hit" },                    -- Nacreous Shell Necklace
        { "Shoulder", 226936, D2_LEGS },                                                           -- Sorcerer's Mantle
        { "Back", 272411, PIX75, note = "1% hit" },                                                -- Arcanoweave Cloak
        { "Chest", 280057, "Blackmaw Hold: Impaan the Imprisoner", note = "1.8% hit" },            -- Robes of Dark Summons
        { "Wrist", 226929, D2_WRIST },                                                             -- Sorcerer's Bindings
        { "Hands", 226930, D2_HANDS, note = "1% hit" },                                            -- Sorcerer's Gauntlets
        { "Waist", 226934, D2_HANDS },                                                             -- Sorcerer's Belt
        { "Legs", 226933, D2_LEGS, note = "1% hit" },                                              -- Sorcerer's Leggings
        { "Feet", 226931, D2_LEGS },                                                               -- Sorcerer's Sandals
        { "Finger", 22339, "Upper Blackrock Spire: Lord Valthalak", note = "1% hit" },             -- Rune Band of Wizardry
        { "Finger", 12543, "Quest: The Princess's Surprise (Blackrock Depths)", 12545, "Quest: The Princess Saved? (Blackrock Depths)" }, -- Songstone of Ironforge / Eye of Orgrimmar
        { "Trinket", 13968, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Eye of the Beast
        { "Trinket", 12930, "Upper Blackrock Spire: Jed Runewatcher" },                            -- Briarwood Reed
        { "Main Hand", 13964, "Scholomance: Darkmaster Gandling" },                                -- Witchblade
        { "Off Hand", 11904, "Quest: It's Dangerous to Go Alone (Un'Goro Crater)" },               -- Spirit of Aquementas
        { "Wand", 19108, "Alterac Valley quest: Korrak the Bloodrager / Hero of the Stormpike / Hero of the Frostwolf" }, -- Wand of Biting Cold
    },
    ["WARLOCK:Affliction"] = {
        { "Head", 226909, D2_HEAD, note = "1% hit" },                                              -- Deathmist Mask
        { "Neck", 22403, "Stratholme: Cannon Master Willey", note = "1% hit" },                    -- Nacreous Shell Necklace
        { "Shoulder", 226912, D2_LEGS },                                                           -- Deathmist Mantle
        { "Back", 272411, PIX75, note = "1% hit" },                                                -- Arcanoweave Cloak
        { "Chest", 280057, "Blackmaw Hold: Impaan the Imprisoner", note = "1.8% hit" },            -- Robes of Dark Summons
        { "Wrist", 226907, D2_WRIST },                                                             -- Deathmist Bracers
        { "Hands", 226911, D2_HANDS, note = "1% hit" },                                            -- Deathmist Wraps
        { "Waist", 226905, D2_HANDS },                                                             -- Deathmist Belt
        { "Legs", 226910, D2_LEGS, note = "1% hit" },                                              -- Deathmist Leggings
        { "Feet", 11822, "Blackrock Depths: Golem Lord Argelmach" },                               -- Omnicast Boots
        { "Finger", 22339, "Upper Blackrock Spire: Lord Valthalak", note = "1% hit" },             -- Rune Band of Wizardry
        { "Finger", 18314, "Dire Maul East: Alzzin the Wildshaper", note = "1% hit" },             -- Ring of Demonic Guile
        { "Trinket", 13968, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Eye of the Beast
        { "Trinket", 18467, "Quest: Harnessing Shadows (Dire Maul)" },                             -- Royal Seal (Warlock)
        { "Main Hand", 18372, "Dire Maul West: Immol'thar" },                                      -- Blade of the New Moon
        { "Off Hand", 18316, "Dire Maul East: Pusillin" },                                         -- Obsidian Bauble
        { "Wand", 13396, "Stratholme: Skul (rare)" },                                              -- Skul's Ghastly Touch
    },
    ["WARLOCK:Demonology"] = {
        { "Head", 22267, "Upper Blackrock Spire: General Drakkisath", note = "1% hit" },           -- Spellweaver's Turban
        { "Neck", 22403, "Stratholme: Cannon Master Willey", note = "1% hit" },                    -- Nacreous Shell Necklace
        { "Shoulder", 226912, D2_LEGS },                                                           -- Deathmist Mantle
        { "Back", 272411, PIX75, note = "1% hit" },                                                -- Arcanoweave Cloak
        { "Chest", 280057, "Blackmaw Hold: Impaan the Imprisoner", note = "1.8% hit" },            -- Robes of Dark Summons
        { "Wrist", 226907, D2_WRIST },                                                             -- Deathmist Bracers
        { "Hands", 226911, D2_HANDS, note = "1% hit" },                                            -- Deathmist Wraps
        { "Waist", 226905, D2_HANDS },                                                             -- Deathmist Belt
        { "Legs", 226910, D2_LEGS, note = "1% hit" },                                              -- Deathmist Leggings
        { "Feet", 226908, D2_LEGS },                                                               -- Deathmist Sandals
        { "Finger", 22339, "Upper Blackrock Spire: Lord Valthalak", note = "1% hit" },             -- Rune Band of Wizardry
        { "Finger", 18314, "Dire Maul East: Alzzin the Wildshaper", note = "1% hit" },             -- Ring of Demonic Guile
        { "Trinket", 13968, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Eye of the Beast
        { "Trinket", 18467, "Quest: Harnessing Shadows (Dire Maul)" },                             -- Royal Seal (Warlock)
        { "Main Hand", 18372, "Dire Maul West: Immol'thar" },                                      -- Blade of the New Moon
        { "Off Hand", 11904, "Quest: It's Dangerous to Go Alone (Un'Goro Crater)" },               -- Spirit of Aquementas
        { "Wand", 13938, "Scholomance: Darkmaster Gandling" },                                     -- Bonecreeper Stylus
    },
    ["WARLOCK:Destruction"] = {
        { "Head", 22267, "Upper Blackrock Spire: General Drakkisath", note = "1% hit" },           -- Spellweaver's Turban
        { "Neck", 22403, "Stratholme: Cannon Master Willey", note = "1% hit" },                    -- Nacreous Shell Necklace
        { "Shoulder", 226912, D2_LEGS },                                                           -- Deathmist Mantle
        { "Back", 272411, PIX75, note = "1% hit" },                                                -- Arcanoweave Cloak
        { "Chest", 280057, "Blackmaw Hold: Impaan the Imprisoner", note = "1.8% hit" },            -- Robes of Dark Summons
        { "Wrist", 226907, D2_WRIST },                                                             -- Deathmist Bracers
        { "Hands", 226911, D2_HANDS, note = "1% hit" },                                            -- Deathmist Wraps
        { "Waist", 226905, D2_HANDS },                                                             -- Deathmist Belt
        { "Legs", 13170, "Lower Blackrock Spire: Highlord Omokk" },                                -- Skyshroud Leggings
        { "Feet", 11822, "Blackrock Depths: Golem Lord Argelmach" },                               -- Omnicast Boots
        { "Finger", 18314, "Dire Maul East: Alzzin the Wildshaper", note = "1% hit" },             -- Ring of Demonic Guile
        { "Finger", 22433, "Scholomance: Darkmaster Gandling" },                                   -- Don Mauricio's Band of Domination
        { "Trinket", 18467, "Quest: Harnessing Shadows (Dire Maul)" },                             -- Royal Seal (Warlock)
        { "Trinket", 13968, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Eye of the Beast
        { "Main Hand", 18396, "Dire Maul West: Prince Tortheldrin" },                              -- Mind Carver
        { "Off Hand", 18316, "Dire Maul East: Pusillin" },                                         -- Obsidian Bauble
        { "Wand", 13938, "Scholomance: Darkmaster Gandling" },                                     -- Bonecreeper Stylus
    },
    ["DRUID:Balance"] = {
        { "Head", 226773, D2_HEAD },                                                               -- Feralheart Cowl
        { "Neck", 22403, "Stratholme: Cannon Master Willey", note = "1% hit" },                    -- Nacreous Shell Necklace
        { "Shoulder", 226778, D2_LEGS, note = "1% hit" },                                          -- Feralheart Spaulders
        { "Back", 18350, "Dire Maul West: Magister Kalendris" },                                   -- Amplifying Cloak
        { "Chest", 226776, D2_HEAD },                                                              -- Feralheart Vest
        { "Wrist", 226775, D2_WRIST },                                                             -- Feralheart Wraps
        { "Hands", 226777, D2_HANDS },                                                             -- Feralheart Hands
        { "Waist", 11662, "Blackrock Depths: Ok'thor the Breaker", note = "1% hit" },              -- Ban'thok Sash
        { "Legs", 13170, "Lower Blackrock Spire: Highlord Omokk" },                                -- Skyshroud Leggings
        { "Feet", 226774, D2_LEGS },                                                               -- Feralheart Galoshes
        { "Finger", 22339, "Upper Blackrock Spire: Lord Valthalak", note = "1% hit" },             -- Rune Band of Wizardry
        { "Finger", 12543, "Quest: The Princess's Surprise (Blackrock Depths)", 12545, "Quest: The Princess Saved? (Blackrock Depths)" }, -- Songstone of Ironforge / Eye of Orgrimmar
        { "Trinket", 13968, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Eye of the Beast
        { "Trinket", 13213, "Lower Blackrock Spire: Mother Smolderweb", note = "1% hit" },         -- Smolderweb's Eye
        { "Main Hand", 13964, "Scholomance: Darkmaster Gandling" },                                -- Witchblade
        { "Off Hand", 18316, "Dire Maul East: Pusillin" },                                         -- Obsidian Bauble
        { "Relic", 272430, PIX50 },                                                                -- Swarming Idol
    },
    ["DRUID:Feral"] = {
        { "Head", 226792, D2_HEAD },                                                               -- Feralheart Cap
        { "Neck", 15411, "Quest: In Dreams (Western Plaguelands)" },                               -- Mark of Fordring
        { "Shoulder", 12927, "Upper Blackrock Spire: Pyroguard Emberseer", note = "1.5% hit" },    -- Truestrike Shoulders
        { "Back", 13340, "Stratholme: Baron Rivendare" },                                          -- Cape of the Black Baron
        { "Chest", 226795, D2_HEAD },                                                              -- Feralheart Tunic
        { "Wrist", 270124, "Quest: Lethtendris's Web (Dire Maul)" },                               -- Warpwood Bracers
        { "Hands", 226793, D2_HANDS },                                                             -- Feralheart Fists
        { "Waist", 226789, D2_HANDS, note = "0.7% hit" },                                          -- Feralheart Girdle
        { "Legs", 226791, D2_LEGS },                                                               -- Feralheart Trousers
        { "Feet", 226794, D2_LEGS },                                                               -- Feralheart Walkers
        { "Finger", 272408, PIX75, note = "1% hit" },                                              -- Cutthroat's Signet
        { "Finger", 22255, "Blackrock Depths: Secret Safe" },                                      -- Magma Forged Band
        { "Trinket", 13965, "Quest: For The Horde! / General Drakkisath's Demise" },               -- Blackhand's Breadth
        { "Trinket", 11815, "Blackrock Depths: Emperor Dagran Thaurissan" },                       -- Hand of Justice
        { "Two Hand", 18420, "Quest: The Treasure of the Shen'dralar (Dire Maul)" },               -- Bonecrusher
        { "Relic", 22397, "Blackrock Depths: Lord Roccor" },                                       -- Idol of Ferocity
    },
    ["DRUID:Feral Tank"] = {
        { "Head", 226801, D2_HEAD },                                                               -- Feralheart Faceguard
        { "Neck", 275736, "Quest: Work Well Done (Mount Hyjal)" },                                 -- Horn of Ve'han
        { "Shoulder", 226798, D2_LEGS },                                                           -- Feralheart Pauldrons
        { "Back", 272415, PIX75, note = "1% hit" },                                                -- Stalwart Cloak
        { "Chest", 226804, D2_HEAD },                                                              -- Feralheart Armor
        { "Wrist", 226796, D2_WRIST },                                                             -- Feralheart Wristguards
        { "Hands", 226802, D2_HANDS },                                                             -- Feralheart Grips
        { "Waist", 226797, D2_HANDS },                                                             -- Feralheart Waistguard
        { "Legs", 226799, D2_LEGS },                                                               -- Feralheart Legguards
        { "Feet", 226803, D2_LEGS },                                                               -- Feralheart Treads
        { "Finger", 260216, "Quest: Blackmaw Reclamation (Blackmaw Hold)" },                       -- Ouroboros Ring
        { "Finger", 15855, "Quest: Hidden Treasures" },                                            -- Ring of Protection
        { "Trinket", 17774, "Quest: The Pariah's Instructions (Maraudon)" },                       -- Mark of the Chosen
        { "Trinket", 11810, "Blackrock Depths: General Angerforge" },                              -- Force of Will
        { "Two Hand", 18531, "Dire Maul North: Mizzle the Crafty (tribute)" },                     -- Unyielding Maul
        { "Relic", 23198, "Stratholme: Magistrate Barthilas" },                                    -- Idol of Brutality
    },
    ["DRUID:Restoration"] = {
        { "Head", 226786, D2_HEAD },                                                               -- Feralheart Headdress
        { "Neck", 10829, "Sunken Temple: Shade of Eranikus" },                                     -- Dragon's Eye
        { "Shoulder", 226785, D2_LEGS },                                                           -- Feralheart Mantle
        { "Back", 18350, "Dire Maul West: Magister Kalendris" },                                   -- Amplifying Cloak
        { "Chest", 13346, "Stratholme: Baron Rivendare" },                                         -- Robes of the Exalted
        { "Wrist", 226782, D2_WRIST },                                                             -- Feralheart Bindings
        { "Hands", 226784, D2_HANDS },                                                             -- Feralheart Gauntlets
        { "Waist", 226780, D2_HANDS },                                                             -- Feralheart Cord
        { "Legs", 16694, "Stratholme: Baron Rivendare" },                                          -- Devout Skirt
        { "Feet", 226781, D2_LEGS },                                                               -- Feralheart Sandals
        { "Finger", 275740, "Quest: Work Well Done (Mount Hyjal)" },                               -- Ring of Nature's Cycles
        { "Finger", 284079, "Western Plaguelands: Scarlet High Clerist (rare)" },                  -- High Clerist's Seal
        { "Trinket", 1713, "World drop (BoE)" },                                                   -- Ankh of Life
        { "Trinket", 280060, "Blackmaw Hold: Bonesnout the Unbroken" },                            -- Lucky Shovelnose Tuft
        { "Main Hand", 13360, "Stratholme: Balnazzar" },                                           -- Gift of the Elven Magi
        { "Off Hand", 15805, "Quest: Kirtonos the Herald (Scholomance)" },                         -- Penelope's Rose
        { "Relic", 272429, PIX50 },                                                                -- Idol of Synthesis
    },
}

for _, g in ipairs(guides) do
    local key = g.class .. ":" .. g.spec
    g.alts = ALTS[key]
    if g.alts then g.altSource = "conquestcapped.com" end
    g.realistic = REALISTIC[key]
    if g.realistic then g.realisticSource = "conquestcapped.com" end
end

ns.RegisterPhase({
    id       = 1,
    label    = "Phase 1",
    subtitle = "Pre-raid (level 60)",
    source   = "wowtbc.gg (IDs verified vs Forever DB)",
    checked  = "2026-11-23",
    guides   = guides,
})
