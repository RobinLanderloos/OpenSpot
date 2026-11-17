-- Which activities to offer in the checklist, and the player's ticks.
-- Pure: activities are plain { id, name, min, max } tables (min/max are the
-- client's suggested levels; 0 = no range given).
local addonName, ns = ...

local Activities = {}
ns.Activities = Activities

Activities.SLACK = 2 -- levels below/above the suggested range still offered

local function hasRange(a) return (a.min or 0) > 0 or (a.max or 0) > 0 end

-- Ranged activities by lowest level, then those without a range, by name.
local function before(a, b)
  local ra, rb = hasRange(a), hasRange(b)
  if ra ~= rb then return ra end
  if ra and a.min ~= b.min then return a.min < b.min end
  return a.name < b.name
end

function Activities.Sorted(list)
  local out = {}
  for i, a in ipairs(list) do out[i] = a end
  table.sort(out, before)
  return out
end

-- Activities around `level`; those without a level range are always offered.
function Activities.Suited(list, level)
  local out = {}
  for _, a in ipairs(list) do
    if not hasRange(a)
      or (level >= (a.min or 0) - Activities.SLACK and level <= (a.max or 0) + Activities.SLACK) then
      out[#out + 1] = a
    end
  end
  return Activities.Sorted(out)
end

-- ticks: activity ID -> true (per-character saved).
function Activities.Toggle(ticks, id)
  ticks[id] = not ticks[id] or nil
end

-- The ticked IDs among `offered`, in the offered order.
function Activities.Ticked(ticks, offered)
  local ids = {}
  for _, a in ipairs(offered) do
    if ticks[a.id] then ids[#ids + 1] = a.id end
  end
  return ids
end
