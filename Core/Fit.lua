-- Does a group listing have an open spot for what the player wants?
-- Pure: takes plain tables, makes no game calls (see docs/adr/0002, 0003).
local addonName, ns = ...

local Fit = {}
ns.Fit = Fit

Fit.ROLES = { "TANK", "HEALER", "DAMAGER" }

Fit.DEFAULT_TEMPLATE = { TANK = 1, HEALER = 1, DAMAGER = 3 }

-- Open spots per role: template minus members with that role.
function Fit.OpenSpots(listing, settings)
  local template = settings and settings.template or Fit.DEFAULT_TEMPLATE
  local counts = listing.counts or {}
  local free = math.max(0, (listing.maxMembers or 5) - (listing.numMembers or 0))
  local open = { free = free }
  for _, role in ipairs(Fit.ROLES) do
    if listing.kind == "dungeon" then
      local have = counts[role] or 0
      if role == "DAMAGER" then have = have + (counts.NOROLE or 0) end
      -- Never more open spots than free slots (off-template groups).
      open[role] = math.min(free, math.max(0, (template[role] or 0) - have))
    else
      -- No template for raids and other activities: any free slot will do.
      open[role] = free
    end
  end
  return open
end

-- Is any filtering asked for at all?
function Fit.IsActive(want)
  for _, role in ipairs(Fit.ROLES) do
    if want.mode == "party" then
      if (want.counts[role] or 0) > 0 then return true end
    elseif want.roles[role] then
      return true
    end
  end
  return false
end

-- want = { mode = "solo", roles = { TANK = true, ... } }: any ticked role open.
-- want = { mode = "party", counts = { TANK = n, ... }, size = n }: every count
-- open, and room for the whole party (the player is one of `size`).
function Fit.Evaluate(listing, want, settings)
  if not Fit.IsActive(want) then return true end
  if listing.solo then return false end
  local open = Fit.OpenSpots(listing, settings)
  if want.mode == "party" then
    if open.free < (want.size or 1) then return false end
    for _, role in ipairs(Fit.ROLES) do
      if open[role] < (want.counts[role] or 0) then return false end
    end
    return true
  end
  for _, role in ipairs(Fit.ROLES) do
    if want.roles[role] and open[role] > 0 then return true end
  end
  return false
end
