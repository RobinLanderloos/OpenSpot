-- Turns a search result from the client into the plain `listing` table that
-- Fit.Evaluate takes.
local addonName, ns = ...

local Listing = {}
ns.Listing = Listing

local function activityID(info)
  if type(info.activityIDs) == "table" and info.activityIDs[1] then return info.activityIDs[1] end
  return info.activityID
end

function Listing.ActivityInfo(info)
  local id = activityID(info)
  if not id or not C_LFGList.GetActivityInfoTable then return nil, id end
  local ok, activity = pcall(C_LFGList.GetActivityInfoTable, id)
  return ok and activity or nil, id
end

-- Returns the listing table, or nil when the result can't be read.
function Listing.FromResult(resultID)
  local info = C_LFGList.GetSearchResultInfo(resultID)
  if not info then return nil end
  local counts = C_LFGList.GetSearchResultMemberCounts and C_LFGList.GetSearchResultMemberCounts(resultID) or {}
  local activity = Listing.ActivityInfo(info)
  local max = activity and tonumber(activity.maxNumPlayers) or 0
  local kind
  if max == 5 then kind = "dungeon"
  elseif max > 5 then kind = "raid"
  else kind = "other"; max = 40 end -- 0 = no limit given
  local numMembers = tonumber(info.numMembers) or 1
  return {
    kind = kind,
    numMembers = numMembers,
    maxMembers = max,
    counts = {
      TANK = tonumber(counts.TANK) or 0,
      HEALER = tonumber(counts.HEALER) or 0,
      DAMAGER = tonumber(counts.DAMAGER) or 0,
      NOROLE = tonumber(counts.NOROLE) or 0,
    },
    -- Unverified on Forever: a one-person listing is a player looking for a
    -- group, not a group. /openspot debug records the raw fields to check.
    solo = numMembers <= 1,
  }
end
