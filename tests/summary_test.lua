local ns, test, eq = ...
local Summary = ns.Summary

local function solo(t, h, d)
  return { mode = "solo", roles = { TANK = t, HEALER = h, DAMAGER = d } }
end

test("solo summary names the ticked roles", function()
  eq(Summary.Text(6, 23, solo(true, false, true)), "Showing 6 of 23 listings (Tank, DPS)")
end)

test("party summary shows counts and party size", function()
  local want = { mode = "party", size = 2, counts = { TANK = 1, HEALER = 0, DAMAGER = 2 } }
  eq(Summary.Text(3, 23, want), "Showing 3 of 23 listings (party of 2: 1 Tank, 2 DPS)")
end)

test("no filter shows nothing", function()
  eq(Summary.Text(23, 23, solo(false, false, false)), nil)
end)
