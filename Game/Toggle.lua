-- The Looking For Group key/button opens Blizzard's window as usual, and
-- OpenSpot's window docks to its right (docs/adr/0005, revised). Only the
-- toggles are watched (hooksecurefunc, nothing replaced): other ways of
-- opening Blizzard's window, like /who results on its Who tab, come alone.
local addonName, ns = ...

local Toggle = { diag = { calls = 0 } }
ns.Toggle = Toggle

local NAMES = { "ToggleGroupFinderFrame", "LFGVanilla_ToggleFrame" }
local hooked = {}
local hidingHooked = false

local function blizzard() return _G.LFGParentFrame end

-- Blizzard's window on its own, e.g. from our "Blizzard window" button.
function Toggle.OpenBlizzard()
  local f = blizzard()
  if f and f:IsShown() then return end
  if f and ShowUIPanel then ShowUIPanel(f) elseif f then f:Show() end
end

local function afterToggle(name)
  Toggle.diag.calls = Toggle.diag.calls + 1
  Toggle.diag.last = name
  local f = blizzard()
  if f and f:IsShown() then
    ns.Window.ShowDocked(f)
  else
    ns.Window.HideDocked()
  end
end

local function hook()
  for _, name in ipairs(NAMES) do
    if type(_G[name]) == "function" and not hooked[name] then
      hooksecurefunc(name, function() afterToggle(name) end)
      hooked[name] = true
    end
  end
  local f = blizzard()
  if f and f.HookScript and not hidingHooked then
    f:HookScript("OnHide", function() ns.Window.HideDocked() end)
    hidingHooked = true
  end
  local names = {}
  for name in pairs(hooked) do names[#names + 1] = name end
  table.sort(names)
  Toggle.diag.hooked = table.concat(names, ",")
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED") -- the toggles may come with a load-on-demand addon
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function()
  hook()
  if hooked.ToggleGroupFinderFrame and hooked.LFGVanilla_ToggleFrame and hidingHooked then
    watcher:UnregisterAllEvents()
  end
end)
