local ns, test, eq = ...
local Rows = ns.Rows

local function listing(t, h, d, n)
  return { kind = "dungeon", numMembers = n or (t + h + d), maxMembers = 5,
    counts = { TANK = t, HEALER = h, DAMAGER = d, NOROLE = 0 } }
end

test("age text is short", function()
  eq(Rows.AgeText(14), "14s")
  eq(Rows.AgeText(240), "4m")
  eq(Rows.AgeText(3900), "1h 5m")
end)

test("best fit first: more members first, then newest", function()
  local rows = {
    { id = 1, listing = listing(1, 0, 0), age = 30 },
    { id = 2, listing = listing(1, 1, 1), age = 300 },
    { id = 3, listing = listing(0, 1, 1), age = 60 },
    { id = 4, listing = listing(1, 0, 1), age = 10 },
  }
  Rows.Sort(rows, "fit")
  local ids = {}
  for i, r in ipairs(rows) do ids[i] = r.id end
  eq(table.concat(ids, ","), "2,4,3,1")
end)

test("column sorts: activity, leader and age", function()
  local rows = {
    { id = 1, activity = "Shadowfang Keep", leader = "Zed", age = 50, listing = listing(1, 0, 0) },
    { id = 2, activity = "Deadmines", leader = "amy", age = 20, listing = listing(1, 0, 0) },
  }
  Rows.Sort(rows, "activity"); eq(rows[1].id, 2, "activity")
  Rows.Sort(rows, "leader"); eq(rows[1].id, 2, "leader ignores case")
  Rows.Sort(rows, "age"); eq(rows[1].id, 2, "age newest first")
end)

test("open spots text per role", function()
  eq(Rows.OpenText({ TANK = 0, HEALER = 1, DAMAGER = 2 }), "T0 H1 D2")
end)

-- Issue 018: while recruiting every shown member fills a need, so the default
-- order puts the listing filling the most needs first, then the newest.
test("recruit order: a DPS trio before a pair before solo players", function()
  local rows = {
    { id = 1, listing = listing(0, 0, 1), age = 10 },
    { id = 2, listing = listing(0, 0, 3), age = 300 },
    { id = 3, listing = listing(0, 0, 2), age = 60 },
    { id = 4, listing = listing(0, 0, 1), age = 5 },
  }
  Rows.Sort(rows)
  eq(rows[1].id .. rows[2].id .. rows[3].id .. rows[4].id, "2341")
end)

test("only rows for the ticked activities", function()
  eq(Rows.InActivities({ activityIDs = { 799 } }, { 798, 799 }), true, "ticked")
  eq(Rows.InActivities({ activityIDs = { 900 } }, { 799 }), false, "other activity")
  eq(Rows.InActivities({ activityIDs = { 900, 799 } }, { 799 }), true, "one of several")
  eq(Rows.InActivities({ activityIDs = { 799 } }, {}), false, "nothing ticked")
  eq(Rows.InActivities({}, { 799 }), true, "unknown activity kept")
end)

test("a row listed for several activities shows the ticked one", function()
  local row = { activity = "Wailing Caverns", activityIDs = { 796, 799, 1982 },
    activityNames = { [796] = "Wailing Caverns", [799] = "Deadmines", [1982] = "Ruins of Lordaeron" } }
  local label, others = Rows.ActivityLabel(row, { 1982 })
  eq(label, "Ruins of Lordaeron +2")
  eq(table.concat(others, ", "), "Wailing Caverns, Deadmines")
  eq((Rows.ActivityLabel(row, {})), "Wailing Caverns +2", "nothing ticked: the first")
  eq((Rows.ActivityLabel({ activity = "Deadmines", activityIDs = { 799 },
    activityNames = { [799] = "Deadmines" } }, { 799 })), "Deadmines", "single activity: no count")
  eq((Rows.ActivityLabel({ activity = "X" }, { 1 })), "X", "unknown activities")
end)
