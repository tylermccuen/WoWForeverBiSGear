# Phase 1 (raids, December 9, 2026): research notes

Status 2026-11-24: raid loot tables are **not published**. Forever hides item stats until someone loots the item, so no site has slot-by-slot raid BiS lists yet. Expect lists in the days after December 9.

## Raids
| Raid | Size | Notes |
|---|---|---|
| Barrow Deeps | 10 | 8 bosses. Under Mount Hyjal; the tunnels start in eastern Ashenvale. No attunement listed. |
| Hyjal Summit | 20 | Home of the tier sets and the first legendary. Bosses not revealed. |
| Onyxia's Lair | 40 | Needs the Onyxia attunement. Loot not published. |

Every raid boss is said to drop one "chase" item (lfcarry.com).

## Tier 1 sets (18, one per role)
Set IDs are in `Data/Phase2.lua` (`ns.TierSets`), from conquestcapped.com.
- Six pieces: Head, Shoulder, Chest, Hands, Legs, Feet. Bonuses at 2/3/4/5 pieces.
- Raid pieces: item level 65, bind on pickup. Head and Chest have no confirmed source yet (expected Hyjal Summit or Barrow Deeps).
- Crafted Shoulder / Hands / Legs / Feet: item level 61, bind on equip. Patterns from **Aisarra Nightmeadow** (Mount Hyjal), need Guardians of Hyjal reputation (Legs: Friendly + quest "Friendly Advice"). Tailoring 300 (cloth), Leatherworking 300 (leather, mail), Blacksmithing 300 (plate). Needs a camp station (Blueprint, 300 skill, near a Campfire).
- Material: **Malleable Essence of Nature**, from disenchanting Hyjal Summit / Barrow Deeps loot. Sources disagree on amounts (5 legs / 3 others per craft vs. 8 / 6 for the recipe); check in game.
- Only one crafted tier piece can be worn; Rousing Seed Pod (10 gold, Revered with Guardians of Hyjal) raises it to two.

## To do once the raids are open
- [ ] Look up the item IDs of each set's pieces (kovarel.com item-set pages, set IDs above).
- [ ] Get boss lists and loot tables for all three raids (kovarel / wowhead.com/forever).
- [ ] Pick the guide to follow for raid BiS (wowtbc.gg only has `pre-raid` keys today; check for a new phase key in its page-data JSON; conquestcapped.com, lfcarry.com per-spec guides).
- [ ] Fill `guides` in `Data/Phase2.lua` (the phase appears in the Phase menu as soon as one spec has a list).
- [ ] Raid bosses into `gen_bosses.py`, drop rates, crafted tier pieces into `gen_crafting.py` (Malleable Essence of Nature as a material), Guardians of Hyjal as a reputation source.
- [ ] Re-check hit caps and enchants/consumables for raids.

## Sources
- icy-veins.com/wow-forever/roadmap (dates)
- conquestcapped.com/guides/wow-forever/wow-forever-tier-sets-1/ (sets, crafting)
- lfcarry.com/guides/wow-forever-bis-lists (item levels, chase items, crafting)
- timesaver.gg/blog/wow-forever-pre-raid-bis (raid sizes, hidden stats)
