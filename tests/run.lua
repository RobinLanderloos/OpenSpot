-- Unit tests for the pure Core files, outside the game.
--   luajit tests/run.lua        (from the repository root)
-- Files are loaded the way the client loads them: each gets the addon name
-- and the shared namespace table as its `...`.
local ADDON = "OpenSpot"
local ns = {}
for _, file in ipairs({
  "Locales/enUS.lua",
  "Core/Fit.lua",
  "Core/Selection.lua",
  "Core/Summary.lua",
  "Core/Whispers.lua",
  "Core/Activities.lua",
  "Core/Rows.lua",
}) do
  assert(loadfile(file))(ADDON, ns)
end

local passed, failed = 0, 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    print("FAIL  " .. name .. "\n      " .. tostring(err))
  end
end

local function eq(actual, expected, what)
  if actual ~= expected then
    error((what or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

for _, file in ipairs({
  "tests/fit_test.lua",
  "tests/selection_test.lua",
  "tests/summary_test.lua",
  "tests/whispers_test.lua",
  "tests/activities_test.lua",
  "tests/rows_test.lua",
}) do
  assert(loadfile(file))(ns, test, eq)
end

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
