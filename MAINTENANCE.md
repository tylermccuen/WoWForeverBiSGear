# Forever Best In Slot: maintenance checklist

Everything that has to be checked or redone to keep the addon current, what triggers it, and how to do it. Last reviewed: 2026-11-24 (version 1.7.3).

Repository: https://github.com/tylermccuen/WoWForeverBiSGear (CurseForge project "WoW Forever BiS Gear", built automatically from GitHub releases).

---

## 0. WoW Forever roadmap (what's coming and when)

From Blizzard's roadmap (BlizzCon 2026), as summarized by icy-veins.com/wow-forever/roadmap. Recheck it whenever an update is announced; dates after December 2026 are seasons, not exact days.

| When | What | What the addon needs |
|---|---|---|
| Nov 4, 2026 (live) | Launch, level 60, dungeons | **Pre-raid** lists (`Data/Phase1.lua`, phase id 1). This is what the addon ships now. |
| **Dec 9, 2026** | Raids open: Barrow Deeps (10), Hyjal Summit (20), Onyxia's Lair (40) | First raid phase: fill `guides` in `Data/Phase2.lua` (already in the addon, hidden until it has a list; shows as "Phase 1"); research so far in `tools/data/phase1_research.md`; raid bosses in `Bosses.lua`; drop rates; raid check may need raid-specific targets. |
| Winter 2026 | Hardcore servers | Probably nothing (same items). Check whether the client reports a different interface number. |
| Spring 2027 | 2 new raids (10 and 20), 2 new dungeons, 2 new class/race combos, new quests and zone, PvP refresh | New phase file; new class/spec combos may need new specs in the lists; new dungeon bosses; new quest givers. |
| Summer 2027 | Revamped iconic raid, a new raid, 2 new dungeons, profession and legacy updates, PvP refresh | New phase file; recheck `Crafting.lua` (recipes / skill caps may change). |

Naming: the phase on screen is called **Pre-raid** (its internal id stays 1 so saved settings keep working). Raid phases get labels like "Phase 1" (Dec 9 raids), "Phase 2" (spring), etc.

---

## 1. What data the addon carries and where it comes from

| Data | File | Source | How it's made |
|---|---|---|---|
| BiS lists (main picks) | `Data/Phase1.lua` (`guides`) | wowtbc.gg Forever BiS pages | Hand-entered; IDs checked on kovarel.com |
| Alternatives | `Data/Phase1.lua` (`ALTS`) | conquestcapped.com spec guides | Hand-entered |
| Realistic sets | `Data/Phase1.lua` (`REALISTIC`) | conquestcapped.com "Realistic" tab | Generated, then pasted in |
| Hunter quiver / ammo | `Data/Phase1.lua` (`HUNTER_AMMO`) | conquestcapped.com hunter guides | Hand-entered |
| Enchants per spec | `Data/Phase1.lua` (`ENCHANTS`) | wowtbc.gg page data (`/page-data/warcraftforever/bis-list/<spec>/page-data.json`, `pre-raid.enchants`) | `tools/data/gen_enchants.py` |
| Tier 0 pieces for Tier 0.5 quests | `Data/Phase1.lua` (`TIER0`) | kovarel.com item pages | `tools/data/gen_t0.py` |
| Consumables per role | `Data/Phase1.lua` (`C`, `CONSUME_PROFILE`) | rankedboost.com Forever consumables guide | Hand-entered |
| Recipes, skill, materials, recipe source | `Data/Crafting.lua` | kovarel.com item + spell pages, wowhead.com/forever | `tools/data/gen_crafting.py` |
| Drop chances | `Data/DropRates.lua` | kovarel.com item pages (Sources list) | Generated from `tools/data/drops.json` |
| Bosses (NPC ID, model ID, dungeon) | `Data/Bosses.lua` | kovarel.com (NPC IDs), wowhead.com/forever (model IDs) | `tools/data/gen_bosses.py` |
| Quest givers | `Data/Quests.lua` | kovarel.com quest pages | `tools/data/gen_quests.py` |
| Hit / defense targets | `Raid.lua` (`ns.RaidTargets`) | conquestcapped.com hit cap guide; warcrafttavern.com (defense) | Hand-entered |

Run the generators from the repo root, e.g. `python3 tools/data/gen_crafting.py`.

---

## 2. Triggers and what to do

### A. A new phase comes out (new raid / new BiS lists)
- [ ] Create `Data/Phase2.lua` following `UPDATING.md` (BiS lists for all 28 specs, from wowtbc.gg or the guide the player trusts).
- [ ] Look up every item ID in kovarel.com or wowhead.com/forever. **Never reuse Classic IDs blindly**: crafted and reworked items have new Forever IDs.
- [ ] Alternatives and Realistic sets for the new phase (conquestcapped.com), if the guides have them.
- [ ] Enchants: re-pull wowtbc.gg page data; new phases often bring new enchants (`gen_enchants.py`), then verify the enchant item IDs on kovarel.
- [ ] Consumables: re-check the rankedboost.com consumables guide for new flasks / elixirs / food.
- [ ] New raid bosses: add them to `tools/data/gen_bosses.py` (NPC ID from kovarel, model ID from Wowhead), regenerate `Data/Bosses.lua`.
- [ ] Drop chances for the new items (kovarel item pages → `drops.json` → `Data/DropRates.lua`).
- [ ] Quest givers for any new quest sources (`gen_quests.py`).
- [ ] New recipes / materials (`gen_crafting.py`).
- [ ] Raid targets: does the new raid change the hit cap or defense needed? (`Raid.lua`)
- [ ] Add the file to `ForeverBestInSlot.toc`, then run the checks in section 3.

