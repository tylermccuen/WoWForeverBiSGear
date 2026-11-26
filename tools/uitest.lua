-- End-to-end test of the addon UI against mocked WoW frames. Run from the addon folder: lua tools/uitest.lua
-- Generic mock of WoW frames: every method exists; Get* return numbers, scripts are stored and can be fired.
local function mock(name)
  local o = {__scripts={}, __shown=false, __name=name, __w=720, __h=540}
  return setmetatable(o, {__index=function(t,k)
    if not k:match("^%u") then return nil end
    if k=="SetScript" then return function(self,ev,fn) self.__scripts[ev]=fn end end
    if k=="GetScript" then return function(self,ev) return self.__scripts[ev] end end
    if k=="Show" then return function(self) self.__shown=true; if self.__scripts.OnShow then self.__scripts.OnShow(self) end end end
    if k=="Hide" then return function(self) self.__shown=false end end
    if k=="IsShown" then return function(self) return self.__shown end end
    if k=="GetWidth" then return function(self) return self.__w end end
    if k=="GetHeight" then return function(self) return self.__h end end
    if k=="SetWidth" then return function(self,w) self.__w=w end end
    if k=="SetSize" then return function(self,w,h) self.__w=w; self.__h=h; if self.__scripts.OnSizeChanged then self.__scripts.OnSizeChanged(self,w,h) end end end
    if k=="GetChecked" then return function() return true end end
    if k=="GetText" then return function(self) return self.__text or "" end end
    if k=="SetText" then return function(self,t) self.__text=t end end
    if k=="GetFrameLevel" then return function() return 1 end end
    if k:match("^Create") then return function(self) return mock(k) end end
    if k:match("^Get") or k:match("^Is") then return function() return nil end end
    return function(self) return self end
  end})
end
ALLFRAMES = {}
CreateFrame = function(_, name) local f=mock(name); if name then _G[name]=f end; table.insert(ALLFRAMES,f); return f end
UIParent, Minimap, GameTooltip = mock(), mock(), mock()
UISpecialFrames = {}; SlashCmdList = {}
wipe = function(t) for k in pairs(t) do t[k]=nil end end
tinsert = table.insert
UnitFactionGroup = function() return "Alliance" end
UnitClass = function() return "Hunter","HUNTER" end
InCombatLockdown = function() return false end
GetSpecialization = function() return 1 end
GetSpecializationInfo = function() return 253, "Beast Mastery" end
GetInventoryItemID = function() return nil end
GetCursorPosition = function() return 0,0 end
C_Container = { GetContainerNumSlots=function() return 0 end, GetContainerItemID=function() end }
-- timers fire at once; a timer that keeps re-arming itself (Santa) stops after a few rounds
local timerDepth = 0
C_Timer = { After=function(_,f)
  if timerDepth >= 4 then return end
  timerDepth = timerDepth + 1; f(); timerDepth = timerDepth - 1
end }
C_ClassColor = { GetClassColor=function() return {r=1,g=1,b=1, GenerateHexColor=function() return "ffffffff" end} end }
C_Item = { GetItemIconByID=function() return 134400 end, GetItemInfoInstant=function() end, GetItemQualityByID=function() return 3 end }
Item = { CreateFromItemID=function(_,id) return { IsItemEmpty=function() return false end,
  ContinueOnItemLoad=function(self,cb) cb() end, GetItemLink=function() return "|cff0070dd[Item "..id.."]|r" end,
  GetItemName=function() return "Item "..id end, GetItemIcon=function() return 1 end } end }
MenuUtil = { CreateContextMenu=function() end }
Settings = { RegisterCanvasLayoutCategory=function() return {GetID=function() return 1 end} end, RegisterAddOnCategory=function() end, OpenToCategory=function() end }
TooltipDataProcessor = { AddTooltipPostCall=function() end }
Enum = { TooltipDataType={Item=0}, BagIndex={} }
LOCALIZED_CLASS_NAMES_MALE = setmetatable({}, {__index=function(_,k) return k end})
CreateAtlasMarkup = function() return "" end

local ns = {}
local events = {}
local files = {"Core.lua","Data/Phases.lua","Data/Phase1.lua","Data/Phase2.lua","Data/Crafting.lua","Data/DropRates.lua","Data/Bosses.lua","Data/Pets.lua","Data/PlayerNotes.lua","Data/PatchNotes.lua","Data/Quests.lua","Items.lua","LinkPopup.lua","Tooltip.lua","Browser.lua","Raid.lua","Boss.lua","Quests.lua","Minimap.lua","Options.lua"}
for _,f in ipairs(files) do assert(loadfile(f))("ForeverBestInSlot", ns) end
local function fire(ev, ...)
  for _, f in ipairs(ALLFRAMES) do
    if f.__scripts.OnEvent then f.__scripts.OnEvent(f, ev, ...) end
  end
end
fire("ADDON_LOADED", "ForeverBestInSlot")
fire("PLAYER_LOGIN")
local function check(label, fn)
  local ok, err = pcall(fn)
  print((ok and "OK   " or "FAIL ") .. label .. (ok and "" or ("  -> " .. tostring(err))))
end
check("open browser", function() ns.ToggleBrowser() end)
local win = _G.ForeverBiSFrame
local function visibleRows()
  local n, sample = 0, nil
  for _, f in ipairs(ALLFRAMES) do
    if f.__shown and f.name and f.name.__text and f.name.__text:find("Item") then
      n = n + 1; sample = sample or (f.name.__text .. " / " .. (f.slot.__text or "") .. " / " .. (f.source.__text or ""))
    end
  end
  return n, sample
