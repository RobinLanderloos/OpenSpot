local ns, test, eq = ...
local Fit = ns.Fit

-- A 5-man dungeon listing with the given role counts.
local function dungeon(t, h, d, none)
  local n = (t or 0) + (h or 0) + (d or 0) + (none or 0)
  return { kind = "dungeon", numMembers = n, maxMembers = 5,
    counts = { TANK = t or 0, HEALER = h or 0, DAMAGER = d or 0, NOROLE = none or 0 } }
end

local function solo(roles)
  local r = {}
  for _, role in ipairs(roles) do r[role] = true end
  return { mode = "solo", roles = r }
end

test("DPS fits a dungeon group with a DPS spot open", function()
  eq(Fit.Evaluate(dungeon(1, 0, 2), solo({ "DAMAGER" })), true)
end)

test("DPS does not fit a group whose DPS spots are taken", function()
  eq(Fit.Evaluate(dungeon(1, 0, 3), solo({ "DAMAGER" })), false)
end)

test("nothing ticked means every listing fits", function()
  eq(Fit.Evaluate(dungeon(1, 1, 3), solo({})), true)
end)

test("members without a role count as DPS", function()
  eq(Fit.Evaluate(dungeon(1, 0, 2, 1), solo({ "DAMAGER" })), false)
  eq(Fit.Evaluate(dungeon(1, 0, 1, 1), solo({ "DAMAGER" })), true)
end)

test("a full listing never fits, even if roles are off-template", function()
  -- 2 tanks, 0 healers, 3 DPS: 5 of 5, so the healer "spot" isn't real.
  eq(Fit.Evaluate(dungeon(2, 0, 3), solo({ "HEALER" })), false)
end)

test("ticking two roles shows groups needing either", function()
  local want = solo({ "TANK", "DAMAGER" })
  eq(Fit.Evaluate(dungeon(0, 1, 3), want), true, "needs tank")
  eq(Fit.Evaluate(dungeon(1, 1, 2), want), true, "needs dps")
  eq(Fit.Evaluate(dungeon(1, 0, 3), want), false, "needs only healer")
end)

-- Issue 002: raids and other activities, single-player listings.
local function raid(n, max)
  return { kind = "raid", numMembers = n, maxMembers = max,
    counts = { TANK = 2, HEALER = 4, DAMAGER = n - 6, NOROLE = 0 } }
end

test("a raid that isn't full is open for every role", function()
  eq(Fit.Evaluate(raid(18, 20), solo({ "TANK" })), true, "tank")
  eq(Fit.Evaluate(raid(18, 20), solo({ "HEALER" })), true, "healer")
end)

test("a full raid fits nobody", function()
  eq(Fit.Evaluate(raid(20, 20), solo({ "DAMAGER" })), false)
end)

test("single-player listings are hidden while filtering", function()
  local player = dungeon(0, 0, 1)
  player.solo = true
  eq(Fit.Evaluate(player, solo({ "DAMAGER" })), false, "filtering")
  eq(Fit.Evaluate(player, solo({})), true, "no filter")
end)

-- Issue 005: editable template.
test("a custom template changes which groups fit", function()
  local settings = { template = { TANK = 1, HEALER = 2, DAMAGER = 2 } }
  eq(Fit.Evaluate(dungeon(1, 1, 2), solo({ "HEALER" }), settings), true, "2-healer template")
  eq(Fit.Evaluate(dungeon(1, 1, 2), solo({ "DAMAGER" }), settings), false, "only 2 dps")
end)

-- Issue 004: party mode.
local function party(t, h, d, size)
  return { mode = "party", counts = { TANK = t, HEALER = h, DAMAGER = d }, size = size }
end

test("party needs every counted role open", function()
  local want = party(1, 0, 1, 2)
  eq(Fit.Evaluate(dungeon(0, 1, 2), want), true, "needs tank and dps")
  eq(Fit.Evaluate(dungeon(1, 1, 1), want), false, "tank taken")
end)

test("two DPS friends need two DPS spots", function()
  local want = party(0, 0, 2, 2)
  eq(Fit.Evaluate(dungeon(1, 1, 2), want), false, "one dps spot")
  eq(Fit.Evaluate(dungeon(1, 1, 1), want), true, "two dps spots")
end)

test("party needs enough free slots for everyone", function()
  -- Counts only say 1 DPS (third member set no role), but we're 3 people.
  local want = party(0, 0, 1, 3)
  eq(Fit.Evaluate(dungeon(1, 1, 1), want), false, "2 free for 3 people")
  eq(Fit.Evaluate(raid(17, 20), want), true, "raid with 3 free")
end)

test("party with all counts zero doesn't filter", function()
  eq(Fit.Evaluate(dungeon(1, 1, 3), party(0, 0, 0, 2)), true)
end)
