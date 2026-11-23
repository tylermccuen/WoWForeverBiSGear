# Adding a new phase

Every phase is one file in `Data\` that registers itself. Nothing else in the addon needs changing.

## Steps
1. Copy the template below to `Data\Phase2.lua` (or 3, 4, ...).
2. Fill in the lists that changed. **Specs you leave out keep using their latest earlier list**, so a phase file can start with just a few specs and grow.
3. Add the file to `ForeverBestInSlot.toc` under `Data\Phase1.lua` (there's a commented example line).
4. Add a section for the new version at the top of `CHANGELOG.md`. CurseForge shows this text as the release notes; the version number itself comes from the release tag.
5. Check the data: `lua tools/validate.lua` from the addon folder. It flags bad slots, missing IDs and duplicate specs, and shows how many items are new per spec.
6. `/reload` in game.

The newest phase automatically becomes the default in the browser and on tooltips. Players can still pick older phases from the **Phase** button. Items that weren't on a spec's previous list are marked **NEW**.

## Template
```lua
local _, ns = ...

local SRC = "https://example.com/guide/"   -- where the lists came from

local guides = {
    { class = "MAGE", spec = "Fire", url = SRC .. "mage/fire", items = {
        -- { slot, itemID, source [, hordeItemID, hordeSource] }
        { "Head",    12345, "Raid Name: Boss Name" },
        { "Trinket", 23456, "Quest: Alliance quest", 34567, "Quest: Horde quest" },
    } },
}

ns.RegisterPhase({
    id       = 2,
    label    = "Phase 2",
    subtitle = "Raid name or short description",
    source   = "Site name",
    checked  = "YYYY-MM-DD",
    guides   = guides,
})
```

**Rules**
- `class`: WARRIOR, PALADIN, HUNTER, ROGUE, PRIEST, SHAMAN, MAGE, WARLOCK, DRUID
- `spec`: must match the Phase 1 spelling (e.g. "Beast Mastery", "Restoration") so the fallback and spec menus line up
- `slot`: Head, Neck, Shoulder, Back, Chest, Wrist, Hands, Waist, Legs, Feet, Finger, Trinket, Two Hand, Main Hand, Off Hand, Ranged, Wand, Relic (Finger and Trinket can appear twice)
- Item IDs: the number in a Wowhead Forever URL, `wowhead.com/forever/item=NNNN`. Look every ID up in a Forever item database; don't reuse Classic IDs, because many crafted and reworked items have new IDs in Forever.
- Use the hand-picked lists from guide sites, not stat-weight calculators: calculators produced wrong picks such as a tank neck on hunters.
- A list is a full replacement for that spec in that phase, not a diff: include every slot.

## Alternatives
Each phase file can also give specs alternatives: other good items per slot, shown under the main pick. In `Data/Phase1.lua` they live in the `ALTS` table, keyed `"CLASS:Spec"`, using the same row format plus an optional `note = "..."`. A spec in a later phase file can set `alts = { ... }` on its guide directly.

## Asking Claude to do it
Start a new chat, attach the zipped `ForeverBestInSlot` folder, and say something like:

> Phase 2 of WoW Forever is out. Research the new BiS lists for every spec and add them to this addon as Data\Phase2.lua, following UPDATING.md. Run tools/validate.lua and send me the updated zip.

Naming the raid or a guide site you trust helps.
