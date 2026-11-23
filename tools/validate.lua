--[[
    Data checker for Forever Best In Slot. Not loaded by the game.

    Run from the addon folder with any Lua 5.1+ interpreter:
        lua tools/validate.lua
    It reads the Data\ files listed in ForeverBestInSlot.toc, checks every row,
    and prints a summary per phase (with items new since the previous phase).
]]

local root = (arg and arg[1]) or "."
local ns = {}
wipe = wipe or function(t) for k in pairs(t) do t[k] = nil end end
ns.On = function() end

local function loadFile(rel)
    local chunk, err = loadfile(root .. "/" .. rel:gsub("\\", "/"))
    if not chunk then error(err) end
    chunk("ForeverBestInSlot", ns)
end

local files = {}
for line in io.lines(root .. "/ForeverBestInSlot.toc") do
    line = line:gsub("\r", "")
    if line:match("^Data[\\/].+%.lua$") then table.insert(files, line) end
end
for _, f in ipairs(files) do loadFile(f) end
loadFile("Items.lua")
ns.BuildIndex()

local validSlot = {}
for _, s in ipairs(ns.SlotOrder) do validSlot[s] = true end
local validClass = {}
for _, c in ipairs(ns.ClassOrder) do validClass[c] = true end
local multi = { Finger = 2, Trinket = 2 }

local errors, warnings = 0, 0
local function err(msg) errors = errors + 1; print("ERROR: " .. msg) end
local function warn(msg) warnings = warnings + 1; print("warn:  " .. msg) end

for _, p in ipairs(ns.PhaseList) do
    local seenSpec = {}
    print(string.format("\n== %s (id %d) %s - %d spec lists", p.label, p.id, p.subtitle or "", #p.guides))
    for _, g in ipairs(p.guides) do
        local name = (g.class or "?") .. " " .. (g.spec or "?")
        if not validClass[g.class] then err(p.label .. ": bad class in " .. name) end
        if type(g.spec) ~= "string" then err(p.label .. ": missing spec in " .. name) end
        if seenSpec[name] then err(p.label .. ": " .. name .. " listed twice") end
        seenSpec[name] = true
        if not g.url then warn(p.label .. ": " .. name .. " has no source url") end

        local slotCount = {}
        for i, row in ipairs(g.items) do
            local where = p.label .. " " .. name .. " row " .. i
            if not validSlot[row[1]] then err(where .. ": unknown slot '" .. tostring(row[1]) .. "'") end
            if type(row[2]) ~= "number" or row[2] <= 0 then err(where .. ": item ID must be a positive number") end
            if type(row[3]) ~= "string" or row[3] == "" then err(where .. ": missing source text") end
            if row[4] ~= nil and (type(row[4]) ~= "number" or type(row[5]) ~= "string") then
                err(where .. ": Horde item needs both an ID and a source")
            end
            slotCount[row[1]] = (slotCount[row[1]] or 0) + 1
        end
        for slot, n in pairs(slotCount) do
            if n > (multi[slot] or 1) then warn(p.label .. " " .. name .. ": " .. n .. " rows for " .. slot) end
        end

        -- new since previous phase
        local prev
        for i = #ns.PhaseList, 1, -1 do
            if ns.PhaseList[i].id < p.id then
                prev = ns.GetGuide(g.class, g.spec, ns.PhaseList[i].id)
                if prev then break end
            end
        end
        local newCount = 0
        if prev then
            local set = ns.GuideItemSet(prev)
            for _, row in ipairs(g.items) do if not set[row[2]] then newCount = newCount + 1 end end
        end
        print(string.format("   %-8s %-14s %2d rows%s", g.class, g.spec, #g.items,
            prev and string.format(", %d new vs %s", newCount, ns.PhaseLabel(prev.phase)) or ""))
    end
    -- specs carried over from earlier phases
    for cls, specs in pairs(ns.ClassSpecs) do
        for _, s in ipairs(specs) do
            local g, from = ns.GetGuide(cls, s, p.id)
            if g and from ~= p.id then print(string.format("   %-8s %-14s (uses %s list)", cls, s, ns.PhaseLabel(from))) end
        end
    end
end

print(string.format("\n%d error(s), %d warning(s)", errors, warnings))
if errors > 0 then os.exit(1) end
