-- Saved variables, the player's selection and the party.
local addonName, ns = ...

local Fit, Selection = ns.Fit, ns.Selection

ns.listeners = {} -- functions called when the selection or party changes

function ns.Changed()
  for _, fn in ipairs(ns.listeners) do fn() end
end

local function copyTemplate(t)
  local out = {}
  for _, role in ipairs(Fit.ROLES) do
    local n = type(t) == "table" and tonumber(t[role]) or nil
    out[role] = n and math.max(0, math.min(5, math.floor(n))) or Fit.DEFAULT_TEMPLATE[role]
  end
  return out
end

function ns.Settings()
  return { template = ns.db.template }
end

function ns.PartySize()
  if IsInGroup and IsInGroup() then return math.max(1, GetNumGroupMembers() or 1) end
  return 1
end

-- The activity of the player's own listing, or nil when not listed.
function ns.ListedActivity()
  local C = C_LFGList
  if type(C) ~= "table" or type(C.HasActiveEntryInfo) ~= "function" then return nil end
  local okHas, has = pcall(C.HasActiveEntryInfo)
  if not okHas or not has or type(C.GetActiveEntryInfo) ~= "function" then return nil end
  local ok, entry = pcall(C.GetActiveEntryInfo)
  if not ok or type(entry) ~= "table" then return nil end
  if type(entry.activityIDs) == "table" and entry.activityIDs[1] then return entry.activityIDs[1] end
  return entry.activityID
end

-- A listed party looks for players instead of a group (docs/adr/0006).
function ns.Recruiting()
  return ns.PartySize() > 1 and ns.ListedActivity() ~= nil
end

-- Template and size of the listed activity, for Selection.SetRecruit.
local function recruitTarget(activityID)
  local ok, info = pcall(C_LFGList.GetActivityInfoTable, activityID)
  local max = ok and type(info) == "table" and tonumber(info.maxNumPlayers) or 0
  if max == 5 then return { template = ns.db.template, maxMembers = 5 } end
  return { maxMembers = max > 0 and max or 40 }
end

function ns.CurrentWant()
  local recruiting = ns.Recruiting()
  if recruiting then
    -- Cheap when nothing changed; keeps needs current after template edits.
    Selection.SetRecruit(ns.selection, ns.PartyRoles(), recruitTarget(ns.ListedActivity()))
  end
  return Selection.Want(ns.selection, ns.PartySize(), recruiting)
end

-- Lower-cased names of everyone in the player's group, the player included.
function ns.PartyNames()
  local names = {}
  local function add(unit)
    local name = UnitExists(unit) and UnitName(unit)
    local key = ns.Whispers.Key(name)
    if key then names[key] = true end
  end
  add("player")
  local prefix = IsInRaid and IsInRaid() and "raid" or "party"
  for i = 1, GetNumGroupMembers() or 0 do add(prefix .. i) end
  return names
end

function ns.SaveSelection()
  OpenSpotCharDB.selection = Selection.Save(ns.selection)
end

-- Assigned role of everyone in the group, the player included.
function ns.PartyRoles()
  local roles = {}
  if ns.PartySize() <= 1 then return roles end
  local prefix = IsInRaid and IsInRaid() and "raid" or "party"
  if prefix == "party" then roles[1] = UnitGroupRolesAssigned("player") or "NONE" end
  for i = 1, GetNumGroupMembers() do
    local unit = prefix .. i
    if UnitExists(unit) then roles[#roles + 1] = UnitGroupRolesAssigned(unit) or "NONE" end
  end
  return roles
end

-- Entering recruit mode ticks the listed activity (added to the player's
-- ticks) and picks its tab, so the first Search looks for the right people.
local wasRecruiting = false
local function tickListedActivity()
  local recruiting = ns.Recruiting()
  if recruiting and not wasRecruiting then
    local id = ns.ListedActivity()
    local ok, info = pcall(C_LFGList.GetActivityInfoTable, id)
    local db = OpenSpotCharDB
    db.activities = type(db.activities) == "table" and db.activities or {}
    db.activities[id] = true
    if ok and type(info) == "table" and info.categoryID then db.category = info.categoryID end
  end
  wasRecruiting = recruiting
end

local function refreshParty()
  Selection.SetPartyRoles(ns.selection, ns.PartyRoles())
  tickListedActivity()
  ns.Changed()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
frame:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == addonName then
    OpenSpotDB = type(OpenSpotDB) == "table" and OpenSpotDB or {}
    OpenSpotCharDB = type(OpenSpotCharDB) == "table" and OpenSpotCharDB or {}
    ns.db = OpenSpotDB
    ns.db.template = copyTemplate(ns.db.template)
    ns.selection = Selection.New(OpenSpotCharDB.selection)
  elseif event == "PLAYER_LOGIN" then
    refreshParty()
  elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED"
    or event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
    if ns.selection then refreshParty() end
  end
end)