### B. A Forever patch changes items, recipes or vendors
- [ ] Read the patch notes for item, recipe, reputation-vendor and enchant changes.
- [ ] Re-verify any changed item IDs on kovarel.com (kovarel has an "Item Changes" page).
- [ ] Re-run the crafting lookup for changed recipes; Forever has already changed reagents for some (e.g. Flask of the Titans).
- [ ] Merchant's Favor vendors (Apothecary Durelle / Nina Surefire, Beneris / Alynsia, Pawani / Daniel Stitchsong): check prices and reputation levels.
- [ ] Bump `checked = "YYYY-MM-DD"` in the phase file.

### C. Guide sites update their lists
- [ ] wowtbc.gg: compare each spec's `pre-raid.gear` and `pre-raid.enchants` (page-data JSON) with `Data/Phase1.lua`.
- [ ] conquestcapped.com: compare Realistic tabs and alternatives.
- [ ] Update, re-verify IDs, run the checks.

### D. Hit / defense numbers change
- [ ] Check the character panel's **Hit Chance** tooltip in game: it shows the raid-boss caps directly. Update `ns.RaidTargets` in `Raid.lua` if they differ.
- [ ] Re-read conquestcapped.com's hit cap guide.

### E. Client / API changes (new Forever client build)
- [ ] Test in game: browser opens, tooltips, raid check panel, compact mode beside the character window, boss models, quest hover.
- [ ] If something breaks, check the API calls used: `TooltipDataProcessor`, `C_TooltipInfo.GetInventoryItem`, `GetHitModifier` / `GetCombatRatingBonus`, `C_Container`, `C_QuestLog`, `PlayerModel:SetDisplayInfo / SetCreature`, `PanelTemplates_*`, `Settings.RegisterCanvasLayoutCategory`.
- [ ] Update the `## Interface:` number in `ForeverBestInSlot.toc` when the client's interface version changes.

---

## 3. Checks before every release
- [ ] `texlua tools/validate.lua .` → 0 errors.
- [ ] `texlua tools/uitest.lua` → no FAIL lines.
- [ ] Build a test zip and try it in game (or send it to the player to test).
- [ ] Add a section at the top of `CHANGELOG.md` (this becomes the CurseForge release notes).
- [ ] Run `python3 tools/gen_patchnotes.py` so the in-game About tab shows the same notes (`tools/uitest.lua` fails if you forget).
- [ ] **No mention of Claude / AI in the changelog or commit messages, and no Co-Authored-By trailers.**
- [ ] Push to `main`, then publish a GitHub release with the version as the tag (https://github.com/tylermccuen/WoWForeverBiSGear/releases/new). The packager uploads to CurseForge automatically; check the release's Assets for `ForeverBestInSlot-<version>-forever.zip`.

---

## 4. Known gaps to fill when the data appears
- [ ] Recipe sources still "TBD": Wild Leather Armor Kit pattern, SAF-T Ultra Precision Scope schematic, Formula: Enchant Shield - Excellent Stamina.
- [ ] Quest givers still "TBD": Job Opening: Guard Captain of Revantusk Village, Korrak the Bloodrager, Sharing the Knowledge, Running Firewater.
- [ ] Boss model IDs missing for 42 of 73 bosses (they fall back to the NPC ID). Fill in `disp` in `gen_bosses.py` from wowhead.com/forever/npc=ID (the page's `data-mv-display-id`).
- [ ] Demonic Rune source (shows "Auction House").
- [ ] Merchant's Favor vendors: reputation level needed for the newer formulas (Wowhead lists only the price).

---

## 5. Periodic check (about once a month, or before a big raid night)
- [ ] Open each guide site and skim for "updated" dates newer than the `checked` date in the phase file.
- [ ] Look at CurseForge comments / GitHub issues for wrong items.
- [ ] Re-check the section 4 gaps.

---

## 6. Notes for whoever does the research
- kovarel.com rate-limits (Cloudflare 1015): fetch one page every ~2.5 s and retry after 15-20 s.
- wowhead.com shows a "Human Verification" page after many quick requests. Don't try to get around it: stop, wait, and continue later at ~3 s per page.
- wowtbc.gg's per-spec page data (`page-data.json`) holds the exact gear and enchant IDs, including which Lesser Arcanum of Voracity stat each spec uses.
- Item tooltips in Forever show hit on gear as a rating (10 = 1%); ranged-only hit ("hit with ranged weapons") isn't in the API's hit value, so the raid check reads it from gear tooltips.
- WoW Forever has no Dungeon Journal: boss models come from `Data/Bosses.lua`.
