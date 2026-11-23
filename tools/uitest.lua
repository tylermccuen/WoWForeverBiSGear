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
local files = {"Core.lua","Data/Phases.lua","Data/Phase1.lua","Items.lua","LinkPopup.lua","Tooltip.lua","Browser.lua","Raid.lua","Minimap.lua","Options.lua"}
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
check("ammo check: arrows in bags for a bow", function()
  local saveInfo, saveCont = C_Item.GetItemInfoInstant, C_Container
  C_Item.GetItemInfoInstant = function(item)
    local id = tonumber(tostring(item):match("item:(%d+)")) or item
    if id == 13023 then return id, "", "", "INVTYPE_RANGED", 0, 2, 2 end   -- bow
    if id == 12654 then return id, "", "", "INVTYPE_AMMO", 0, 6, 2 end     -- arrows
    if id == 13377 then return id, "", "", "INVTYPE_AMMO", 0, 6, 3 end     -- bullets
    return id, "", "", "", 0, 4, 0
  end
  C_Container = { GetContainerNumSlots = function(bag) return bag == 0 and 2 or 0 end,
                  GetContainerItemInfo = function(bag, slot) return { itemID = slot == 1 and 12654 or 13377, stackCount = 200 } end,
                  GetContainerItemID = function() return nil end }
  local ok, text = ns.CheckAmmo({ [18] = "|Hitem:13023:0|h" })
  print("   bow + arrows:", ok, text)
  if not ok then error("arrows not recognised") end
  C_Container.GetContainerItemInfo = function() return { itemID = 13377, stackCount = 200 } end
  ok, text = ns.CheckAmmo({ [18] = "|Hitem:13023:0|h" })
  print("   bow + only bullets:", ok, text)
  if ok then error("bullets accepted for a bow") end
  C_Item.GetItemInfoInstant, C_Container = saveInfo, saveCont
end)
check("raid companion docks with browser", function()
  ns.db.raidCompanion = true
  ns.UpdateRaidCompanion()
end)
check("raid check (every spec)", function()
  local _GetLink = GetInventoryItemLink
  GetInventoryItemLink = function(_, inv) if inv == 1 then return "|cff0070dd|Hitem:226887:0:0|h[Cap]|h|r" end end
  GetHitModifier = function() return 6 end
  GetCritChance = function() return 12.5 end
  UnitDefense = function() return 300, 120 end
  C_Item.GetItemStats = function(link) return { ITEM_MOD_AGILITY_SHORT = 10, ITEM_MOD_STAMINA_SHORT = 8 } end
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
check("open settings + link popup", function() ns.OpenOptions(); ns.ShowLinkPopupForItem(15411) end)
