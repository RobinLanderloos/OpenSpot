-- The "Showing X of Y listings (...)" line under the results. Pure.
local addonName, ns = ...

local Summary = {}
ns.Summary = Summary

local ROLES = { "TANK", "HEALER", "DAMAGER" }

-- Returns nil when nothing is being filtered (the line is hidden then).
function Summary.Text(shown, total, want)
  if not ns.Fit.IsActive(want) then return nil end
  local L, parts = ns.L, {}
  if want.mode == "party" then
    for _, role in ipairs(ROLES) do
      local n = want.counts[role] or 0
      if n > 0 then parts[#parts + 1] = n .. " " .. L[role] end
    end
    local what = L.PARTY_OF:format(want.size, table.concat(parts, ", "))
    return L.SHOWING:format(shown, total, what)
  end
  for _, role in ipairs(ROLES) do
    if want.roles[role] then parts[#parts + 1] = L[role] end
  end
  return L.SHOWING:format(shown, total, table.concat(parts, ", "))
end
