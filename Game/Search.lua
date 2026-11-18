-- Talks to C_LFGList for our window: categories and activities, searching,
-- reading results into rows, whispering.
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

-- Activity ID -> name, for the IDs given.
function Search.ActivityNames(ids)
  local names = {}
  for _, id in ipairs(ids) do
    local ok, info = pcall(C.GetActivityInfoTable, id)
    if ok and type(info) == "table" then names[id] = info.fullName or info.shortName end
  end
  return names
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
        activityIDs = ns.Listing.ActivityIDs(info),
        activityNames = Search.ActivityNames(ns.Listing.ActivityIDs(info)),
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

-- Invites a player to the party (recruiting, docs/adr/0006). Returns false
-- when the client offers no invite call.
function Search.Invite(name)
  if not name then return false end
  local invite = type(C_PartyInfo) == "table" and C_PartyInfo.InviteUnit or _G.InviteUnit
  if type(invite) ~= "function" then return false end
  local ok, err = pcall(invite, name)
  Search.diag.lastInvite = { name = name, ok = ok, err = not ok and tostring(err) or nil }
  return ok
end

function Search.Whisper(name)
  if not name then return end
  if type(ChatFrame_SendTell) == "function" then
    ChatFrame_SendTell(name)
  elseif type(ChatFrameUtil) == "table" and ChatFrameUtil.SendTell then
    ChatFrameUtil.SendTell(name)
  end
end
