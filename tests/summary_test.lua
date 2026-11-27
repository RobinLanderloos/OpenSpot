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

test("recruit summary names the needs", function()
  local want = { mode = "recruit", free = 3, needs = { TANK = 0, HEALER = 1, DAMAGER = 2 } }
  eq(Summary.Text(4, 22, want), "Recruiting: 1 Healer, 2 DPS · Showing 4 of 22")
end)

test("recruit summary with nothing needed says the group is full", function()
  local want = { mode = "recruit", free = 0, needs = { TANK = 0, HEALER = 0, DAMAGER = 0 } }
  eq(Summary.Text(22, 22, want), "Your group is full")
end)

test("explain: solo, nothing ticked shows everything", function()
  eq(Summary.Explain(solo(false, false, false)),
    "Solo: showing every group. Click a role to show only groups with an open spot for it.")
end)

test("explain: solo ticks are any of them", function()
  eq(Summary.Explain(solo(true, false, false)), "Solo: groups with an open Tank spot. Click a role to add or remove it.")
  eq(Summary.Explain(solo(true, true, true)), "Solo: groups with an open Tank, Healer or DPS spot. Click a role to add or remove it.")
end)

test("explain: an unlisted party needs room for everyone", function()
  local want = { mode = "party", size = 3, counts = { TANK = 1, HEALER = 0, DAMAGER = 2 } }
  eq(Summary.Explain(want),
    "Party of 3, joining: groups with room for all 3 and 1 Tank and 2 DPS spots open. Left-click +1, right-click -1.")
  want.counts = { TANK = 0, HEALER = 0, DAMAGER = 0 }
  eq(Summary.Explain(want), "Party of 3, joining: groups with room for all 3. Left-click a role to require its spots.")
end)

test("explain: a listed party recruits what it misses", function()
  local want = { mode = "recruit", free = 3, needs = { TANK = 0, HEALER = 1, DAMAGER = 2 } }
  eq(Summary.Explain(want),
    "Your party is listed, so recruiting: players to fill 1 Healer and 2 DPS. Left-click +1, right-click -1. Delist to join a group instead.")
  want.needs, want.free = { TANK = 0, HEALER = 0, DAMAGER = 0 }, 0
  eq(Summary.Explain(want), "Your party is listed and full: nothing to recruit. Delist to join a group instead.")
end)
