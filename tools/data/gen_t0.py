import json,re,sys
t0=json.load(open("tools/data/t0.json"))
m=json.load(open("tools/data/namemap.json")); inv={}
for k,v in m.items(): inv.setdefault(v,k)
DUNGEON={"Scholomance":["Darkmaster Gandling","Ras Frostwhisper","Rattlegore","Doctor Theolen Krastinov","Instructor Malicia","Kirtonos the Herald","Lord Alexei Barov","Lady Illucia Barov","Jandice Barov","The Ravenian","Lorekeeper Polkelt","Vectus","Marduk Blackpool"],
"Stratholme":["Baron Rivendare","Nerub'enkan","Cannon Master Willey","Hearthsinger Forresten","Maleki the Pallid","Archivist Galford","Balnazzar","Magistrate Barthilas","Ramstein the Gorger","Baroness Anastari","Timmy the Cruel","Postmaster Malown","Stonespine","Skul","The Unforgiven","Grand Crusader Dathrohan"],
"Upper Blackrock Spire":["General Drakkisath","Solakar Flamewreath","The Beast","Gyth","Pyroguard Emberseer","Warchief Rend Blackhand","Jed Runewatcher","Goraluk Anvilcrack"],
"Lower Blackrock Spire":["War Master Voone","Overlord Wyrmthalak","Shadow Hunter Vosh'gajin","Mother Smolderweb","Highlord Omokk","Halycon","Gizrul the Slavener","Urok Doomhowl","Quartermaster Zigris","Spirestone Butcher","Bannok Grimaxe","Crystal Fang","Ghok Bashguud","Burning Felguard"],
"Blackrock Depths":["Emperor Dagran Thaurissan","Ambassador Flamelash","Lord Incendius","Golem Lord Argelmach","General Angerforge","Fineous Darkvire","Lord Roccor","Bael'Gar","Warder Stilgiss","Magmus","Hurley Blackbreath","Phalanx","Pyromancer Loregrain","Houndmaster Grebmar","Princess Moira Bronzebeard"],
"Dire Maul":["Prince Tortheldrin","Immol'thar","King Gordok","Alzzin the Wildshaper","Zevrim Thornhoof","Hydrospawn","Illyanna Ravenoak","Magister Kalendris","Tendris Warpwood","Lethtendris","Captain Kromcrush","Guard Fengus","Guard Slip'kik","Guard Mol'dar","Cho'Rush the Observer","Stomper Kreeg","Pusillin"]}
B2D={b:d for d,bs in DUNGEON.items() for b in bs}
SLOTW=[("Head",r"Cap|Crown|Mask|Cowl|Helm|Coif|Circlet|Headdress"),("Shoulder",r"Mantle|Spaulders|Pauldrons|Epaulets|Shoulders"),("Chest",r"Tunic|Robe|Vest|Breastplate|Chestpiece|Chestguard|Hauberk"),("Wrist",r"Bindings|Bracers|Wristguards|Bracelets"),("Hands",r"Gloves|Gauntlets|Handguards|Grips|Wraps"),("Waist",r"Belt|Girdle|Cord|Waistguard|Sash"),("Legs",r"Pants|Leggings|Skirt|Kilt|Legplates|Legguards"),("Feet",r"Boots|Sandals|Sabatons|Greaves|Treads|Footpads")]
def slot(n):
    for s,rx in SLOTW:
        if re.search(rx,n): return s
def source(txt):
    txt=txt.replace("Direct acquisitionSourceChance","").replace("Direct acquisitionSourceDetails","").replace(" / Details","")
    if txt.startswith("Trash"):
        return "Random trash drop (Stratholme, Scholomance, Blackrock Spire)"
    mm=re.match(r"(.+?)Dungeon",txt)
    if mm:
        b=mm.group(1).strip(); d=B2D.get(b)
        if not d: print("UNKNOWN BOSS",b,file=sys.stderr); d="Dungeon"
        return d+": "+b+(" (or Madam Swyndle, vendor)" if "Madam Swyndle" in txt else "")
    print("UNPARSED",txt,file=sys.stderr); return "Dungeon drop"
FAM={"Beastmaster":"Beaststalker","Darkmantle":"Shadowcraft","Virtuous":"Devout","Sorcerer's":"Magister's","Deathmist":"Dreadmist","Feralheart":"Wildheart","Five Thunders":"Elements","Soulforge":"Lightforge","Heroism":"Valor"}
t0by={}
for i,(n,_,src,q) in t0.items():
    fam=next((f for f in FAM.values() if f in n),None); s=slot(n)
    if not fam or not s: continue
    t0by[(fam,s)]=(int(i),n,source(src))
data=open("Data/Phase1.lua").read()
rows=re.findall(r'\{\s*"(\w[\w ]*)"\s*,\s*(\d+)\s*,',data)
out={}
for s,i in rows:
    n=inv.get(int(i),"")
    fam=next((v for k,v in FAM.items() if k in n),None)
    if not fam: continue
    t=t0by.get((fam,s))
    if not t: print("NO T0 FOR",i,n,s,file=sys.stderr); continue
    out[int(i)]=(t,n)
L=["-- Tier 0.5 piece -> the Tier 0 piece its quest needs (kovarel.com)","local TIER0 = {"]
for i,(t,n) in sorted(out.items()):
    L.append('    [%d] = { %d, "%s" },%s-- %s -> %s' % (i,t[0],t[2]," "*max(1,44-len(t[2])),n,t[1]))
L.append("}")
open("tools/data/tier0.lua","w").write("\n".join(L)+"\n"); print(len(out),"mapped")
