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
local files = {"Core.lua","Data/Phases.lua","Data/Phase1.lua","Data/Crafting.lua","Items.lua","LinkPopup.lua","Tooltip.lua","Browser.lua","Raid.lua","Announce.lua","Minimap.lua","Options.lua"}
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
check("raid companion docks with browser", function()
  ns.db.raidCompanion = true
  ns.UpdateRaidCompanion()
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
check("guild announce only for new BiS items", function()
  local sent = {}
  SendChatMessage = function(msg, chan) table.insert(sent, chan .. ": " .. msg) end
  IsInGuild = function() return true end
  InCombatLockdown = function() return false end
  local t = 0; GetTime = function() return t end
  UnitClass = function() return "Hunter", "HUNTER" end
  ns.char.selectedClass, ns.char.selectedSpec = "HUNTER", "Marksmanship"
  ns.db.announceGuild = true
  ns.char.seenItems = nil
  local g = ns.GetGuide("HUNTER","Marksmanship",1)
  local bisA, bisB = g.items[1][2], g.items[2][2]
  local saveWith = ns.WithItem
  ns.WithItem = function(id, cb) cb({ GetItemLink = function() return "[Item " .. id .. "]" end }) end
  -- login: already-owned BiS item is remembered, not announced
  ns.Owned = { [bisA] = "equipped" }
  ns.CheckNewBis()                       -- before readyAt is set: baseline
  if #sent ~= 0 then error("announced at login") end
  -- simulate entering world + 20s
  t = 0; ns.FireEvent("PLAYER_ENTERING_WORLD"); t = 20
  ns.Owned = { [bisA] = "equipped", [bisB] = "bag", [12345] = "bag" }
  ns.CheckNewBis()
  print("   sent:", #sent, sent[1])
  if #sent ~= 1 then error("expected exactly one announcement") end
  ns.CheckNewBis()
  if #sent ~= 1 then error("announced twice") end
  ns.WithItem = saveWith; ns.db.announceGuild = false; ns.Owned = {}
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
check("open settings + link popup", function() ns.OpenOptions(); ns.ShowLinkPopupForItem(15411) end)
