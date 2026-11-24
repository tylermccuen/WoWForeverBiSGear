import json
VEND = "Vendor: Apothecary Durelle / Nina Surefire (Honored, %d Merchant's Favor)"
VENDF = "Vendor: Apothecary Durelle / Nina Surefire (Friendly, %d Merchant's Favor)"
ZG = "Vendor: Rin'wosho the Trader (Zandalar Tribe rep)"
N = {3356:"Kingsblood",3372:"Leaded Vial",6371:"Fire Oil",8845:"Ghost Mushroom",8925:"Crystal Vial",8846:"Gromsblood",13463:"Dreamfoil",13467:"Icecap",13465:"Mountain Silversage",13466:"Plaguebloom",10620:"Thorium Ore",13423:"Stonescale Oil",7068:"Elemental Fire",13468:"Black Lotus",159:"Refreshing Spring Water",13888:"Darkclaw Lobster",3358:"Khadgar's Whisker",3819:"Wintersbite",7067:"Elemental Earth",12365:"Dense Stone",3713:"Soothing Spices",20424:"Sandworm Meat",8831:"Purple Lotus",14344:"Large Brilliant Shard",18256:"Imbued Vial",4625:"Firebloom",8766:"Morning Glory Dew",3712:"Turtle Meat",12202:"Tiger Meat",8838:"Sungrass",13464:"Golden Sansam",8836:"Arthas' Tears",8839:"Blindweed",11176:"Dream Dust",13444:"Major Mana Potion",15564:"Rugged Armor Kit",248824:"Fel Hide",249429:"Pristine Scale",14341:"Rune Thread",248825:"Fel Leather",251290:"Legionite Bar",251291:"Heavy Thorium Bar"}
# id: (prof, skill, recipe, from, [(matID, count)])
C = {
 6373:("Alchemy",140,"Alchemy trainer",None,[(3356,1),(3372,1),(6371,2)]),
 9264:("Alchemy",250,"Recipe: Elixir of Shadow Power","Vendor: Maria Lumere (Stormwind) / Algernon (Undercity), limited stock",[(8845,3),(8925,1)]),
 13442:("Alchemy",255,"Recipe: Mighty Rage Potion","Drop: Blackrock Slayer (Burning Steppes)",[(8846,3),(8925,1)]),
 13444:("Alchemy",295,"Recipe: Major Mana Potion","Drop: Darkmaster Gandling (Scholomance) / Vendor: Magnus Frostwake",[(8925,1),(13463,3),(13467,2)]),
 13452:("Alchemy",280,"Recipe: Elixir of the Mongoose","Drop: Legashi / Jadefire Rogues (Azshara, Felwood)",[(8925,1),(13465,2),(13466,2)]),
 13453:("Alchemy",275,"Recipe: Elixir of Brute Force","Quest: Dadanga is Hungry! (Un'Goro Crater)",[(8846,2),(8925,1),(13466,2)]),
 13454:("Alchemy",285,"Recipe: Greater Arcane Elixir","World drop",[(8925,1),(13463,3),(13465,1)]),
 13455:("Alchemy",280,"Recipe: Greater Stoneshield Potion","World drop",[(8925,1),(10620,1),(13423,3)]),
 13457:("Alchemy",290,"Recipe: Greater Fire Protection Potion","Drop: Firebrand Invokers / Pyromancers (Blackrock Spire)",[(7068,1),(8925,1),(13463,1)]),
 13510:("Alchemy",300,"Recipe: Flask of the Titans","Drop: General Drakkisath (Upper Blackrock Spire)",[(8846,30),(8925,1),(13423,10),(13468,1)]),
 13511:("Alchemy",300,"Recipe: Flask of Distilled Wisdom","Drop: Balnazzar (Stratholme)",[(8925,1),(13463,30),(13467,10),(13468,1)]),
 13512:("Alchemy",300,"Recipe: Flask of Supreme Power","Drop: Ras Frostwhisper (Scholomance)",[(8925,1),(13463,30),(13465,10),(13468,1)]),
 13513:("Alchemy",300,"Recipe: Flask of Chromatic Resistance","Drop: Gyth (Upper Blackrock Spire)",[(8925,1),(13465,10),(13467,30),(13468,1)]),
 13933:("Cooking",275,"Recipe: Lobster Stew","Vendor: Vivianna (Feathermoon) / Sheendra Tallgrass (Camp Mojache)",[(159,1),(13888,1)]),
 17708:("Alchemy",190,"Recipe: Elixir of Frost Power","Winter Veil gift (Smokywood Pastures)",[(3358,1),(3372,1),(3819,2)]),
 18262:("Blacksmithing",300,"Plans: Elemental Sharpening Stone","Drop: Molten Core bosses",[(7067,2),(12365,3)]),
 20004:("Alchemy",290,"Recipe: Major Troll's Blood Elixir",ZG,[(8846,1),(8925,1),(13466,2)]),
 20452:("Cooking",325,"Learned from quest","Sharing the Knowledge (Silithus)",[(3713,1),(20424,1)]),
 20748:("Enchanting",300,"Formula: Brilliant Mana Oil",ZG,[(8831,3),(14344,2),(18256,1)]),
 20749:("Enchanting",300,"Formula: Brilliant Wizard Oil",ZG,[(4625,3),(14344,2),(18256,1)]),
 246948:("Alchemy",250,"Recipe: Distilled Firewater","Quest: Running Firewater",[(3372,1),(3819,4),(8846,2)]),
 249870:("Cooking",250,"Recipe: Sage's Tea","Drop: Deadwind Ogre Mage (Deadwind Pass)",[(8766,1),(13465,2)]),
 250068:("Cooking",275,"Recipe: Savory Turtle Stew","Drop: Child of Tortolla (Mount Hyjal)",[(3712,3),(3713,3)]),
 250072:("Cooking",275,"Recipe: Swiftstrike Steak","Drop: Frostsaber Pride Watcher (Winterspring)",[(3713,2),(12202,3)]),
 250329:("Alchemy",250,"Recipe: Elixir of the Phalanx",VEND%180,[(8838,4),(8925,1),(13464,2)]),
 250333:("Alchemy",195,"Recipe: Greater Cleric's Elixir",VENDF%120,[(8831,1),(8836,3),(8925,1)]),
 250337:("Alchemy",280,"Recipe: Elixir of the Owl",VEND%180,[(13463,4),(13465,2),(18256,1)]),
 250341:("Alchemy",175,"Recipe: Greater Mageblood Elixir",VENDF%120,[(8836,2),(8839,3),(8925,1)]),
 250343:("Alchemy",285,"Recipe: Elixir of Nature Power",VEND%180,[(8838,2),(8925,1),(13464,4)]),
 250351:("Alchemy",300,"Recipe: Elixir of the Grizzly",VEND%240,[(8839,1),(8846,3),(8925,1)]),
 250937:("Alchemy",285,"Recipe: Major Spellblasting Potion",VEND%180,[(13463,2),(13465,1),(18256,1)]),
 250943:("Alchemy",290,"Recipe: Major Frenzy Potion",VEND%240,[(8839,2),(13466,3),(18256,1)]),
 250949:("Alchemy",280,"Recipe: Major Mender's Potion",VEND%180,[(8838,1),(13463,3),(18256,1)]),
 252487:("Leatherworking",235,"Pattern: Mystic Rugged Armor Kit","Vendor: Pawani / Daniel Stitchsong (Honored, 90 Merchant's Favor)",[(11176,2),(13444,2),(15564,1),(248824,1),(249429,1)]),
 279258:("Leatherworking",300,"Pattern: Wild Leather Armor Kit",None,[(14341,3),(248825,22)]),
 279272:("Engineering",300,"Schematic: SAF-T Ultra Precision Scope",None,[(251290,1),(251291,12)]),
}
DROPS = { 20520:"Drop: Scholomance mobs / Auction House" }
SPELL_ITEM = {1249057:273631,1249019:273630,1249059:273633,1249058:273632,1219587:273604,20015:273552,20025:273558,20028:273560,1220624:273606,20010:273547,1248599:273620,20011:273548,23802:273575,20009:273546,20013:273550,20012:273549,20023:273556,20024:273557,1248805:273629,20034:273566,27837:273589,23800:273573,1248757:273627,23803:273576,1219579:273600,1219581:273602}
# Classic formulas (Wowhead WoW Forever: spell -> taught by item -> source)
ENCH_SRC = {
 20009:("Formula: Enchant Bracer - Superior Spirit","World drop (Stranglethorn Vale, The Hinterlands) and chests"),
 20010:("Formula: Enchant Bracer - Superior Strength","Drop: Deadwind Warlock (Deadwind Pass)"),
 20011:("Formula: Enchant Bracer - Superior Stamina","World drop (Western Plaguelands) and chests"),
 20012:("Formula: Enchant Gloves - Greater Agility","Drop: Legashi Rogue / Blackguard (Azshara)"),
 20013:("Formula: Enchant Gloves - Greater Strength","Drop: Spirestone Mystic (Lower Blackrock Spire)"),
 20015:("Formula: Enchant Cloak - Superior Defense","Vendor: Lorelae Wintersong (Moonglade) / Drop: Gordok Mage-Lord (Dire Maul)"),
 20023:("Formula: Enchant Boots - Greater Agility","World drop (Western Plaguelands, The Hinterlands, Sunken Temple) and chests"),
 20024:("Formula: Enchant Boots - Spirit","World drop (Western Plaguelands, Stranglethorn Vale) and chests"),
 20025:("Formula: Enchant Chest - Greater Stats","Drop: Blackhand Assassin (Blackrock Spire), Scholomance Adept, Gordok Mage-Lord (Dire Maul)"),
 20028:("Formula: Enchant Chest - Major Intellect","Drop: Scarlet Enchanter (Eastern Plaguelands)"),
 20034:("Formula: Enchant Weapon - Crusader","Drop: Scarlet Spellbinder (Western Plaguelands)"),
 23800:("Formula: Enchant Weapon - Agility","Vendor: Meilosh (Felwood, Timbermaw Hold rep)"),
 23802:("Formula: Enchant Bracer - Healing","Vendor: Argent Dawn quartermasters (Argent Dawn rep)"),
 23803:("Formula: Enchant Weapon - Mighty Spirit","Vendor: Lokhtos Darkbargainer (Blackrock Depths, Thorium Brotherhood rep)"),
 27837:("Formula: Enchant 2H Weapon - Agility","Vendor: Meilosh (Felwood, Timbermaw Hold rep)"),
 1248599:("Formula: Enchant Bracer - Superior Agility","Drop: Thuzadin Acolyte (Stratholme)"),
 1248757:("Formula: Enchant Weapon - Insight","Vendor: Beneris / Alynsia (45 Merchant's Favor)"),
 1248805:("Formula: Enchant Weapon - Revelation","Vendor: Beneris / Alynsia (45 Merchant's Favor)"),
 1249019:("Formula: Enchant Necklace - Strength","Vendor: Beneris / Alynsia (120 Merchant's Favor)"),
 1249057:("Formula: Enchant Necklace - Spell Power","Vendor: Beneris / Alynsia (120 Merchant's Favor)"),
 1249058:("Formula: Enchant Necklace - Healing Power","Vendor: Beneris / Alynsia (120 Merchant's Favor)"),
 1249059:("Formula: Enchant Necklace - Agility","Vendor: Beneris / Alynsia (120 Merchant's Favor)"),
}
sp = json.load(open("tools/data/spells.json"))
for sid, v in sp.items():
    item = SPELL_ITEM[int(sid)]
    mats = []
    for mid, (nm, cnt) in v["r"].items():
        N[int(mid)] = nm; mats.append((int(mid), cnt))
    f, src = v.get("f"), v.get("src")
    if not f and int(sid) in ENCH_SRC: f, src = ENCH_SRC[int(sid)]
    C[item] = ("Enchanting", int(v["s"]), f, src, sorted(mats, key=lambda m: -m[1]))
def q(s): return '"' + s.replace('"','\\"') + '"'
L = ["local _, ns = ...", "",
     "-- How consumables and enchants are made: profession, skill, recipe, where",
     "-- the recipe comes from, and the materials (kovarel.com and wowhead.com WoW Forever item and",
     "-- spell pages, checked 2026-11-24). Phase independent.", "ns.Crafting = {"]
for i in sorted(C):
    prof, skill, rec, frm, mats = C[i]
    parts = ["prof = %s" % q(prof), "skill = %d" % skill]
    if rec: parts.append("recipe = %s" % q(rec))
    if frm: parts.append("from = %s" % q(frm))
    m = ", ".join("{ %d, %d, %s }" % (mid, cnt, q(N[mid])) for mid, cnt in mats)
    L.append("    [%d] = { %s,\n        mats = { %s } }," % (i, ", ".join(parts), m))
for i, frm in DROPS.items():
    L.append("    [%d] = { from = %s }," % (i, q(frm)))
L.append("}")
open("Data/Crafting.lua","w").write("\n".join(L)+"\n")
print(len(C), "crafted entries")
