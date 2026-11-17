-- Diagnostic reports the developer can read without the player copying chat.
-- Everything said through ns.Report is printed AND stored in the saved
-- variables; after the player types /reload, read
--   F:\Games\World of Warcraft\_forever_\WTF\Account\137380454#1\SavedVariables\OpenSpot.lua
local addonName, ns = ...

local Report = {}
ns.Report = Report

local lines

function Report.Start()
  local _, build, _, interface = GetBuildInfo()
  lines = { ("build %s, interface %s, %s"):format(tostring(build), tostring(interface),
    date and date("%Y-%m-%d %H:%M") or "") }
end

function Report.Say(text)
  print("|cff40c0ffOpenSpot:|r " .. text)
  if lines then lines[#lines + 1] = text end
end

-- Stored in the report only, not printed (for long per-result dumps).
function Report.Add(text)
  if lines then lines[#lines + 1] = text end
end

function Report.Finish(db)
  db.report = lines
  lines = nil
end
