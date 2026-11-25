local _, ns = ...

-- Where to pick up the quests named in the lists: name = { { side, quest giver,
-- zone, coordinates, required level }, ... } (kovarel.com WoW Forever quest
-- pages, checked 2026-11-24).
ns.Quests = {
    ["An Earnest Proposition"] = {
        { "Alliance", "Deliana", "Ironforge", "58.1,29.5", "58" },
        { "Horde", "Mokvar", "Orgrimmar", "35.0,38.3", "58" },
    },
    ["Anthion's Parting Words"] = {
        { "Both", "Anthion Harmon", "Eastern Plaguelands", "26.1,11.3", "58" },
    },
    ["Aurius' Reckoning"] = {
        { "Both", "Aurius", "Stratholme", "", "55" },
    },
    ["Blackmaw Reclamation"] = {
        { "Both", "Gatekeeper Rageroar", "Azshara", "42.3,20.1", "47" },
    },
    ["Codex of Defense"] = {
        { "Both", "the class book (drops in any Dire Maul wing; turn in to Lorekeeper Lydros, West)", "Dire Maul", "", "54" },
    },
    ["Corruption of Earth and Seed"] = {
        { "Horde", "Selendra", "Desolace", "26.9,77.7", "45" },
        { "Alliance", "Keeper Marandis", "Desolace", "63.8,10.7", "45" },
    },
    ["For The Horde!"] = {
        { "Horde", "Thrall", "Orgrimmar", "31.7,37.8", "55" },
    },
    ["Frost Shock and You"] = {
        { "Both", "the class book (drops in any Dire Maul wing; turn in to Lorekeeper Lydros, West)", "Dire Maul", "", "54" },
    },
    ["General Drakkisath's Demise"] = {
        { "Alliance", "Marshal Maxwell", "Burning Steppes", "84.7,69.0", "55" },
    },
    ["Greater Friend of the Library"] = {
        { "Both", "Owen Thadd / Garion Wendell", "Stormwind City, Undercity", "", "20" },
        { "Both", "Jennea Cannon", "Stormwind City", "49.6,85.8", "50" },
    },
    ["Harnessing Shadows"] = {
        { "Both", "the class book (drops in any Dire Maul wing; turn in to Lorekeeper Lydros, West)", "Dire Maul", "", "54" },
    },
    ["Hero of the Frostwolf"] = {
        { "Horde", "Voggah Deathgrip", "Alterac Mountains", "63.8,60.5", "58" },
    },
    ["Hero of the Stormpike"] = {
        { "Alliance", "Prospector Stonehewer", "Alterac Mountains, Alterac Valley", "40.6,79.6", "58" },
    },
    ["Hidden Treasures"] = {
        { "Both", "Pamela Redpath", "Eastern Plaguelands", "31.1,78.0", "50" },
    },
    ["Holy Bologna: What the Light Won't Tell You"] = {
        { "Both", "the class book (drops in any Dire Maul wing; turn in to Lorekeeper Lydros, West)", "Dire Maul", "", "54" },
    },
    ["In Dreams"] = {
        { "Both", "Highlord Taelan Fordring", "Western Plaguelands", "42.0,14.8", "52" },
    },
    ["It's Dangerous to Go Alone"] = {
        { "Both", "Linken", "Un'Goro Crater", "44.7,8.1", "47" },
    },
    ["Job Opening: Guard Captain of Revantusk Village"] = {
        { "Horde", "TBD", "", "", "46" },
    },
    ["Just Compensation"] = {
        { "Alliance", "Deliana", "Ironforge", "58.1,29.5", "58" },
        { "Horde", "Mokvar", "Orgrimmar", "35.0,38.3", "58" },
    },
    ["Kirtonos the Herald"] = {
        { "Both", "Eva Sarkhoff", "Western Plaguelands", "70.2,73.7", "55" },
    },
    ["Korrak the Bloodrager"] = {
        { "Alliance", "TBD", "", "", "51" },
    },
    ["Lethtendris's Web"] = {
        { "Alliance", "Latronicus Moonspear", "Feralas", "30.4,46.2", "54" },
        { "Horde", "Talo Thornhoof", "Feralas", "76.2,43.8", "54" },
    },
    ["Libram of Focus"] = {
        { "Both", "Lorekeeper Lydros", "Dire Maul West", "", "54" },
    },
    ["Libram of Voracity"] = {
        { "Both", "Mathredis Firestar", "Burning Steppes", "65.0,23.6", "50" },
    },
    ["Mapping the Way Forward"] = {
        { "Alliance", "Curator Thorius", "Ironforge", "71.5,15.7", "55" },
    },
    ["Maxwell's Mission"] = {
        { "Alliance", "Marshal Maxwell", "Burning Steppes", "84.7,69.0", "55" },
    },
    ["Running Firewater"] = {
        { "Both", "TBD", "Azshara", "", "47" },
    },
    ["Saving Sharpbeak"] = {
        { "Alliance", "Gryphon Master Talonaxe", "The Hinterlands", "9.8,44.5", "40" },
    },
    ["Saving the Best for Last"] = {
        { "Alliance", "Deliana", "Ironforge", "58.1,29.5", "58" },
        { "Horde", "Mokvar", "Orgrimmar", "35.0,38.3", "58" },
    },
    ["Sharing the Knowledge"] = {
        { "Both", "TBD", "Silithus", "", "54" },
    },
    ["The Arcanist's Cookbook"] = {
        { "Both", "the class book (drops in any Dire Maul wing; turn in to Lorekeeper Lydros, West)", "Dire Maul", "", "54" },
    },
    ["The Dark Crystal"] = {
        { "Horde", "Master Apothecary Faranell", "Undercity", "48.8,69.3", "55" },
    },
    ["The Lich, Ras Frostwhisper"] = {
        { "Both", "Magistrate Marduke", "Western Plaguelands", "70.6,74.1", "57" },
    },
    ["The Light and How To Swing It"] = {
        { "Both", "the class book (drops in any Dire Maul wing; turn in to Lorekeeper Lydros, West)", "Dire Maul", "", "54" },
    },
    ["The Pariah's Instructions"] = {
        { "Both", "Centaur Pariah", "Desolace", "50.4,86.7", "39" },
    },
    ["The Princess Saved?"] = {
        { "Horde", "Princess Moira Bronzebeard", "Blackrock Depths", "", "48" },
    },
    ["The Princess's Surprise"] = {
        { "Alliance", "Princess Moira Bronzebeard", "Blackrock Depths", "", "50" },
    },
    ["The Scarlet Oracle, Demetria"] = {
        { "Horde", "Nathanos Blightcaller", "Eastern Plaguelands", "22.2,63.5", "56" },
    },
    ["The Treasure of the Shen'dralar"] = {
        { "Alliance", "Shen'dralar Ancient", "Dire Maul West", "", "56" },
    },
    ["Voodoo Feathers"] = {
        { "Both", "Fallen Hero of the Horde", "Swamp of Sorrows", "34.3,66.1", "50" },
    },
    ["Warlord's Command"] = {
        { "Horde", "Warlord Goretooth's Command (item)", "Badlands", "", "55" },
    },
    ["Work Well Done"] = {
        { "Both", "Tiala Whitemane", "Mount Hyjal", "68.8,50.6", "54" },
    },
}
