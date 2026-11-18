-- Result rows for our own window: ordering and short texts. Pure.
-- A row is { id, activity, leader, age (seconds), listing (see Fit) , ... }.
local addonName, ns = ...

local Rows = {}
ns.Rows = Rows

function Rows.AgeText(seconds)
  seconds = math.max(0, math.floor(seconds or 0))
  if seconds < 60 then return seconds .. "s" end
  local minutes = math.floor(seconds / 60)
  if minutes < 60 then return minutes .. "m" end
  return ("%dh %dm"):format(math.floor(minutes / 60), minutes % 60)
end

-- Whether a row belongs to one of the ticked activities (`ids`, a list).
-- A listing can be posted for several activities at once; it matches when
-- any of them is ticked. Guards against results from another search (e.g.
-- Blizzard's window) too. Rows with no known activity are kept.
function Rows.InActivities(row, ids)
  local own = row.activityIDs
  if type(own) ~= "table" or #own == 0 then return true end
  for _, want in ipairs(ids) do
    for _, id in ipairs(own) do
      if id == want then return true end
    end
  end
  return false
end

-- The activity a row is shown under: the first of its activities that is
-- ticked (`ids`), else its first. Returns the label ("Ruins of Lordaeron +2"
-- when listed for more) and the names of the other activities.
-- row.activityNames maps activity ID -> name.
function Rows.ActivityLabel(row, ids)
  local own, names = row.activityIDs or {}, row.activityNames or {}
  if #own == 0 then return row.activity or "?", {} end
  local ticked = {}
  for _, id in ipairs(ids or {}) do ticked[id] = true end
  local main = own[1]
  for _, id in ipairs(own) do
    if ticked[id] then main = id; break end
  end
  local others = {}
  for _, id in ipairs(own) do
    if id ~= main then others[#others + 1] = names[id] or tostring(id) end
  end
  local label = names[main] or row.activity or tostring(main)
  if #others > 0 then label = ("%s +%d"):format(label, #others) end
  return label, others
end

function Rows.OpenText(open)
  return ("T%d H%d D%d"):format(open.TANK or 0, open.HEALER or 0, open.DAMAGER or 0)
end

local function members(r) return r.listing and r.listing.numMembers or 0 end
local function lower(s) return (s or ""):lower() end

local ORDERS = {
  -- Fullest groups first (closest to starting), then the newest listing.
  fit = function(a, b)
    if members(a) ~= members(b) then return members(a) > members(b) end
    if (a.age or 0) ~= (b.age or 0) then return (a.age or 0) < (b.age or 0) end
    return a.id < b.id
  end,
  activity = function(a, b)
    if a.activity ~= b.activity then return lower(a.activity) < lower(b.activity) end
    return a.id < b.id
  end,
  leader = function(a, b)
    if lower(a.leader) ~= lower(b.leader) then return lower(a.leader) < lower(b.leader) end
    return a.id < b.id
  end,
  members = function(a, b)
    if members(a) ~= members(b) then return members(a) > members(b) end
    return a.id < b.id
  end,
  age = function(a, b)
    if (a.age or 0) ~= (b.age or 0) then return (a.age or 0) < (b.age or 0) end
    return a.id < b.id
  end,
}

-- Sorts in place. by: "fit" (default), "activity", "leader", "members", "age".
function Rows.Sort(rows, by)
  table.sort(rows, ORDERS[by] or ORDERS.fit)
  return rows
end
