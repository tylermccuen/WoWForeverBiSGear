local _, ns = ...

--[[
    Hunter pets for raids and dungeons (WoW Forever, level 60).
    Sources (checked 2026-11-25): playhub.com hunter pet tier list,
    warcrafttavern.com best hunter pets, exitlag.com Forever pets.
    In Forever every family has its own ability and pets inherit part of the
    hunter's stats; damage is normalized by attack speed within a family.
    Guides don't agree on every pick yet (little level 60 raid testing),
    so each spec lists a main pick and alternatives.
]]

ns.PetFamilies = {
    -- family = { tier, ability, what it does }
    Cat          = { "S", "Prowl", "Top single-target damage; strongest pick for boss fights" },
    Wolf         = { "S", "Furious Howl", "Party and raid members within 15 yards get +84 melee attack power for 1 minute (rank 4)" },
    Bear         = { "S", "Swipe", "Hits up to 3 enemies; tough and easy for dungeon packs" },
    Spider       = { "S", "Web", "Roots a target for 4 sec from 20 yards (40 sec cooldown)" },
    Raptor       = { "A", "Savage Rend", "Bleed damage; close to Cat for bosses" },
    ["Carrion Bird"] = { "A", "Demoralizing Screech", "Lowers nearby enemies' melee attack power" },
    Crocolisk    = { "A", "Dismember", "Target receives 25% less healing" },
    ["Wind Serpent"] = { "A", "Lightning Breath", "Ranged nature attack from 20 yards" },
    Tallstrider  = { "B", "Dust Cloud", "Removes 505 armor from the target for 30 sec (max rank)" },
}

-- per spec: best first; "lone" = the talent that plays without a pet
ns.HunterPets = {
    ["Beast Mastery"] = {
        picks = { "Cat", "Raptor" },
        why = "Your pet does a big share of your damage, so bring the hardest-hitting family. Cat and Raptor are close; keep a Raptor if it's already leveled.",
        also = "Bear for dungeon packs (Swipe).",
    },
    ["Marksmanship"] = {
        picks = { "Wolf", "Tallstrider" },
        lone = true,
        why = "Many Marksmanship hunters raid with the Lone Wolf talent and no pet. If you bring one, a Wolf's Furious Howl helps when melee stand near it; a Tallstrider's Dust Cloud lowers the boss's armor.",
        also = "Cat if you just want pet damage.",
    },
    ["Survival"] = {
        picks = { "Wolf", "Raptor" },
        why = "You fight in melee range, so Furious Howl reaches the melee group as well as you.",
        also = "Cat on a two-handed build, or when you're the only melee that would get Howl.",
    },
}

-- named beasts worth taming for raids (level, where, what it teaches)
ns.PetTames = {
    { family = "Wolf", name = "Bloodaxe Worg", level = "56-57", zone = "Lower Blackrock Spire",
      note = "Teaches Furious Howl rank 4 (the raid rank)." },
}

