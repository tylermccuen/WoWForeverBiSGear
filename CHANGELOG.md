# Forever Best In Slot

## 1.7.0
- **Avoid grouping with:** the "Also BiS" line under each item is now its own column on the BiS and Realistic tabs, listing the other specs (class-coloured) that have the item as a BiS pick, so you know who would roll against you.
- **Smoother resizing:** dragging the bottom-right corner no longer makes the window jump; it now grows from its top-left corner. Right-click the corner to reset the size (it used to be a double-click, which was easy to trigger by accident).
- **List tabs:** BiS, Realistic, Enchants and Consumables are now tabs along the bottom of the window instead of a dropdown.
- **Tick slots done:** every row in the BiS, Realistic and Enchants lists has a "done" checkbox. Ticking a slot marks it finished in both the BiS and Realistic lists, so you can mix them: finish your head with the Realistic pick and it shows as done while you look at BiS. Slots where you own the BiS or Realistic item are ticked automatically, and you can untick any slot to mark it not done. The counter now shows how many slots are done, and **Hide finished** hides every done slot. Ticks are saved per character and spec.
- **Consumables list:** open the Consumables tab for a raid shopping list for your spec: flask, elixirs, food, weapon oil or sharpening stone, potions and runes (from rankedboost.com's WoW Forever consumables guide). Casters get the elixir for their spell school. The counter shows how many you already have in your bags, and hovering a consumable tells you if it's on your list.
- **Raid check:** a companion panel docked to the right side of the browser. It opens and moves with the browser; the "Raid check" button (or `/bis raid`) turns it on or off. It checks whether your character is ready to raid, for the spec selected in the browser or your active spec:
  - Hit chance against raid bosses: 8% for melee, hunters and tanks, 17% for casters (healers are skipped, heals can't miss). Dual wielders also see the auto-attack figure.
  - Defense 440 for tanks, so raid bosses can't crit you.
  - Empty gear slots, and slots on your enchant list that aren't enchanted.
  - How many BiS and Realistic items you have equipped.
  - Your gear's key stats for your role (for example healing and intellect for healers, spell damage for casters, agility and attack power for hunters) compared with the full pre-raid BiS set.
  The check updates when you change gear or spec.

## 1.6.0
- **Enchants:** every spec now has an Enchants list (pick "Enchants" from the list button) with the enchant, arcanum, armor kit or scope for each slot, from wowtbc.gg. Hovering an enchant scroll, arcanum or kit tells you if it's your BiS enchant.
- **Quiver and ammo for hunters:** new Quiver and Ammo slots. Every hunter list shows the best arrows (Doomshot) and the best bullets (Miniature Cannon Balls), so you can pick the one for your bow or gun. Bows get Harpy Hide Quiver; the Realistic set's rifle gets Ribbly's Bandolier; alternatives cover the other quivers and ammo pouches.
- **Tier 0 pieces for Tier 0.5 quests:** wherever a list has a Tier 0.5 piece (like Beastmaster's Cap), the blue Tier 0 piece its quest needs (like Beaststalker's Cap) is listed right under it with where it drops. The row disappears once you own the Tier 0.5 piece. Tooltips on Tier 0 pieces say which Tier 0.5 piece they turn into.
- **Hide finished:** a new checkbox hides a slot once you own either its BiS item or its Realistic item.

## 1.5.0
- **Realistic pre-raid sets:** every spec now has a second list of gear that's quicker to collect, from conquestcapped.com. Switch between "BiS (best available)" and "Realistic (quick to collect)" with the new list button in the browser.
- Tooltips say "Realistic pick for you" for items in your realistic set, show your main BiS pick for that slot, and label realistic specs with "(realistic)".

## 1.4.0
- **Gear alternatives:** every spec now lists alternative items per slot under the main BiS pick. Toggle them with the "Alternatives" checkbox in the browser. Tooltips say "Alternative for you" and name your main pick for that slot.
- **Resizable window:** drag the bottom-right corner to resize the browser; columns stretch to fit and the size is remembered. Double-click the corner to reset it.
- Horde Arcane Mages and Affliction Warlocks now get Eye of Orgrimmar, the Horde version of Songstone of Ironforge.

## 1.3.0
- **BiS verdict on tooltips:** hovering an item or clicking an item link now starts the tooltip with "BiS for you" (green) or "Not BiS for you" plus your BiS item for that slot, with markers for items you already own. Both lines can be turned off in Settings.

## 1.2.0
- First release: pre-raid (level 60) BiS lists for all specs, item browser with filters, tooltips, copy-paste item links, minimap button and phase support.
