-- The Looking For Group key/button opens OpenSpot's window instead of
-- Blizzard's (docs/adr/0005). Blizzard's window still opens through our
-- "Blizzard window" button, e.g. to list your own group.
local addonName, ns = ...

local Toggle = { diag = {} }
ns.Toggle = Toggle

local allowBlizzard = false -- true while the player asked for Blizzard's window
local hooked = false

local function blizzardFrame() return _G.LFGParentFrame end

function Toggle.OpenBlizzard()
  allowBlizzard = true
  local f = blizzardFrame()
  if f and f:IsShown() then return end
  if type(ToggleGroupFinderFrame) == "function" then
    ToggleGroupFinderFrame()
  elseif type(LFGVanilla_ToggleFrame) == "function" then
    LFGVanilla_ToggleFrame()
  end
end

-- Whenever Blizzard's window opens without the player asking for it (key,
-- micro button, other addons), close it again and toggle ours instead.
local function hook()
  local f = blizzardFrame()
  if hooked or not f or not f.HookScript then return false end
  f:HookScript("OnShow", function(self)
    if allowBlizzard or ns.db.useBlizzard then return end
    if HideUIPanel then HideUIPanel(self) else self:Hide() end
    ns.Window.Toggle()
  end)
  f:HookScript("OnHide", function() allowBlizzard = false end)
  hooked = true
  Toggle.diag.hooked = true
  return true
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function()
  if hook() then watcher:UnregisterAllEvents() end
end)