-- Best rank of each pet skill known in WoW Forever, and where to learn it.
-- Wild beasts teach Bite, Claw, Dash, Dive and family skills (tame one, let it
-- teach you, then use Beast Training on your pet); a Pet Trainer sells the
-- rest. Forever changed the beasts, so these are the highest ranks players
-- have documented so far (guided.news, conquestcapped.com, playhub.com,
-- checked 2026-11-25); higher ranks may turn up on level 56+ beasts.
-- from = { name, level, zone, "x, y" or nil }
ns.PetBestRank = {
    ["Bite"]  = { rank = 7, from = { { "Uhk'loc", "52-53 gorilla", "Un'Goro Crater", "68.4, 14.4" },
                                     { "Sewer Beast", "50 crocolisk", "Stormwind City", "48.8, 50.2" },
                                     { "Ironback", "51 turtle", "The Hinterlands" } } },
    ["Claw"]  = { rank = 7, from = { { "Mongress", "50 bear", "Felwood", "43.4, 77.6" },
                                     { "Olm the Wise", "52 bird of prey", "Felwood", "58.4, 18.4" },
                                     { "Clack the Reaver", "53 scorpid", "Blasted Lands", "53.2, 36.0" } } },
    ["Dash"]  = { rank = 3, from = { { "Rak'shiri", "57 cat", "Winterspring", "52.0, 14.0" },
                                     { "Grunter", "50 boar", "Blasted Lands", "57.8, 28.0" } } },
    ["Dive"]  = { rank = 3, from = { { "Zaricotl", "55-56 carrion bird", "Badlands", "39.8, 55.8" },
                                     { "Spiteflayer", "52 carrion bird", "Blasted Lands", "59.4, 39.4" } } },
    ["Furious Howl"]     = { rank = 4, from = { { "Bloodaxe Worg", "56-57 wolf", "Lower Blackrock Spire" } } },
    ["Lightning Breath"] = { rank = 5, from = { { "Arash-ethis", "49 wind serpent", "Feralas" } } },
    ["Scorpid Poison"]   = { rank = 4, from = { { "Krellack", "56 scorpid", "Silithus" } } },
    ["Charge"]           = { rank = 5, from = { { "Grunter", "50 boar", "Blasted Lands", "57.8, 28.0" } } },
    -- bought from a Pet Trainer (next to the hunter trainer in each capital)
    ["Growl"]             = { rank = 7, trainer = true },
    ["Great Stamina"]     = { rank = 10, trainer = true },
    ["Natural Armor"]     = { rank = 10, trainer = true },
    ["Arcane Resistance"] = { rank = 4, trainer = true },
    ["Fire Resistance"]   = { rank = 4, trainer = true },
    ["Frost Resistance"]  = { rank = 4, trainer = true },
    ["Nature Resistance"] = { rank = 4, trainer = true },
    ["Shadow Resistance"] = { rank = 4, trainer = true },
}

-- Families that learn Claw (every other family learns Bite instead)
ns.ClawFamilies = { Bear = true, ["Bird of Prey"] = true, ["Carrion Bird"] = true, Cat = true, Crab = true, Raptor = true, Scorpid = true }
ns.BiteFamilies = { Bat = true, Bear = true, Boar = true, ["Carrion Bird"] = true, Cat = true, Crocolisk = true, Fox = true,
                    Gorilla = true, Hyena = true, Raptor = true, Spider = true, Tallstrider = true, Turtle = true,
                    ["Wind Serpent"] = true, Wolf = true }

-- Training point costs (Classic, which Forever kept: 300 points at level 60
-- with Best Friend loyalty). Growl costs nothing.
ns.PetTrainCost = {
    ["Bite"] = { [8] = 25 }, ["Claw"] = { [8] = 25 },
    ["Great Stamina"] = { [10] = 185 },
    ["Natural Armor"] = { [6] = 50, [10] = 150 },
    ["Resistance"] = { [3] = 45, [4] = 90 },
}


-- The raid training plan for 300 points (shown on the Pet tab)
ns.PetRaidTraining = {
    "Bite and/or Claw (whichever its family learns) at the best rank you can find: most of your pet's damage. Rank 7 is the best known in Forever so far (about 21 points each).",
    "Great Stamina rank 10 (185 points): raid damage hits pets hard, and more health keeps it attacking.",
    "That leaves about 70 of 300. Spend it on its family skill (e.g. Furious Howl rank 4 for a Wolf), then a resistance for fights that need one, or Natural Armor rank 6 (50 points).",
    "Natural Armor matters less in raids, where your pet isn't tanking; don't max it before Great Stamina.",
    "Growl is free: keep it, but turn off its auto-cast in raids so your pet doesn't pull threat from the tank.",
    "Wrong points spent? A Pet Trainer can unlearn your pet's skills for a small fee.",
    "Keep it Happy (fed): you can't feed it in combat, and an unhappy pet does less damage.",
}
