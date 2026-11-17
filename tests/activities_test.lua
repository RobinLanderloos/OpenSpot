local ns, test, eq = ...
local Activities = ns.Activities

local LIST = {
  { id = 798, name = "Ragefire Chasm", min = 13, max = 18 },
  { id = 800, name = "Shadowfang Keep", min = 20, max = 30 },
  { id = 801, name = "Blackfathom Deeps", min = 24, max = 32 },
  { id = 799, name = "Deadmines", min = 17, max = 26 },
  { id = 1064, name = "Custom", min = 0, max = 0 },
}

local function names(list)
  local out = {}
  for i, a in ipairs(list) do out[i] = a.name end
  return table.concat(out, ",")
end

test("suited activities are those around my level, lowest first", function()
  eq(names(Activities.Suited(LIST, 23)), "Deadmines,Shadowfang Keep,Blackfathom Deeps,Custom")
end)

test("all activities sorted the same way when not limiting by level", function()
  eq(names(Activities.Sorted(LIST)), "Ragefire Chasm,Deadmines,Shadowfang Keep,Blackfathom Deeps,Custom")
end)

test("ticks toggle per activity and only offered ones are searched", function()
  local ticks = {}
  Activities.Toggle(ticks, 800)
  Activities.Toggle(ticks, 798)
  Activities.Toggle(ticks, 798)
  Activities.Toggle(ticks, 801)
  local ids = Activities.Ticked(ticks, Activities.Suited(LIST, 23))
  eq(table.concat(ids, ","), "800,801")
  eq(table.concat(Activities.Ticked(ticks, Activities.Suited(LIST, 15)), ","), "", "none suited at 15")
end)
