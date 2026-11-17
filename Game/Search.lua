-- Talks to C_LFGList for our window: categories and activities, searching,
-- reading results into rows, whispering and applying.
local addonName, ns = ...

local Search = { diag = {} }
ns.Search = Search

local C = C_LFGList

-- { { id, name } } for the category tabs, in the client's order.
function Search.Categories()
  local out = {}
  local ok, ids = pcall(C.GetAvailableCategories)
  if not ok or type(ids) ~= "table" then return out end
  for _, id in ipairs(ids) do
    local okInfo, info = pcall(C.GetLfgCategoryInfo, id)
    out[#out + 1] = { id = id, name = okInfo and type(info) == "table" and info.name or tostring(id) }
  end
  return out
end

-- { { id, name, min, max, maxPlayers } } for one category.
function Search.Activities(categoryID)
  local out = {}
  local ok, ids = pcall(C.GetAvailableActivities, categoryID)
  if not ok or type(ids) ~= "table" then return out end
  for _, id in ipairs(ids) do
    local okInfo, info = pcall(C.GetActivityInfoTable, id)
    if okInfo and type(info) == "table" then
      out[#out + 1] = {
        id = id,
        name = info.fullName or info.shortName or tostring(id),
        min = tonumber(info.minLevelSuggestion) or 0,
        max = tonumber(info.maxLevelSuggestion) or 0,
      }
    end
  end
  return out
end

-- Must run from a click (the client only searches on a hardware event).
function Search.Run(categoryID, activityIDs)
  if #activityIDs == 0 then return false, "no activities" end
  local ok, err = pcall(C.Search, categoryID, 0, 0, nil, false, nil, activityIDs)
  Search.diag.lastSearch = { category = categoryID, activities = table.concat(activityIDs, ","), ok = ok,
    err = not ok and tostring(err) or nil }
  return ok, err
end

-- Members of a result: { { name, class, classFilename, role, level, isLeader } }.
function Search.Members(resultID, count)
  local out = {}
  if type(C.GetSearchResultPlayerInfo) ~= "function" then return out end
  for i = 1, count or 5 do
    local ok, p = pcall(C.GetSearchResultPlayerInfo, resultID, i)
    if ok and type(p) == "table" and p.name then
      out[#out + 1] = { name = p.name, class = p.className, classFilename = p.classFilename,
        role = p.assignedRole, level = p.level, isLeader = p.isLeader }
    end
  end
  return out
end

-- The current results as rows (see Core/Rows), unsorted and unfiltered.
function Search.Rows()
  local ok, _, ids = pcall(C.GetSearchResults)
  if not ok or type(ids) ~= "table" then ok, _, ids = pcall(C.GetFilteredSearchResults) end
  local rows = {}
  if not ok or type(ids) ~= "table" then return rows end
  for _, id in ipairs(ids) do
    local info = C.GetSearchResultInfo(id)
    local listing = info and ns.Listing.FromResult(id)
    if info and listing then
      local activity = ns.Listing.ActivityInfo(info)
      rows[#rows + 1] = {
        id = id,
        activity = activity and (activity.fullName or activity.shortName) or "?",
        leader = info.leaderName,
        age = tonumber(info.age) or 0,
        comment = info.comment,
        listing = listing,
        members = Search.Members(id, listing.numMembers),
      }
    end
  end
  return rows
end

function Search.Whisper(name)
  if not name then return end
  if type(ChatFrame_SendTell) == "function" then
    ChatFrame_SendTell(name)
  elseif type(ChatFrameUtil) == "table" and ChatFrameUtil.SendTell then
    ChatFrameUtil.SendTell(name)
  end
end

local requested = {} -- resultID -> true, this session (request invites have no status to read)

local function requestInvite()
  return type(C_PartyInfo) == "table" and type(C_PartyInfo.RequestInviteFromUnit) == "function"
    and C_PartyInfo.RequestInviteFromUnit or nil
end

function Search.CanApply() return requestInvite() ~= nil or type(C.ApplyToGroup) == "function" end

-- Join: Forever's Classic-style browser asks the leader for an invite
-- (C_PartyInfo.RequestInviteFromUnit); the retail application call
-- (C_LFGList.ApplyToGroup) is only the fallback. Must run from a click.
function Search.Apply(resultID, want, leader)
  local request = requestInvite()
  local ok, err, path
  if request and leader then
    path = "RequestInviteFromUnit"
    ok, err = pcall(request, leader)
  else
    path = "ApplyToGroup"
    local tank, healer, dps
    if want and want.mode == "solo" and ns.Fit.IsActive(want) then
      tank, healer, dps = want.roles.TANK, want.roles.HEALER, want.roles.DAMAGER
    else
      local okRoles, t, h, d = pcall(C.GetAvailableRoles)
      if okRoles then tank, healer, dps = t, h, d else tank, healer, dps = false, false, true end
    end
    ok, err = pcall(C.ApplyToGroup, resultID, tank and true or false, healer and true or false, dps and true or false)
  end
  if ok then requested[resultID] = true end
  Search.diag.lastApply = { id = resultID, leader = leader, path = path, ok = ok, err = not ok and tostring(err) or nil }
  return ok, err
end

-- "applied", "invited", ... or nil when the player hasn't applied.
function Search.ApplicationStatus(resultID)
  if type(C.GetApplicationInfo) ~= "function" then return requested[resultID] and "requested" or nil end
  local ok, _, status, pending = pcall(C.GetApplicationInfo, resultID)
  if not ok then return nil end
  if pending and pending ~= "none" then return pending end
  if status and status ~= "none" then return status end
  return requested[resultID] and "requested" or nil
end
