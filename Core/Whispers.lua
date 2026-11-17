-- Which group leaders the player has whispered, and when. Pure: the store is
-- a plain table (per-character SavedVariables) of name key -> time sent.
local addonName, ns = ...

local Whispers = {}
ns.Whispers = Whispers

Whispers.EXPIRE = 3600 -- seconds a whisper stays marked

-- "Densler-Forever" and "densler" are the same leader.
function Whispers.Key(name)
  if type(name) ~= "string" or name == "" then return nil end
  return (name:gsub("%-.*$", "")):lower()
end

function Whispers.Record(store, name, now)
  local key = Whispers.Key(name)
  if key then store[key] = now end
end

-- Time the leader was last whispered, or nil when never or over an hour ago.
function Whispers.SentAt(store, name, now)
  local key = Whispers.Key(name)
  local at = key and store[key]
  if at and now - at < Whispers.EXPIRE then return at end
  return nil
end

function Whispers.Prune(store, now)
  for key, at in pairs(store) do
    if type(at) ~= "number" or now - at >= Whispers.EXPIRE then store[key] = nil end
  end
end

function Whispers.Label(sentAt, now)
  local minutes = math.floor((now - sentAt) / 60)
  if minutes < 1 then return ns.L.SENT_NOW end
  return ns.L.SENT_MINUTES:format(minutes)
end
