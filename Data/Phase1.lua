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
-- Songstone of Ironforge comes from an Alliance-only quest; Horde gets Rune Band of Wizardry
local SONGSTONE   = { "Finger",  12543,  "Quest: The Princess's Surprise (Alliance only)", 22339, "Upper Blackrock Spire: Lord Valthalak" }

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
local CC = "https://conquestcapped.com/guides/wow-forever/"
local ALTS = {
    ["HUNTER:Marksmanship"] = {
        { "Back",  272414, PIX75, note = "1% hit" },
        { "Wrist", 18375,  "Dire Maul West: Prince Tortheldrin" },
    },
    ["HUNTER:Survival"] = {
        { "Back",  272414, PIX75, note = "1% hit" },
        { "Feet",  13967,  "Scholomance: Kirtonos the Herald", note = "1% hit" },
    },
    ["WARRIOR:Fury"] = {
        CUTTHROAT,
        { "Main Hand", 11684, "Blackrock Depths: Emperor Dagran Thaurissan" },
        { "Ranged",    18323, "Dire Maul: Zevrim Thornhoof", note = "1% hit" },
    },
}
for _, g in ipairs(guides) do
    g.alts = ALTS[g.class .. ":" .. g.spec]
    if g.alts then g.altSource = "conquestcapped.com" end
end

ns.RegisterPhase({
    id       = 1,
    label    = "Phase 1",
    subtitle = "Pre-raid (level 60)",
    source   = "wowtbc.gg (IDs verified vs Forever DB)",
    checked  = "2026-11-23",
    guides   = guides,
})
