-- The Looking For Group key/button opens OpenSpot's window instead of
-- Blizzard's (docs/adr/0005). Only the toggle functions they call are taken
-- over: anything else that opens Blizzard's window (its Who tab, which
-- Who's Hiring uses for /who results) still gets Blizzard's window.
local addonName, ns = ...

local Toggle = { diag = { calls = 0 } }
ns.Toggle = Toggle

local NAMES = { "ToggleGroupFinderFrame", "LFGVanilla_ToggleFrame" }
local originals = {}

-- Blizzard's own window, e.g. to list your own group.
function Toggle.OpenBlizzard()
  local f = _G.LFGParentFrame
  if f and f:IsShown() then return end
  for _, name in ipairs(NAMES) do
    if originals[name] then return originals[name]() end
  end
end

local function take()
  local taken = {}
  for _, name in ipairs(NAMES) do
    local fn = _G[name]
    if type(fn) == "function" and not originals[name] then
      originals[name] = fn
      _G[name] = function(...)
        if ns.db and ns.db.useBlizzard then return fn(...) end
        Toggle.diag.calls = Toggle.diag.calls + 1
        Toggle.diag.last = name
        ns.Window.Toggle()
      end
      taken[#taken + 1] = name
    end
  end
  if #taken > 0 then
    Toggle.diag.taken = table.concat(taken, ",")
    Toggle.diag.hooked = true
  end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED") -- the toggles may come with a load-on-demand addon
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function()
  take()
  if originals.ToggleGroupFinderFrame and originals.LFGVanilla_ToggleFrame then
    watcher:UnregisterAllEvents()
  end
end)