end
local n, sample = visibleRows()
print("   rows with item names:", n, sample)
check("toggle alternatives off+refresh", function() ns.char.showAlts=false; ns.RefreshBrowser() end)
print("   rows:", (visibleRows()))
check("alternatives on", function() ns.char.showAlts=true; ns.RefreshBrowser() end)
print("   rows:", (visibleRows()))
check("resize to 1100x700", function() win:SetSize(1100,700) end)
check("missing only + slot filter", function() ns.char.missingOnly=true; ns.char.selectedSlot="Finger"; ns.RefreshBrowser() end)
print("   rows:", (visibleRows()))
check("switch to every class/spec", function()
  ns.char.missingOnly=false; ns.char.selectedSlot="All"
  for _, cls in ipairs(ns.ClassOrder) do for _, sp in ipairs(ns.GetSpecsForClass(cls)) do
    ns.char.selectedClass, ns.char.selectedSpec = cls, sp; ns.RefreshBrowser()
  end end
end)
check("realistic list for every class/spec", function()
  ns.char.listMode="realistic"
  for _, cls in ipairs(ns.ClassOrder) do for _, sp in ipairs(ns.GetSpecsForClass(cls)) do
    ns.char.selectedClass, ns.char.selectedSpec = cls, sp; ns.RefreshBrowser()
    local n = visibleRows()
    if n == 0 then error("no realistic rows for " .. cls .. " " .. sp) end
  end end
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"; ns.RefreshBrowser()
end)
print("   MM hunter realistic rows:", (visibleRows()))
check("back to BiS list", function() ns.char.listMode="bis"; ns.RefreshBrowser() end)
print("   rows:", (visibleRows()))
check("enchants list for every class/spec", function()
  ns.char.listMode="enchants"
  for _, cls in ipairs(ns.ClassOrder) do for _, sp in ipairs(ns.GetSpecsForClass(cls)) do
    ns.char.selectedClass, ns.char.selectedSpec = cls, sp; ns.RefreshBrowser()
    if visibleRows() == 0 then error("no enchant rows for " .. cls .. " " .. sp) end
  end end
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"; ns.RefreshBrowser()
end)
print("   MM hunter enchant rows:", (visibleRows()))
check("realistic with Tier 0 quest rows", function()
  ns.char.listMode="realistic"; ns.RefreshBrowser()
  local g = ns.GetGuide("HUNTER","Marksmanship",1)
  local pre = 0
  for _, r in ipairs(ns.GetGuideRows(g, false, "realistic")) do if r.isPre then pre = pre + 1 end end
  if pre == 0 then error("no Tier 0 rows in MM realistic") end
  print("   Tier 0 rows:", pre, " total rows:", (visibleRows()))
end)
check("hide finished slots", function()
  local before = visibleRows()
  local g = ns.GetGuide("HUNTER","Marksmanship",1)
  ns.Owned[g.items[1][2]] = "bag"     -- own the BiS head: realistic head row should hide
  ns.char.hideDone = true; ns.RefreshBrowser()
  local after = visibleRows()
  if after >= before then error("nothing hidden: " .. before .. " -> " .. after) end
  print("   rows:", before, "->", after)
  ns.char.hideDone = false; ns.Owned[g.items[1][2]] = nil
end)
check("tick a slot done in BiS, hidden in Realistic too", function()
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"
  ns.char.listMode = "realistic"; ns.char.hideDone = true; ns.RefreshBrowser()
  local before = visibleRows()
  ns.SetDoneMark("HUNTER:Marksmanship", "Head#1", true)   -- as if ticked on the BiS head row
  ns.char.listMode = "bis"; ns.RefreshBrowser()
  local bisRows = visibleRows()
  ns.char.listMode = "realistic"; ns.RefreshBrowser()
  local after = visibleRows()
  print("   realistic rows:", before, "->", after, " bis rows with head done:", bisRows)
  if after >= before then error("ticked slot not hidden in Realistic") end
  ns.SetDoneMark("HUNTER:Marksmanship", "Head#1", nil)
  ns.char.hideDone = false; ns.char.listMode = "bis"; ns.RefreshBrowser()
end)
check("untick a slot you own", function()
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"
  local g = ns.GetGuide("HUNTER","Marksmanship",1)
  ns.Owned[g.items[1][2]] = "bag"
  ns.char.listMode = "bis"; ns.char.hideDone = true; ns.RefreshBrowser()
  local hidden = visibleRows()
  ns.SetDoneMark("HUNTER:Marksmanship", "Head#1", false)   -- unticked although owned
  ns.RefreshBrowser()
  local shown = visibleRows()
  print("   owned head: hidden rows", hidden, "-> after untick", shown)
  if shown <= hidden then error("untick didn't bring the slot back") end
  ns.SetDoneMark("HUNTER:Marksmanship", "Head#1", nil); ns.Owned[g.items[1][2]] = nil
  ns.char.hideDone = false; ns.RefreshBrowser()
end)
check("consumables list for every class/spec", function()
  ns.char.listMode="consumables"
  for _, cls in ipairs(ns.ClassOrder) do for _, sp in ipairs(ns.GetSpecsForClass(cls)) do
    ns.char.selectedClass, ns.char.selectedSpec = cls, sp; ns.RefreshBrowser()
    if visibleRows() == 0 then error("no consumables for " .. cls .. " " .. sp) end
  end end
  ns.char.selectedClass, ns.char.selectedSpec = "MAGE", "Fire"; ns.RefreshBrowser()
  print("   Fire mage consumable rows:", (visibleRows()))
  ns.char.listMode="bis"; ns.RefreshBrowser()
end)
check("raid check draws even if item data never loads", function()
  local saveWith = ns.WithItem
  ns.WithItem = function() end          -- simulate items that never finish loading
  local calls = 0
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"
  ns.RunRaidCheck(function(r) calls = calls + 1 end)
  ns.WithItem = saveWith
  if calls == 0 then error("nothing drawn while items load") end
end)
check("raid check tab", function()
  ns.char.listMode = "raid"; ns.RefreshBrowser()
  if not _G.ForeverBiSFrame.raidPane:IsShown() then error("raid pane not shown") end
  local v = _G.ForeverBiSFrame.raidPane.view
  for _, cls in ipairs(ns.ClassOrder) do for _, sp in ipairs(ns.GetSpecsForClass(cls)) do
    ns.char.selectedClass, ns.char.selectedSpec = cls, sp
    UnitClass = function() return cls, cls end
    v.refresh()
    if v.lastError then error(cls .. " " .. sp .. ": " .. v.lastError) end
    v.setWidth(300)   -- narrow layout too
    if v.lastError then error(cls .. " " .. sp .. " narrow: " .. v.lastError) end
    v.setWidth(700)
    if v.lastError then error(cls .. " " .. sp .. " wide: " .. v.lastError) end
  end end
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"
  UnitClass = function() return "Hunter", "HUNTER" end
  print("   dashboard rendered for every spec, wide and narrow")
  ns.char.listMode = "bis"; ns.RefreshBrowser()
end)
check("raid panel with the character window", function()
  local shown = true
  CharacterFrame = { IsShown = function() return shown end, HookScript = function() end,
                     GetHeight = function() return 500 end, GetEffectiveScale = function() return 1 end,
                     GetRight = function() return 400 end }
  ns.db.raidWithCharacter = true
  local b = _G.ForeverBiSFrame
  local wasOpen = b and b:IsShown()
  if wasOpen then b:Hide() end   -- the panel shows when the browser is closed
  ns.UpdateRaidCompanion()
  if not ns.RaidPanelShown() then error("panel not shown with the character window") end
  if wasOpen then b:Show() end
  shown = false
  ns.UpdateRaidCompanion()
  if ns.RaidPanelShown() then error("panel still shown after closing the character window") end
end)
check("raid check (every spec)", function()
  local _GetLink = GetInventoryItemLink
  GetInventoryItemLink = function(_, inv) if inv == 1 then return "|cff0070dd|Hitem:226887:0:0|h[Cap]|h|r" end end
  GetHitModifier = function() return 2 end
  CR_HIT_MELEE, CR_HIT_RANGED, CR_HIT_SPELL = 6, 7, 8
  GetCombatRatingBonus = function(cr) return 1.7 end
  GetCritChance = function() return 12.5 end
  UnitDefense = function() return 300, 120 end
  C_Item.GetItemStats = function(link) return { ITEM_MOD_AGILITY_SHORT = 10, ITEM_MOD_STAMINA_SHORT = 8 } end
  GetInventoryItemLink = function(_, inv)
    if inv == 1 then return "|cff0070dd|Hitem:226887:0:0|h[Cap]|h|r" end
    if inv == 2 then return "|cff0070dd|Hitem:18404:0:0|h[Neck]|h|r" end
  end
  C_TooltipInfo = { GetInventoryItem = function(_, inv)
    if inv == 1 then return { lines = { { leftText = "Beastmaster's Cap" }, { leftText = "Enchanted: +8 Agility" } } } end
    if inv == 6 then return { lines = { { leftText = "Sash of the Grand Hunt" }, { leftText = "Equip: Improves your chance to hit with ranged weapons by 1%." } } } end
    return { lines = { { leftText = "Some Neck" } } }
  end }
  C_Item.GetItemNameByID = function(id) return "Item " .. id end
  for _, cls in ipairs(ns.ClassOrder) do for _, sp in ipairs(ns.GetSpecsForClass(cls)) do
    ns.char.selectedClass, ns.char.selectedSpec = cls, sp
    UnitClass = function() return cls, cls end
    local got
    ns.RunRaidCheck(function(r) got = r end)
    if not got then error("no report for " .. cls .. " " .. sp) end
    if got.placeTotal and (got.placeTotal < 10 or #got.places ~= 3) then
      error("gear by place looks wrong for " .. cls .. " " .. sp .. ": " .. tostring(got.placeTotal))
    end
    for _, b in ipairs(got.bars) do
      if b.label:find("BiS items") or b.label:find("Realistic") then error("old BiS / Realistic bar is back") end
    end
    if cls == "HUNTER" and sp == "Marksmanship" then
      for _, l in ipairs(got.lines) do print("   [" .. l.status .. "] " .. l.text) end
    end
  end end
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"
  ns.ToggleRaidCheck()
end)
check("enchant column", function()
  ns.char.selectedClass, ns.char.selectedSpec, ns.char.listMode = "HUNTER", "Marksmanship", "bis"
  ns.RefreshBrowser()
  local g = ns.GetGuide("HUNTER","Marksmanship",1)
  local shown = 0
  for _, e in ipairs(ns.ItemIndex[g.items[7][2]] or {}) do shown = shown + 1 end
  print("   specs indexed for MM hands item:", shown)
end)
check("compact beside the character window and back", function()
  local shown = true
  CharacterFrame = { IsShown = function() return shown end, HookScript = function() end, GetRight = function() return 400 end }
  ns.db.compactWithCharacter = true
  ns.UpdateCompact()
  local f = _G.ForeverBiSFrame
  print("   compact:", f.compact, " width:", f:GetWidth())
  if not f.compact then error("didn't go compact") end
  ns.RefreshBrowser()
  shown = false
  ns.UpdateCompact()
  print("   after close:", f.compact, " width:", f:GetWidth())
  if f.compact then error("stayed compact") end
end)
check("quest highlight", function()
  C_QuestLog = { GetNumQuestLogEntries = function() return 2 end,
                 GetInfo = function(i) return ({ { title = "Libram of Voracity" }, { title = "General Drakkisath's Demise" } })[i] end }
  ns.ScanQuestLog()
  local tests = {
    ["Quest: Libram of Voracity (Burning Steppes)"] = true,
    ["Quest: For The Horde! / General Drakkisath's Demise"] = true,
    ["Dungeon Set 2 quest: Saving the Best for Last"] = false,
    ["Scholomance: Darkmaster Gandling"] = false,
  }
  for src, want in pairs(tests) do
    if ns.OnSourceQuest(src) ~= want then error("wrong for " .. src) end
  end
  ns.RefreshBrowser()
end)
check("recipe + materials on Consumables and Enchants", function()
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"
  for _, m in ipairs({ "consumables", "enchants" }) do
    ns.char.listMode = m; ns.RefreshBrowser()
    local g = ns.GetGuide("HUNTER","Marksmanship",1)
    local set = m == "consumables" and g.consumables or g.enchants
    local crafted = 0
    for _, r in ipairs(set) do if ns.Crafting[r[2]] then crafted = crafted + 1 end end
    print("   " .. m .. ": crafting data for " .. crafted .. " / " .. #set)
  end
  ns.char.listMode = "bis"; ns.RefreshBrowser()
end)
check("boss lookup + window", function()
  local tests = {
    ["Stratholme: Baron Rivendare"] = true,
    ["Drop: Gyth (Upper Blackrock Spire)"] = true,
    ["Upper Blackrock Spire: General Drakkisath / Madam Swyndle (vendor)"] = true,
    ["Quest: Baron Rivendare"] = false,
    ["Random trash drop (Stratholme, Scholomance, Blackrock Spire)"] = false,
    ["Crafted: Leatherworking"] = false,
  }
  for src, want in pairs(tests) do
    if (ns.FindBoss(src) ~= nil) ~= want then error("wrong for " .. src) end
  end
  local b = ns.FindBoss("Stratholme: Baron Rivendare")
  print("   Baron Rivendare: npc", b.npc, "model", b.display, b.instance)
  ns.ShowBoss(b)
  ns.ShowBoss(ns.FindBoss("Lower Blackrock Spire: Shadow Hunter Vosh'gajin"))   -- NPC ID only
  ns.RefreshBrowser()
end)
check("dungeon / boss split and sorting", function()
  local cases = {
    { "Stratholme: Baron Rivendare", "Stratholme", "Baron Rivendare" },
    { "Quest: The Princess Saved? (Blackrock Depths)", "Blackrock Depths", "Quest: The Princess Saved?" },
    { "Dungeon Set 2 quest: Saving the Best for Last", "Tier 0.5 set", "Quest: Saving the Best for Last" },
    { "Crafted: Leatherworking", "Crafted", "Leatherworking" },
    { "Random trash drop (Stratholme, Scholomance, Blackrock Spire)", "Stratholme, Scholomance, Blackrock Spire", "Trash Drop" },
    { "Stormpike Guard / Frostwolf Clan (Exalted)", "Alterac Valley", "Stormpike Guard / Frostwolf Clan (Exalted)" },
    { "Darkspear Raiders (Exalted)", "Reputation", "Darkspear Raiders (Exalted)" },
    { "Barkskin Burrow reputation (Revered)", "Reputation", "Barkskin Burrow (Revered)" },
    { "World drop (BoE)", "World Drop", "Any Mob (BoE)" },
  }
  for _, c in ipairs(cases) do
    local d, b = ns.SplitSource(c[1])
    if d ~= c[2] or b ~= c[3] then error(c[1] .. " -> [" .. d .. "] [" .. b .. "]") end
  end
  ns.DropRates = { [101] = { { "Baron Rivendare", 11.1 } }, [102] = { { "Gyth", 19.7 } } }
  local list = {
    { id = 100, slot = "Head", source = "Quest: X (Zone)" },
    { id = 101, slot = "Legs", source = "Stratholme: Baron Rivendare" },
    { id = 999, slot = "Legs", source = "T0", isAlt = true },
    { id = 102, slot = "Shoulder", source = "Upper Blackrock Spire: Gyth" },
  }
  ns.char.sortBy, ns.char.sortDesc = "drop", true
  local out = ns.SortRows(list)
  local ids = {}; for _, r in ipairs(out) do ids[#ids+1] = r.id end
  print("   by drop:", table.concat(ids, ","))
  if table.concat(ids, ",") ~= "102,101,999,100" then error("drop sort wrong") end
  ns.char.sortBy, ns.char.sortDesc = "dungeon", false
  ids = {}; for _, r in ipairs(ns.SortRows(list)) do ids[#ids+1] = r.id end
  print("   by dungeon:", table.concat(ids, ","))
  ns.char.sortBy, ns.char.sortDesc = "slot", false
  ns.char.listMode = "bis"; ns.RefreshBrowser()
end)
check("quest hover tooltip", function()
  local lines = {}
  local tt = { AddLine = function(_, t) lines[#lines+1] = t end,
               AddDoubleLine = function(_, a, b) lines[#lines+1] = a .. "  |  " .. b end }
  UnitFactionGroup = function() return "Horde" end
  local q = ns.QuestsInSource("Dungeon Set 2 quest: Saving the Best for Last")
  if not q then error("quest not found") end
  ns.AddQuestTooltip(tt, q)
  for _, l in ipairs(lines) do print("   " .. l) end
  if not ns.QuestsInSource("Quest: For The Horde! / General Drakkisath's Demise") then error("multi quest") end
  UnitFactionGroup = function() return "Alliance" end
end)
check("saved specs: your spec first, up to 5 saved", function()
  UnitClass = function() return "Hunter", "HUNTER" end
  GetSpecialization = function() return 2 end
  GetSpecializationInfo = function() return 0, "Marksmanship" end
  ns.char.savedSpecs = {}
  if ns.SaveSpec("HUNTER", "Marksmanship") then error("saved your own spec") end
  assert(ns.SaveSpec("PRIEST", "Holy"))
  assert(ns.SaveSpec("WARRIOR", "Protection"))
  assert(ns.SaveSpec("MAGE", "Fire"))
  assert(ns.SaveSpec("DRUID", "Balance"))
  assert(ns.SaveSpec("ROGUE", "Combat"))
  if ns.SaveSpec("WARLOCK", "Affliction") then error("saved a 6th") end
  if ns.SaveSpec("PRIEST", "Holy") then error("saved a duplicate") end
  local list = ns.GetMySpecList()
  local names = {}
  for _, f in ipairs(list) do names[#names+1] = f.spec .. (f.mine and "*" or "") end
  print("   your specs:", table.concat(names, ", "))
  if not list[1].mine or #list ~= 6 then error("wrong list") end
  ns.char.selectedClass, ns.char.selectedSpec = "MAGE", "Fire"; ns.RefreshBrowser()
  ns.RemoveSavedSpec("WARRIOR", "Protection")
  if #ns.GetMySpecList() ~= 5 then error("remove failed") end
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"; ns.RefreshBrowser()
end)
check("raid panel sits past the character window's side buttons", function()
  local saved = CharacterFrame
  local side = { IsShown = function() return true end, GetLeft = function() return 402 end, GetRight = function() return 446 end }
  CharacterFrame = { GetRight = function() return 400 end, GetChildren = function() return side end }
  local gap = ns.CharacterOverhang()
  CharacterFrame = saved
  if math.abs(gap - 46) > 0.01 then error("gap " .. tostring(gap)) end
end)
check("your spec comes from talent points", function()
  UnitClass = function() return "Hunter", "HUNTER" end
  GetSpecialization = function() return 1 end
  GetSpecializationInfo = function() return 0, "Beast Mastery" end
  GetNumTalentTabs = function() return 3 end
  local pts = { 5, 31, 15 }
  local names = { "Beast Mastery", "Marksmanship", "Survival" }
  GetTalentTabInfo = function(i) return 360 + i, names[i], "", 132160 + i, pts[i] end
  local _, sp = ns.GetActiveSpec()
  if sp ~= "Marksmanship" then error("got " .. tostring(sp)) end
  GetTalentTabInfo = function(i) return names[i], "Interface\\Icons\\Tab" .. i, pts[i] end   -- older return order
  _, sp = ns.GetActiveSpec()
  if sp ~= "Marksmanship" then error("old order got " .. tostring(sp)) end
  GetNumTalentTabs, GetTalentTabInfo = nil, nil
  ns.char.mySpec = "Survival"
  _, sp = ns.GetActiveSpec()
  if sp ~= "Survival" then error("manual pick ignored: " .. tostring(sp)) end
  ns.char.mySpec = nil
  GetSpecialization = function() return 2 end
  GetSpecializationInfo = function() return 0, "Marksmanship" end
end)
check("ticks clear when the lists change a slot", function()
  ns.char.selectedClass, ns.char.selectedSpec, ns.char.listMode = "HUNTER", "Marksmanship", "bis"
  ns.char.done = {}
  ns.RefreshBrowser()
  local g = ns.GetGuide("HUNTER", "Marksmanship", 1)
  local sig = g.items[1][2] .. "|"   -- rough: the real signature is built by the browser
  -- tick Head through the browser's own signature
  local key = "Head#1"
  ns.char.done["HUNTER:Marksmanship"] = { [key] = true }   -- an old-style tick
  ns.RefreshBrowser()
  local m = ns.char.done["HUNTER:Marksmanship"][key]
  if type(m) ~= "table" or not m.sig then error("old tick not migrated") end
  -- simulate a guide update: new head item
  local old = g.items[1][2]
  g.items[1][2] = 999999
  ns.ClearRowCache()   -- a real list update arrives with a reload
  local printed
  local savePrint = ns.Print; ns.Print = function(msg) printed = msg end
  ns.RefreshBrowser()
  ns.Print = savePrint
  g.items[1][2] = old
  ns.ClearRowCache()
  if ns.char.done["HUNTER:Marksmanship"][key] ~= nil then error("tick not cleared") end
  print("   " .. tostring(printed))
  ns.RefreshBrowser()
end)
check("ticks carry to another spec with the same items", function()
  ns.char.done = {}
  ns.SetDoneMark("HUNTER:Marksmanship", "Head#1", true, "1|2")
  if ns.ResolveDoneMark("HUNTER:Survival", "Head#1", "1|2") ~= true then error("not shared") end
  if ns.ResolveDoneMark("HUNTER:Survival", "Head#1", "9|2") ~= nil then error("shared across different items") end
  if ns.ResolveDoneMark("MAGE:Fire", "Head#1", "1|2") ~= nil then error("shared across classes") end
  ns.SetDoneMark("HUNTER:Survival", "Head#1", false, "1|2")   -- untick on the other spec sticks
  if ns.ResolveDoneMark("HUNTER:Survival", "Head#1", "1|2") ~= false then error("untick lost") end
  ns.char.done = {}
end)
check("enchants tab: skill / where / materials columns sort", function()
  local list = {
    { id = 1, slot = "Head", source = "Quest: Libram (Burning Steppes)", craftTab = true },
    { id = 2, slot = "Neck", craftTab = true, craft = { prof = "Enchanting", skill = 210, from = "Vendor: B" } },
    { id = 3, slot = "Back", craftTab = true, craft = { prof = "Enchanting", skill = 300, from = "Drop: A" } },
  }
  ns.char.sortBy, ns.char.sortDesc = "dungeon", true
  local out = ns.SortRows(list)
  if out[1].id ~= 3 or out[3].id ~= 1 then error("skill sort wrong") end
  ns.char.sortBy, ns.char.sortDesc = "boss", false
  out = ns.SortRows(list)
  if out[1].id ~= 3 or out[2].id ~= 1 or out[3].id ~= 2 then error("source sort wrong") end
  ns.char.sortBy, ns.char.sortDesc = "slot", false
  ns.char.listMode = "enchants"; ns.RefreshBrowser()
  ns.char.listMode = "consumables"; ns.RefreshBrowser()
  ns.char.listMode = "bis"; ns.RefreshBrowser()
end)
check("pin a quest giver on the map", function()
  local set
  C_Map = C_Map or {}
  C_Map.GetMapChildrenInfo = function(root) if root == 947 then return { { mapID = 1454, name = "Orgrimmar", mapType = 3 } } end return {} end
  C_Map.CanSetUserWaypointOnMap = function() return true end
  C_Map.SetUserWaypoint = function(p) set = p end
  UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { m = m, x = x, y = y } end }
  UnitFactionGroup = function() return "Horde" end
  local pins = ns.QuestPins({ "For The Horde!" })
  if #pins ~= 1 then error("pins " .. #pins) end
  assert(ns.PinOnMap(pins[1].zone, pins[1].coords, pins[1].giver))
  if not set or set.m ~= 1454 or math.abs(set.x - 0.317) > 0.001 then error("wrong pin") end
  UnitFactionGroup = function() return "Alliance" end
end)
check("consumables: have / keep counts and targets", function()
  C_Item = C_Item or {}
  local saveCount = C_Item.GetItemCount
  C_Item.GetItemCount = function(id, bank) if id == 13510 then return bank and 3 or 1 end return 0 end
  local b, t = ns.ConsumeCount(13510)
  if b ~= 1 or t ~= 3 then error("count " .. b .. "/" .. t) end
  if ns.ConsumeTarget(13510, "Flask") ~= 2 then error("flask recommendation") end
  ns.SetConsumeTarget(13510, 10)
  local n, custom = ns.ConsumeTarget(13510, "Flask")
  if n ~= 10 or not custom then error("custom target") end
  ns.char.selectedClass, ns.char.selectedSpec, ns.char.listMode = "WARRIOR", "Fury", "consumables"
  ns.RefreshBrowser()
  ns.char.missingOnly = true; ns.RefreshBrowser(); ns.char.missingOnly = false
  ns.SetConsumeTarget(13510, nil)
  C_Item.GetItemCount = saveCount
  ns.char.listMode = "bis"; ns.RefreshBrowser()
end)
check("realistic tab says when the BiS item is what you have", function()
  ns.char.selectedClass, ns.char.selectedSpec, ns.char.listMode = "HUNTER", "Marksmanship", "realistic"
  ns.char.done = {}
  local g = ns.GetGuide("HUNTER", "Marksmanship", 1)
  local bisHead
  for _, r in ipairs(ns.GetGuideRows(g, false, "bis")) do if r.slot == "Head" then bisHead = r.id break end end
  local realHead
  for _, r in ipairs(ns.GetGuideRows(g, false, "realistic")) do if r.slot == "Head" and not r.isAlt then realHead = r break end end
  if not (bisHead and realHead) or realHead.id == bisHead then print("   (same head on both lists, skipped)") ns.char.listMode = "bis" return end
  local saveRO = ns.RefreshOwned; ns.RefreshOwned = function() end   -- keep the fake ownership
  ns.Owned[bisHead] = "equipped"; ns.OwnedVersion = ns.OwnedVersion + 1
  ns.RefreshBrowser()
  ns.RefreshOwned = saveRO
  for _, r in ipairs(ns.GetGuideRows(g, false, "realistic")) do
    if r.slot == "Head" and not r.isAlt then
      if not (r.doneBy and r.doneBy.id == bisHead and r.doneBy.list == "bis") then error("doneBy not set: mode=" .. tostring(_G.ForeverBiSFrame.layoutMode) .. " sel=" .. tostring(ns.char.selectedSpec) .. " lm=" .. tostring(ns.char.listMode) .. " shown=" .. tostring(_G.ForeverBiSFrame and _G.ForeverBiSFrame:IsShown()) .. " key=" .. tostring(r.doneKey) .. " auto=" .. tostring(r.autoDone)) end
    end
  end
  ns.Owned[bisHead] = nil; ns.OwnedVersion = ns.OwnedVersion + 1
  ns.char.listMode = "bis"; ns.RefreshBrowser()
end)
check("click a quest you have: opens the quest log", function()
  local saveN, saveI = C_QuestLog.GetNumQuestLogEntries, C_QuestLog.GetInfo
  C_QuestLog.GetNumQuestLogEntries = function() return 1 end
  C_QuestLog.GetInfo = function() return { title = "In Dreams", questID = 5944 } end
  ns.ScanQuestLog()
  local q = ns.QuestInLog("Quest: In Dreams (Western Plaguelands)")
  if not q or q.id ~= 5944 then error("not found") end
  local opened
  QuestMapFrame_OpenToQuestDetails = function(id) opened = id end
  ns.OpenQuestLog(q)
  if opened ~= 5944 then error("not opened") end
  QuestMapFrame_OpenToQuestDetails = nil
  C_QuestLog.GetNumQuestLogEntries, C_QuestLog.GetInfo = saveN, saveI
  ns.ScanQuestLog()
end)
check("character window: shrunk browser, raid panel only when the browser is closed", function()
  local b = _G.ForeverBiSFrame
  if not b:IsShown() then ns.ToggleBrowser() end
  local saved, hooks, shown = CharacterFrame, {}, false
  CharacterFrame = { IsShown = function() return shown end, GetRight = function() return 400 end,
    HookScript = function(_, ev, f) hooks[ev] = f end, GetHeight = function() return 420 end,
    GetEffectiveScale = function() return 1 end }
  ns.FireEvent("PLAYER_LOGIN")
  shown = true; hooks.OnShow()
  if not b:IsShown() or not b.compact then error("browser should stay, shrunk") end
  if ns.RaidPanelShown() then error("raid panel shown next to the shrunk browser") end
  ns.ToggleBrowser()   -- close the browser: the raid panel takes its place
  ns.UpdateRaidCompanion()   -- (the mock frames don't run OnHide hooks)
  if not ns.RaidPanelShown() then error("raid panel missing once the browser closed") end
  shown = false; hooks.OnHide()
  if ns.RaidPanelShown() then error("raid panel left open") end
  CharacterFrame = saved
end)
check("Phase 1 planning page from the Phase menu", function()
  if not (ns.Previews and ns.Previews[2]) then error("no Phase 1 preview") end
  if ns.LatestPhase() ~= 1 then error("preview became the current phase") end
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"
  ns.char.previewPhase = 2
  local f = _G.ForeverBiSFrame
  if not f:IsShown() then ns.ToggleBrowser() end
  ns.RefreshBrowser()
  if not f.previewPane:IsShown() then error("planning page not shown") end
  local text = f.previewPane.text:GetText() or ""
  for _, want in ipairs({ "Barrow Deeps", "Wildstalker Armor", "Dec 9, 2026", "Spring 2027", "Onyxia attunement" }) do
    if not text:find(want, 1, true) then error("missing: " .. want) end
  end
  ns.char.previewPhase = nil
  ns.RefreshBrowser()
  if f.previewPane:IsShown() then error("planning page still up") end
end)
check("hunter Pet tab and raid check pet tile", function()
  UnitCreatureFamily = function() return "Boar" end
  UnitName = function(u) return u == "pet" and "Grunt" or "Me" end
  local rec, fam, status = ns.PetVerdict("Survival")
  if status ~= "other" or rec.picks[1] ~= "Wolf" then error("verdict " .. tostring(status)) end
  UnitCreatureFamily = function() return "Cat" end
  local _, _, st2 = ns.PetVerdict("Beast Mastery")
  if st2 ~= "best" then error("cat for BM should be best") end
  ns.char.selectedClass, ns.char.selectedSpec, ns.char.listMode = "HUNTER", "Beast Mastery", "pet"
  local f = _G.ForeverBiSFrame
  if not f:IsShown() then ns.ToggleBrowser() end
  ns.RefreshBrowser()
  local text = f.previewPane.text:GetText() or ""
  if not (f.previewPane:IsShown() and text:find("Cat or Raptor", 1, true) and text:find("the top pick", 1, true)) then error("pet page wrong") end
  ns.char.selectedClass, ns.char.selectedSpec = "MAGE", "Fire"
  ns.RefreshBrowser()
  if ns.char.listMode ~= "ranked" then error("pet tab stayed for a mage") end
  UnitCreatureFamily = nil
end)
check("why-place tooltip talks about the item, not websites", function()
  local lines = {}
  local saveAdd = GameTooltip.AddLine
  GameTooltip.AddLine = function(_, t) table.insert(lines, tostring(t)) end
  local first = { id = 252605, slot = "Head", source = "Crafted: Leatherworking", place = 1 }
  local second = { id = 226887, slot = "Head", source = "Dungeon Set 2 quest: Saving the Best for Last", place = 2, isExtra = true,
                   why = "1% hit. In the Realistic set, the easier-to-get gear." }
  local fake = { card = { entry = { places = { first, second } } }, place = 2 }
  if not ns.PodiumWhyEnter then error("no hook (podium not built)") end
  ns.PodiumWhyEnter(fake)
  GameTooltip.AddLine = saveAdd
  local all = table.concat(lines, "\n")
  for _, bad in ipairs({ "conquestcapped", "wowtbc", "guide", "Realistic set", "Ranked" }) do
    if all:find(bad, 1, true) then error("mentions " .. bad .. ":\n" .. all) end
  end
  if not all:find("quest reward", 1, true) then error("no reason given:\n" .. all) end
end)
check("About tab with patch notes (and they match CHANGELOG.md)", function()
  local first = io.open("CHANGELOG.md"):read("a"):match("\n## ([^\n]+)")
  if not (ns.PatchNotes and ns.PatchNotes[1] and ns.PatchNotes[1].version == first) then
    error("Data/PatchNotes.lua is out of date: run python3 tools/gen_patchnotes.py")
  end
  ns.char.listMode = "about"
  local f = _G.ForeverBiSFrame
  if not f:IsShown() then ns.ToggleBrowser() end
  ns.RefreshBrowser()
  local text = f.previewPane.text:GetText() or ""
  if not (f.previewPane:IsShown() and text:find("Patch notes", 1, true) and text:find(first, 1, true)) then error("about page wrong") end
  ns.char.listMode = "ranked"; ns.RefreshBrowser()
end)
check("hunters: a Two Hand group next to one-handers (and the reverse)", function()
  UnitFactionGroup = function() return "Alliance" end
  local g = ns.GetGuide("HUNTER", "Marksmanship", 1)
  local rows = ns.GetRankedRows(g)
  local th
  for _, r in ipairs(rows) do if r.slot == "Two Hand" and r.place == 1 then th = r end end
  if not th or th.id ~= 274419 or not th.weaponChoice or th.isAlt then error("no Two Hand group for Marksmanship") end
  -- it sits with the other weapons, before Ranged
  local posTH, posR
  for i, r in ipairs(rows) do if r == th then posTH = i end if r.slot == "Ranged" and not posR then posR = i end end
  if not (posR and posTH < posR) then error("Two Hand group not before Ranged") end
  local mage = ns.GetRankedRows(ns.GetGuide("MAGE", "Fire", 1))
  for _, r in ipairs(mage) do if r.weaponChoice then error("non-hunters get weapon groups") end end
end)
check("pet training check", function()
  UnitExists = function(u) return u == "pet" end
  local saveLevel = UnitLevel
  UnitLevel = function(u) return u == "pet" and 58 or 60 end
  GetPetLoyalty = function() return "Loyalty Level 5 (Faithful)" end
  GetPetHappiness = function() return 3 end
  GetPetTrainingPoints = function() return 250, 230 end
  local spells = { { "Bite", "Rank 7" }, { "Claw", "Rank 6" }, { "Furious Howl", "Rank 4" }, { "Growl", "Rank 7" },
                   { "Natural Armor", "Rank 10" }, { "Great Stamina", "Rank 4" } }
  UnitCreatureFamily = function() return "Cat" end
  HasPetSpells = function() return #spells end
  BOOKTYPE_PET = "pet"
  GetSpellBookItemName = function(i) return spells[i][1], spells[i][2] end
  local c = ns.PetTrainingCheck()
  local all = table.concat(c.lines, "\n")
  for _, want in ipairs({ "level it to 60", "Faithful", "20 training points unspent", "Claw rank 6: rank 7 from Mongress",
                          "Bite rank 7: the best rank", "unlearn some armor", "Great Stamina rank 4: buy rank 10 from a Pet Trainer" }) do
    if not all:find(want, 1, true) then error("missing: " .. want .. "\n" .. all) end
  end
  if c.issues ~= 6 then error("issues " .. c.issues .. "\n" .. all) end
  UnitCreatureFamily = nil
  UnitExists, GetPetLoyalty, GetPetHappiness, GetPetTrainingPoints, HasPetSpells, GetSpellBookItemName = nil, nil, nil, nil, nil, nil
  UnitLevel = saveLevel
end)
check("open settings + link popup", function() ns.OpenOptions(); ns.ShowLinkPopupForItem(15411) end)
check("gear tab: 1st / 2nd / 3rd place", function()
  if not _G.ForeverBiSFrame:IsShown() then ns.ToggleBrowser() end
  ns.char.selectedClass, ns.char.selectedSpec, ns.char.listMode = "WARRIOR", "Fury", "ranked"
  ns.char.selectedSlot, ns.char.missingOnly, ns.char.hideDone = "All", false, false
  local g = ns.GetGuide("WARRIOR", "Fury", ns.LatestPhase())
  local rows = ns.GetRankedRows(g)
  local places, seen = {}, {}
  for _, r in ipairs(rows) do
    if r.place then
      places[r.slot] = math.max(places[r.slot] or 0, r.place)
      local k = r.slot .. ":" .. r.id
      if seen[k] then error("duplicate item in a slot: " .. k) end
      seen[k] = true
      if r.place > ns.MAX_PLACES then error("too many places for " .. r.slot) end
    end
  end
  if places.Shoulder ~= 3 then error("Fury shoulder should have 3 places, got " .. tostring(places.Shoulder)) end
  if places.Finger ~= 3 then error("Fury rings should have 3 places, got " .. tostring(places.Finger)) end
  -- you wear two rings: both best rings are 1st place, the extras 2nd and 3rd
  local ringMains = {}
  for _, r in ipairs(rows) do
    if r.slot == "Finger" and not r.isExtra then table.insert(ringMains, r.place) end
  end
  if #ringMains ~= 2 or ringMains[1] ~= 1 or ringMains[2] ~= 1 then
    error("both best rings should be 1st place: " .. table.concat(ringMains, ","))
  end
  -- closed slots: only the main rows; open one: its extras appear
  ns.char.showAlts = false; ns.char.expandedSlots = {}
  ns.RefreshBrowser()
  local closed = visibleRows()
  ns.char.expandedSlots.Shoulder = true
  ns.RefreshBrowser()
  local opened = visibleRows()
  if opened ~= closed + 2 then error("opening Shoulder should add 2 rows: " .. closed .. " -> " .. opened) end
  ns.char.showAlts = true
  ns.RefreshBrowser()
  local all = visibleRows()
  if all <= opened then error("2nd & 3rd ticked should show every slot's places") end
  print("   gear rows closed / one open / all:", closed, opened, all)
end)
check("holiday theme on / off", function()
  ns.db.holidayTheme = "on"
  if not ns.HolidayOn() then error("holiday should be on") end
  if not ns.PlaceIcon(1):find("holiday1") then error("1st place should be the tree") end
  ns.RefreshBrowser()
  ns.db.holidayTheme = "off"
  if ns.HolidayOn() or not ns.PlaceIcon(2):find("place2") then error("holiday should be off") end
  ns.RefreshBrowser()
  ns.db.holidayTheme = "auto"
end)
check("gear tab: quiver / ammo follow the bow or gun", function()
  local function quiverPlaces(g)
    local out = {}
    for _, r in ipairs(ns.GetRankedRows(g)) do
      if r.slot == "Quiver" or r.slot == "Ammo" then table.insert(out, r.slot .. r.place .. "=" .. r.id) end
    end
    return table.concat(out, " ")
  end
  local found
  for _, ph in ipairs(ns.PhaseList) do
    local g = ns.GetGuide("HUNTER", "Marksmanship", ph.id)
    if g and quiverPlaces(g) ~= "" then found = g break end
  end
  if not found then error("no hunter guide with a quiver") end
  local _GII, _GIL = GetItemInfoInstant, GetInventoryItemLink
  GetItemInfoInstant = function() return 1, "Weapon", "Bows", "INVTYPE_RANGED", 1, 2, 2 end
  local bow = quiverPlaces(found)
  GetItemInfoInstant = function() return 1, "Weapon", "Guns", "INVTYPE_RANGEDRIGHT", 1, 2, 3 end
  GetInventoryItemLink = function(_, inv) if inv == 18 then return "|Hitem:1|h" end end
  local gun = quiverPlaces(found)
  GetItemInfoInstant, GetInventoryItemLink = _GII, _GIL
  print("   bow:", bow) print("   gun:", gun)
  if bow ~= "Quiver1=19319 Quiver2=2662 Ammo1=12654" then error("bow quiver places wrong: " .. bow) end
  if gun ~= "Quiver1=19320 Quiver2=2663 Ammo1=13377" then error("gun quiver places wrong: " .. gun) end
end)

check("gear tab: podium cards", function()
  if not _G.ForeverBiSFrame:IsShown() then ns.ToggleBrowser() end
  ns.char.selectedClass, ns.char.selectedSpec, ns.char.listMode = "WARRIOR", "Fury", "ranked"
  ns.char.gearView = "podium"
  ns.RefreshBrowser()
  if not _G.ForeverBiSFrame.podiumOn then error("podium view not on") end
  if visibleRows() ~= 0 then error("list rows still shown in podium view") end
  -- hovering a step explains the place
  local card = ns.PodiumCards()[1]
  for place = 1, 3 do
    local why = card.steps[place].why
    local f = why:GetScript("OnEnter")
    if not f then error("step " .. place .. " has no why tooltip") end
    f(why)
  end
  ns.db.holidayTheme = "on"; ns.RefreshBrowser(); ns.SantaFlyBy(); ns.db.holidayTheme = "auto"
  ns.char.gearView = "list"
  ns.RefreshBrowser()
  if _G.ForeverBiSFrame.podiumOn or visibleRows() == 0 then error("list view didn't come back") end
end)
