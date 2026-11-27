-- The "Showing X of Y listings (...)" line under the results. Pure.
local addonName, ns = ...

local Summary = {}
ns.Summary = Summary

local ROLES = { "TANK", "HEALER", "DAMAGER" }

-- Returns nil when nothing is being filtered (the line is hidden then).
function Summary.Text(shown, total, want)
  local L, parts = ns.L, {}
  if want.mode == "recruit" then
    if not ns.Fit.IsActive(want) then return L.GROUP_FULL end
    for _, role in ipairs(ROLES) do
      local n = want.needs[role] or 0
      if n > 0 then parts[#parts + 1] = n .. " " .. L[role] end
    end
    return L.RECRUITING:format(table.concat(parts, ", "), shown, total)
  end
  if not ns.Fit.IsActive(want) then return nil end
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

-- "a, b or c" / "a and b": the list joined for a sentence.
local function join(parts, word)
  if #parts <= 1 then return parts[1] or "" end
  return table.concat(parts, ", ", 1, #parts - 1) .. " " .. word .. " " .. parts[#parts]
end

-- The sentence under the role buttons: what OpenSpot looks for now and how
-- the buttons work in this mode (solo ticks, party counts, recruiting).
function Summary.Explain(want)
  local L, parts = ns.L, {}
  if want.mode == "recruit" then
    for _, role in ipairs(ROLES) do
      local n = want.needs[role] or 0
      if n > 0 then parts[#parts + 1] = n .. " " .. L[role] end
    end
    if #parts == 0 then return L.EXPLAIN_RECRUIT_FULL end
    return L.EXPLAIN_RECRUIT:format(join(parts, L.AND))
  end
  if want.mode == "party" then
    for _, role in ipairs(ROLES) do
      local n = want.counts[role] or 0
      if n > 0 then parts[#parts + 1] = n .. " " .. L[role] end
    end
    if #parts == 0 then return L.EXPLAIN_PARTY_ANY:format(want.size, want.size) end
    return L.EXPLAIN_PARTY:format(want.size, want.size, join(parts, L.AND))
  end
  for _, role in ipairs(ROLES) do
    if want.roles[role] then parts[#parts + 1] = L[role] end
  end
  if #parts == 0 then return L.EXPLAIN_SOLO_ALL end
  return L.EXPLAIN_SOLO:format(join(parts, L.OR))
end
