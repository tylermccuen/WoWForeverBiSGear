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
