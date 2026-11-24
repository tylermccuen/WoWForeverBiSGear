import json,re
raw=json.loads(open("tools/data/quests_raw.json").read())
BOOKS={"Codex of Defense","Frost Shock and You","Harnessing Shadows","Holy Bologna: What the Light Won't Tell You","The Arcanist's Cookbook","The Light and How To Swing It"}
ZFIX={"It's Dangerous to Go Alone":"Un'Goro Crater","Saving Sharpbeak":"The Hinterlands","The Scarlet Oracle, Demetria":"Eastern Plaguelands"}
DELIANA=["Alliance","Deliana","Ironforge","58.1,29.5","58"]; MOKVAR=["Horde","Mokvar","Orgrimmar","35.0,38.3","58"]
out={}
for name,givers in raw.items():
    res=[];seen=set()
    for side,giver,zone,coords,lvl in givers:
        if name in BOOKS:
            res=[["Both","the class book (drops in Dire Maul)","Dire Maul","",lvl]];break
        zone=zone.split(" and ")[0]
        if zone=="Dun Morogh, Ironforge": zone="Ironforge"
        zone=ZFIX.get(name,zone) if not zone else zone
        giver=giver.replace("Warlord Goretooth's Command!Warlord Goretooth","Warlord Goretooth's Command (item)").replace("!"," / ")
        if giver=="No known starter": giver="TBD"
        if giver in seen: continue
        seen.add(giver); res.append([side,giver,zone,coords,lvl])
    if name in ("Saving the Best for Last","Just Compensation","An Earnest Proposition"):
        res=[DELIANA,MOKVAR]
    if name=="Anthion's Parting Words":
        res=[["Both","Anthion Harmon","Eastern Plaguelands","26.1,11.3","58"]]
    out[name]=res
def q(s): return '"'+s.replace('"','\\"')+'"'
L=["local _, ns = ...","","-- Where to pick up the quests named in the lists: name = { { side, quest giver,","-- zone, coordinates, required level }, ... } (kovarel.com WoW Forever quest","-- pages, checked 2026-11-24).","ns.Quests = {"]
for n in sorted(out):
    L.append("    [%s] = {" % q(n))
    for side,giver,zone,coords,lvl in out[n]:
        L.append("        { %s, %s, %s, %s, %s }," % (q(side),q(giver),q(zone),q(coords),q(lvl)))
    L.append("    },")
L.append("}")
open("Data/Quests.lua","w").write("\n".join(L)+"\n")
print(len(out))
