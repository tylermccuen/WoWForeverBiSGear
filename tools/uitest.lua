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
C_Timer = { After=function(_,f) f() end }
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
local files = {"Core.lua","Data/Phases.lua","Data/Phase1.lua","Data/Crafting.lua","Data/DropRates.lua","Data/Bosses.lua","Data/Quests.lua","Items.lua","LinkPopup.lua","Tooltip.lua","Browser.lua","Raid.lua","Boss.lua","Quests.lua","Minimap.lua","Options.lua"}
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
  ns.UpdateRaidCompanion()
  if not ns.RaidPanelShown() then error("panel not shown with the character window") end
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
    { "Random trash drop (Stratholme, Scholomance, Blackrock Spire)", "Stratholme, Scholomance, Blackrock Spire", "Trash drop" },
    { "Stormpike Guard / Frostwolf Clan (Exalted)", "", "Stormpike Guard / Frostwolf Clan (Exalted)" },
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
check("open settings + link popup", function() ns.OpenOptions(); ns.ShowLinkPopupForItem(15411) end)
