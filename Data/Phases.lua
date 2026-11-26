local _, ns = ...

--[[
    Phase registry. Each Data\PhaseN.lua file calls ns.RegisterPhase{...}.

    A phase file only needs the specs whose lists changed: any spec missing
    from a phase falls back to that spec's most recent earlier phase.
]]

ns.Phases = {}      -- [id] = phase
ns.PhaseList = {}   -- phases sorted by id

ns.ClassOrder = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
ns.SlotOrder = { "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet",
                 "Finger", "Trinket", "Two Hand", "Main Hand", "Off Hand", "Ranged", "Wand", "Relic", "Quiver", "Ammo" }

function ns.RegisterPhase(p)
    assert(type(p.id) == "number", "RegisterPhase: id must be a number")
    assert(not ns.Phases[p.id], "RegisterPhase: phase " .. p.id .. " registered twice")
    p.label = p.label or ("Phase " .. p.id)
    p.guides = p.guides or {}
    for _, g in ipairs(p.guides) do g.phase = p.id end
    ns.Phases[p.id] = p
    table.insert(ns.PhaseList, p)
    table.sort(ns.PhaseList, function(a, b) return a.id < b.id end)
end

-- Upcoming phases with no lists yet: offered in the Phase menu as a planning
-- page (timeline, what's known, how to get ready). They never become the
-- "current" phase and never feed tooltips.
ns.Previews = {}
ns.PreviewList = {}
function ns.RegisterPreview(p)
    ns.Previews[p.id] = p
    table.insert(ns.PreviewList, p)
    table.sort(ns.PreviewList, function(a, b) return a.id < b.id end)
end

function ns.LatestPhase()
    local last = ns.PhaseList[#ns.PhaseList]
    return last and last.id or 1
end

function ns.PhaseLabel(id)
    local p = ns.Phases[id]
    return p and p.label or ("Phase " .. tostring(id))
end

function ns.MultiPhase()
    return #ns.PhaseList > 1
end
