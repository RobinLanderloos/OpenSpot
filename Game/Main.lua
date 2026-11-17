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

function ns.CurrentWant()
  return Selection.Want(ns.selection, ns.PartySize())
end

function ns.SaveSelection()
  OpenSpotCharDB.selection = Selection.Save(ns.selection)
end

-- Assigned role of everyone in the group, the player included.
local function partyRoles()
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

local function refreshParty()
  Selection.SetPartyRoles(ns.selection, partyRoles())
  ns.Changed()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == addonName then
    OpenSpotDB = type(OpenSpotDB) == "table" and OpenSpotDB or {}
    OpenSpotCharDB = type(OpenSpotCharDB) == "table" and OpenSpotCharDB or {}
    ns.db = OpenSpotDB
    ns.db.template = copyTemplate(ns.db.template)
    ns.selection = Selection.New(OpenSpotCharDB.selection)
  elseif event == "PLAYER_LOGIN" then
    refreshParty()
  elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" then
    if ns.selection then refreshParty() end
  end
end)
