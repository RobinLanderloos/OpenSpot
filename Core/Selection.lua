-- What the player is looking for: solo role ticks, and per-role counts while
-- in a party (docs/adr/0003). Pure: no game calls.
local addonName, ns = ...

local Selection = {}
ns.Selection = Selection

local ROLES = { "TANK", "HEALER", "DAMAGER" }

-- saved: the table from Selection.Save (per-character SavedVariables), or nil.
function Selection.New(saved)
  local solo = type(saved) == "table" and type(saved.solo) == "table" and saved.solo or {}
  local state = {
    solo = {},
    party = { TANK = 0, HEALER = 0, DAMAGER = 0 },
    partyKey = nil, -- the party's roles the counts were last filled from
    -- What a listed party still needs (docs/adr/0006).
    recruit = { TANK = 0, HEALER = 0, DAMAGER = 0 },
    recruitFree = 0,
    recruitKey = nil,
  }
  for _, role in ipairs(ROLES) do state.solo[role] = solo[role] == true end
  return state
end

function Selection.Save(state)
  local solo = {}
  for _, role in ipairs(ROLES) do solo[role] = state.solo[role] end
  return { solo = solo }
end

function Selection.Toggle(state, role)
  state.solo[role] = not state.solo[role]
end

-- roles: the assigned role of each party member ("TANK", "HEALER",
-- "DAMAGER" or "NONE"). Re-fills the counts only when the roles changed, so a
-- hand adjustment survives roster events that change nothing.
function Selection.SetPartyRoles(state, roles)
  local sorted = {}
  for i, role in ipairs(roles) do sorted[i] = role end
  table.sort(sorted)
  local key = table.concat(sorted, ",")
  if key == state.partyKey then return false end
  state.partyKey = key
  for _, role in ipairs(ROLES) do state.party[role] = 0 end
  for _, role in ipairs(roles) do
    if state.party[role] then state.party[role] = state.party[role] + 1 end
  end
  return true
end

-- roles: as for SetPartyRoles. target = { template = { TANK = n, ... } or
-- nil, maxMembers = n } for the listed activity; without a template any role
-- may fill any free slot. Party members without a role count as DPS. Re-fills
-- only when something changed, so a hand adjustment survives.
function Selection.SetRecruit(state, roles, target)
  local sorted = {}
  for i, role in ipairs(roles) do sorted[i] = role end
  table.sort(sorted)
  local template = target.template
  local key = table.concat(sorted, ",") .. "|" .. tostring(target.maxMembers) .. "|"
    .. (template and (template.TANK .. "," .. template.HEALER .. "," .. template.DAMAGER) or "-")
  if key == state.recruitKey then return false end
  state.recruitKey = key
  local free = math.max(0, (target.maxMembers or 5) - #roles)
  state.recruitFree = free
  local have = { TANK = 0, HEALER = 0, DAMAGER = 0 }
  for _, role in ipairs(roles) do
    local r = have[role] and role or "DAMAGER"
    have[r] = have[r] + 1
  end
  for _, role in ipairs(ROLES) do
    if template then
      state.recruit[role] = math.min(free, math.max(0, (template[role] or 0) - have[role]))
    else
      state.recruit[role] = free
    end
  end
  return true
end

-- recruiting: adjust the needs of a listed party instead of the join counts.
function Selection.Adjust(state, role, delta, recruiting)
  local t = recruiting and state.recruit or state.party
  t[role] = math.max(0, t[role] + delta)
end

-- The `want` table Fit.Evaluate takes. partySize is the number of people in
-- the player's group (1 when solo); recruiting: the party has its own listing.
function Selection.Want(state, partySize, recruiting)
  if (partySize or 1) > 1 and recruiting then
    local needs = {}
    for _, role in ipairs(ROLES) do needs[role] = state.recruit[role] end
    return { mode = "recruit", needs = needs, free = state.recruitFree }
  end
  if (partySize or 1) > 1 then
    local counts = {}
    for _, role in ipairs(ROLES) do counts[role] = state.party[role] end
    return { mode = "party", counts = counts, size = partySize }
  end
  local roles = {}
  for _, role in ipairs(ROLES) do roles[role] = state.solo[role] and true or false end
  return { mode = "solo", roles = roles }
end
