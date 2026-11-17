-- Hooks Forever's Looking For Group window (LFGBrowseFrame): adds the role
-- buttons and the counter, and removes listings that don't fit
-- (docs/adr/0001, 0004).
--
-- Blizzard's browse code is not on disk, so the hook tries the method names
-- the Classic browse frame is known to use and records what it found in
-- ns.Browse.diag for /openspot debug.
local addonName, ns = ...

local Fit, Summary, L = ns.Fit, ns.Summary, ns.L

local Browse = { diag = {} }
ns.Browse = Browse

local browse          -- LFGBrowseFrame once it exists
local bar             -- our controls
local buttons = {}
local allResults      -- the unfiltered result IDs from the last update
local busy            -- true while we redraw, so our own redraw isn't re-filtered
local lastFiltered    -- the table we put in browse.results ourselves
local shown, total = 0, 0

local function fits(resultID, want, settings)
  local ok, listing = pcall(ns.Listing.FromResult, resultID)
  if not ok or not listing then return true end -- never hide what we can't read
  return Fit.Evaluate(listing, want, settings)
end

-- Filters `results` (a list of result IDs) for the current selection.
function Browse.Filter(results)
  local want, settings = ns.CurrentWant(), ns.Settings()
  local out = {}
  for _, id in ipairs(results) do
    if not Fit.IsActive(want) or fits(id, want, settings) then out[#out + 1] = id end
  end
  return out
end

local function updateCounter()
  if not bar then return end
  local text = Summary.Text(shown, total, ns.CurrentWant())
  bar.counter:SetText(text or "")
end

-- Path 1: the frame keeps its result IDs in `self.results` and draws them
-- with UpdateResults (Classic and retail browse panels both do this).
local function filterResultsField()
  if busy or type(browse.results) ~= "table" then return false end
  -- Nested hooks (UpdateResultList calling UpdateResults) would otherwise
  -- read back our own filtered list as if it were the full one.
  if browse.results == lastFiltered then return true end
  allResults = {}
  for i, id in ipairs(browse.results) do allResults[i] = id end
  return true
end

local function redraw()
  if not browse then return end
  if allResults and browse.UpdateResults then
    local filtered = Browse.Filter(allResults)
    shown, total = #filtered, #allResults
    busy = true
    browse.results = filtered
    lastFiltered = filtered
    local ok, err = pcall(browse.UpdateResults, browse)
    busy = false
    if not ok then Browse.diag.redrawError = tostring(err) end
  else
    -- Path 2: no results field; remove rows from the scroll box's data.
    local box = browse.ScrollBox
    local provider = type(box) == "table" and box.GetDataProvider and box:GetDataProvider()
    if type(provider) == "table" and provider.RemoveByPredicate then
      Browse.diag.path = "dataProvider"
      local want, settings = ns.CurrentWant(), ns.Settings()
      total = provider:GetSize()
      if Fit.IsActive(want) then
        busy = true
        provider:RemoveByPredicate(function(data)
          local id = type(data) == "table" and data.resultID
          return id and not fits(id, want, settings)
        end)
        busy = false
      end
      shown = provider:GetSize()
    end
  end
  updateCounter()
end

local function onResultsUpdated()
  if busy then return end
  if filterResultsField() then Browse.diag.path = "results" end
  redraw()
end

local function roleText(role, want)
  if want.mode == "party" then
    return ("%s %d"):format(L[role], want.counts[role] or 0)
  end
  return L[role]
end

local function updateButtons()
  if not bar then return end
  local want = ns.CurrentWant()
  for _, role in ipairs(Fit.ROLES) do
    local b = buttons[role]
    b:SetText(roleText(role, want))
    local on = want.mode == "party" and (want.counts[role] or 0) > 0 or want.mode == "solo" and want.roles[role]
    b:SetAlpha(on and 1 or 0.5)
    if b.LockHighlight then
      if on then b:LockHighlight() else b:UnlockHighlight() end
    end
  end
end

local function onRoleClick(role, mouse)
  if ns.PartySize() > 1 then
    ns.Selection.Adjust(ns.selection, role, mouse == "RightButton" and -1 or 1)
  else
    ns.Selection.Toggle(ns.selection, role)
    ns.SaveSelection()
  end
  ns.Changed()
end

local function buildBar()
  bar = CreateFrame("Frame", "OpenSpotBar", browse)
  bar:SetSize(420, 28)
  bar:SetPoint("TOPLEFT", browse, "BOTTOMLEFT", 8, -2)
  local label = bar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  label:SetPoint("LEFT", 0, 0)
  label:SetText(L.FILTER_LABEL)
  local prev = label
  for _, role in ipairs(Fit.ROLES) do
    local b = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    b:SetSize(72, 22)
    b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(_, mouse) onRoleClick(role, mouse) end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(L[role])
      GameTooltip:AddLine(ns.PartySize() > 1 and L.TIP_PARTY or L.TIP_SOLO, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    buttons[role] = b
    prev = b
  end
  bar.counter = bar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  bar.counter:SetPoint("LEFT", prev, "RIGHT", 10, 0)
end

-- Method names that run after new results arrive, most likely first.
local HOOKS = { "UpdateResultList", "UpdateResults", "RefreshResults" }

function Browse.Attach()
  if browse or not _G.LFGBrowseFrame then return false end
  browse = _G.LFGBrowseFrame
  buildBar()
  local hooked = {}
  for _, name in ipairs(HOOKS) do
    if type(browse[name]) == "function" then
      hooksecurefunc(browse, name, onResultsUpdated)
      hooked[#hooked + 1] = name
    end
  end
  Browse.diag.hooked = table.concat(hooked, ",")
  updateButtons()
  updateCounter()
  return true
end

function Browse.Frame() return browse end
function Browse.Counts() return shown, total end

ns.listeners[#ns.listeners + 1] = function()
  updateButtons()
  redraw()
end

-- The browse window may live in a load-on-demand Blizzard addon.
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function()
  if Browse.Attach() then watcher:UnregisterAllEvents() end
end)
