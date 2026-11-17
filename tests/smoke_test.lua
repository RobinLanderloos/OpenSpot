-- Load check: runs every file the .toc lists, in order, against a small
-- stand-in for the game. Catches missing files, syntax errors and nil calls
-- before logging in; it does not prove the real client behaves the same.
--   luajit tests/smoke_test.lua
local ADDON = "OpenSpot"

local files = {}
for line in io.lines(ADDON .. ".toc") do
  line = line:gsub("%s+$", "")
  if line ~= "" and not line:match("^#") then files[#files + 1] = (line:gsub("\\", "/")) end
end

-- Widgets: remember scripts, events, text, attributes, size, anchor and
-- shown state; Create* calls give child widgets. Like real frames, unknown
-- methods (capitalised) do nothing and unset fields are nil.
local widgets = {}
local function newWidget(parent)
  local w = { shown = true, scripts = {}, events = {}, parentWidget = parent }
  widgets[#widgets + 1] = w
  return setmetatable(w, { __index = function(self, key)
    if key == "Text" or key == "TitleText" then
      local child = newWidget(self); rawset(self, key, child); return child
    end
    if key == "SetScript" then return function(s, name, fn) s.scripts[name] = fn end end
    if key == "RegisterEvent" or key == "RegisterUnitEvent" then return function(s, name) s.events[name] = true end end
    if key == "UnregisterEvent" then return function(s, name) s.events[name] = nil end end
    if key == "SetText" then return function(s, text) rawset(s, "text", text) end end
    if key == "GetText" then return function(s) return rawget(s, "text") end end
    if key == "SetAttribute" then
      return function(s, name, v) rawset(s, "attrs", rawget(s, "attrs") or {}); s.attrs[name] = v end
    end
    if key == "SetAlpha" then return function(s, a) rawset(s, "alpha", a) end end
    if key == "IsShown" then return function(s) return s.shown end end
    if key == "Show" then return function(s) s.shown = true; if s.scripts.OnShow then s.scripts.OnShow(s) end end end
    if key == "Hide" then return function(s) s.shown = false end end
    if key == "SetShown" then return function(s, v) if v then s:Show() else s:Hide() end end end
    if key == "SetSize" then return function(s, w2, h) rawset(s, "width", w2); rawset(s, "height", h) end end
    if key == "GetWidth" then return function(s) return rawget(s, "width") or 0 end end
    if key == "GetHeight" then return function(s) return rawget(s, "height") or 0 end end
    if key == "SetPoint" then
      return function(s, ...) if not rawget(s, "point") then rawset(s, "point", { ... }) end end
    end
    if key == "ClearAllPoints" then return function(s) rawset(s, "point", nil) end end
    if type(key) == "string" and key:match("^Create") then
      return function(s, name) local c = newWidget(s); if type(name) == "string" then rawset(c, "name", name) end; return c end
    end
    if type(key) == "string" and key:match("^%u") then return function() end end
    return nil
  end })
end

local function fire(event, ...)
  for _, w in ipairs(widgets) do
    if w.events[event] and w.scripts.OnEvent then w.scripts.OnEvent(w, event, ...) end
  end
end

-- Shown only when it and every parent are shown, as in the game.
local function visible(w)
  while w do
    if not rawget(w, "shown") then return false end
    w = rawget(w, "parentWidget")
  end
  return true
end

local function shownTexts()
  local texts = {}
  for _, w in ipairs(widgets) do
    local text = rawget(w, "text")
    if visible(w) and type(text) == "string" then texts[#texts + 1] = text end
  end
  return table.concat(texts, "\n")
end

local function find(predicate)
  for _, w in ipairs(widgets) do if predicate(w) then return w end end
end

-- Timers wait until the test runs them, as the game would on later frames.
local timers = {}
local function runTimers()
  local guard = 0
  while #timers > 0 and guard < 100000 do
    table.remove(timers, 1)()
    guard = guard + 1
  end
end

-- The game globals the addon touches. Add what your files need.
_G.CreateFrame = function(_, name, parent)
  local w = newWidget(parent)
  rawset(w, "name", name)
  return w
end
_G.UIParent = newWidget()
_G.GameTooltip = newWidget()
_G.UISpecialFrames = {}
_G.tinsert = table.insert
_G.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
_G.InCombatLockdown = function() return false end
_G.SlashCmdList = {}
_G.GetBuildInfo = function() return "1.60.1", "70938", "Nov 1 2026", 16001 end
_G.time = function() return 1763100000 end
_G.Settings = {
  RegisterCanvasLayoutCategory = function() return newWidget() end,
  RegisterAddOnCategory = function() end,
  OpenToCategory = function() end,
}
_G.OpenSpotDB = nil
_G.OpenSpotCharDB = nil
_G.date = os.date
_G.hooksecurefunc = function(t, name, fn)
  local orig = t[name]
  rawset(t, name, function(...) local r = { orig(...) }; fn(...); return unpack(r) end)
end

-- Search results: 5-man dungeon groups (activity 799) plus one 40-player
-- listing. Counts are TANK, HEALER, DAMAGER, NOROLE.
local RESULTS = {
  [1] = { 799, 3, { 1, 0, 2, 0 } }, -- needs healer + dps
  [2] = { 799, 4, { 1, 1, 2, 0 } }, -- needs dps
  [3] = { 799, 4, { 0, 1, 3, 0 } }, -- needs tank
  [4] = { 799, 5, { 1, 1, 3, 0 } }, -- full
  [5] = { 799, 1, { 0, 0, 1, 0 } }, -- one member: judged like a group
  [6] = { 900, 15, { 2, 4, 9, 0 } }, -- 40-player listing with room
}
local ACTIVITIES = {
  [798] = { fullName = "Ragefire Chasm", maxNumPlayers = 5, categoryID = 2, minLevelSuggestion = 10, maxLevelSuggestion = 16 },
  [799] = { fullName = "Deadmines", maxNumPlayers = 5, categoryID = 2, minLevelSuggestion = 17, maxLevelSuggestion = 26 },
  [800] = { fullName = "Shadowfang Keep", maxNumPlayers = 5, categoryID = 2, minLevelSuggestion = 20, maxLevelSuggestion = 30 },
  [900] = { fullName = "Molten Core", maxNumPlayers = 40, categoryID = 2, minLevelSuggestion = 0, maxLevelSuggestion = 0 },
}
local searched, applied = nil, {}
_G.C_LFGList = {
  GetAvailableCategories = function() return { 2, 116 } end,
  GetLfgCategoryInfo = function(id) return { name = id == 2 and "Dungeons" or "Quests & Zones" } end,
  GetAvailableActivities = function(cat) if cat == 2 then return { 800, 798, 799, 900 } end return {} end,
  GetActivityInfoTable = function(id) return ACTIVITIES[id] end,
  Search = function(category, _, _, _, _, _, ids) searched = { category = category, ids = table.concat(ids, ",") } end,
  GetSearchResults = function() return 6, { 1, 2, 3, 4, 5, 6 } end,
  GetSearchResultInfo = function(id)
    local r = RESULTS[id]
    return r and { searchResultID = id, activityIDs = { r[1] }, numMembers = r[2], leaderName = "Leader" .. id, age = id * 10 }
  end,
  GetSearchResultMemberCounts = function(id)
    local c = RESULTS[id][3]; return { TANK = c[1], HEALER = c[2], DAMAGER = c[3], NOROLE = c[4] }
  end,
  GetSearchResultPlayerInfo = function(id, i)
    if i > RESULTS[id][2] then return nil end
    return { name = i == 1 and ("Leader" .. id) or ("Member" .. id .. "-" .. i), classFilename = "MAGE",
      className = "Mage", assignedRole = "DAMAGER", level = 20, isLeader = i == 1 }
  end,
  GetAvailableRoles = function() return true, false, true end,
  ApplyToGroup = function(id, t, h, d) applied[id] = { t, h, d } end,
  GetApplicationInfo = function(id) return id, applied[id] and "applied" or "none", "none" end,
  GetFilteredSearchResults = function() return 6, { 1, 2, 3, 4, 5, 6 } end,
}

-- Group state the tests change.
local group = { size = 1, roles = {} }
_G.UnitLevel = function() return 20 end
_G.IsInGroup = function() return group.size > 1 end
_G.IsInRaid = function() return false end
_G.GetNumGroupMembers = function() return group.size > 1 and group.size or 0 end
_G.UnitExists = function(unit) local i = tonumber(unit:match("%d+")); return i and i < group.size end
_G.UnitGroupRolesAssigned = function(unit)
  if unit == "player" then return group.roles[1] or "NONE" end
  return group.roles[(tonumber(unit:match("%d+")) or 0) + 1] or "NONE"
end

-- Blizzard's Looking For Group window and its toggle.
local blizz = CreateFrame("Frame", "LFGParentFrame", UIParent)
blizz:Hide()
rawset(blizz, "HookScript", function(s, name, fn)
  local old = s.scripts[name]
  s.scripts[name] = function(...) if old then old(...) end fn(...) end
end)
rawset(blizz, "Hide", function(s) s.shown = false; if s.scripts.OnHide then s.scripts.OnHide(s) end end)
_G.LFGParentFrame = blizz
_G.HideUIPanel = function(f) f:Hide() end
_G.ToggleGroupFinderFrame = function() if blizz.shown then blizz:Hide() else blizz:Show() end end
local told
_G.ChatFrame_SendTell = function(name) told = name end

-- Load the addon like the client does.
local ns = {}
for _, file in ipairs(files) do
  local chunk, err = loadfile(file)
  if not chunk then error("the .toc lists a file that does not load: " .. tostring(err)) end
  chunk(ADDON, ns)
end
fire("ADDON_LOADED", ADDON)
fire("PLAYER_LOGIN")

local failed = 0
local ran = 0
local function check(name, condition, detail)
  ran = ran + 1
  if not condition then
    failed = failed + 1
    print("FAIL  " .. name .. (detail and ("\n      " .. tostring(detail)) or ""))
  end
end

-- Capture chat output of slash commands.
local said = {}
local realPrint = print
local function slash(command, message)
  said = {}
  _G.print = function(text) said[#said + 1] = tostring(text) end
  local ok, err = pcall(SlashCmdList[command], message)
  _G.print = realPrint
  return ok, ok and table.concat(said, "\n") or tostring(err)
end

local function window() return ns.Window.Frame() end
-- Result IDs on visible rows, sorted, and the row widget for one result.
local function shownIDs()
  local ids = {}
  for _, w in ipairs(widgets) do
    local data = rawget(w, "data")
    if data and rawget(w, "whisper") and visible(w) then ids[#ids + 1] = data.id end
  end
  table.sort(ids)
  return table.concat(ids, ",")
end
local function rowFor(id)
  for _, w in ipairs(widgets) do
    local data = rawget(w, "data")
    if data and data.id == id and rawget(w, "whisper") and visible(w) then return w end
  end
end
local function buttonText(prefix)
  return find(function(w)
    return rawget(w, "text") and w.text:find("^" .. prefix) and w.scripts.OnClick and visible(w)
  end)
end
local function click(w, mouse) w.scripts.OnClick(w, mouse or "LeftButton") end

-- Opening: the Looking For Group key opens ours, not Blizzard's.
ToggleGroupFinderFrame()
check("Looking For Group key opens our window", window() and window().shown, "window not shown")
check("and Blizzard's window is closed again", blizz.shown == false)

check("category tabs", buttonText("Dungeons") ~= nil and buttonText("Quests & Zones") ~= nil, shownTexts())
local texts = shownTexts()
check("activities suited to level 20 are offered, lowest first",
  texts:find("Deadmines", 1, true) and texts:find("Shadowfang Keep", 1, true)
  and not texts:find("Ragefire Chasm", 1, true), texts)

-- Search needs ticked activities.
click(buttonText("Search"))
check("search without ticks asks to tick", shownTexts():find("Tick one or more activities first.", 1, true) ~= nil)
local deadmines = find(function(w) return rawget(w, "activityID") == 799 and visible(w) end)
click(deadmines)
check("ticking an activity searches right away", searched and searched.category == 2 and searched.ids == "799",
  searched and (searched.category .. " " .. searched.ids))
searched = nil
click(buttonText("Search"))
check("Search button searches again", searched and searched.ids == "799")
check("ticked activities saved per character", OpenSpotCharDB.activities[799] == true)
fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
check("nothing ticked shows every listing", shownIDs() == "1,2,3,4,5,6", shownIDs())
check("rows show activity, leader, open spots and age",
  shownTexts():find("Deadmines", 1, true) and shownTexts():find("Leader2", 1, true)
  and shownTexts():find("T0 H0 D1", 1, true) and shownTexts():find("20s", 1, true), shownTexts())

click(buttonText("DPS"))
check("DPS ticked: dps-needing groups and the big listing", shownIDs() == "1,2,5,6", shownIDs())
check("counter shows", shownTexts():find("Showing 4 of 6 listings (DPS)", 1, true) ~= nil, shownTexts())
click(buttonText("Tank"))
check("Tank + DPS", shownIDs() == "1,2,3,5,6", shownIDs())
check("role ticks saved per character", OpenSpotCharDB.selection.solo.TANK == true)

-- Party of 2: tank + dps.
group.size, group.roles = 2, { "TANK", "DAMAGER" }
fire("GROUP_ROSTER_UPDATE")
check("party: needs tank and dps open plus 2 free", shownIDs() == "5,6", shownIDs())
check("party button shows count", buttonText("Tank 1") ~= nil, shownTexts())
click(buttonText("Tank 1"), "RightButton")
check("right-click lowers the count", shownIDs() == "1,5,6", shownIDs())
group.size, group.roles = 1, {}
fire("GROUP_ROSTER_UPDATE")
check("solo ticks are back after leaving", shownIDs() == "1,2,3,5,6", shownIDs())

-- Whisper and join.
local row1 = rowFor(1)
click(row1.whisper)
check("Whisper opens a whisper to the leader", told == "Leader1", told)
fire("CHAT_MSG_WHISPER_INFORM", "hi", "Leader1-Forever")
row1 = rowFor(1)
check("a whispered leader's row is tagged", row1.tag.text == "Whispered <1m", row1.tag.text)
check("and dimmed", rawget(row1, "alpha") == 0.6, rawget(row1, "alpha"))
check("other rows untouched", rowFor(2).tag.text == "" and rawget(rowFor(2), "alpha") == 1)
check("whispers saved per character", OpenSpotCharDB.whispers.leader1 ~= nil)
click(rowFor(2).join)
check("Join applies with the ticked roles", applied[2] and applied[2][1] == true and applied[2][2] == false
  and applied[2][3] == true)
check("the row shows Applied", rowFor(2).join.text == "Applied", rowFor(2).join.text)

-- Unticking the last activity clears the list; ticking again searches.
searched = nil
click(deadmines)
check("unticking the last activity clears the list", shownIDs() == "" and searched == nil, shownIDs())
click(deadmines)
fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
check("ticking again searches and fills the list", searched and shownIDs() == "1,2,3,5,6", shownIDs())

-- Clear unticks this tab's activities and empties the list.
click(buttonText("Clear"))
check("Clear unticks the activities", OpenSpotCharDB.activities[799] == nil)
check("and empties the list", shownIDs() == "", shownIDs())
click(deadmines)
fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
check("ticking after Clear searches again", shownIDs() == "1,2,3,5,6", shownIDs())

-- Sorting by column.
local leaderHeader = find(function(w)
  local label = rawget(w, "label")
  return type(label) == "table" and rawget(label, "text") == "Leader" and w.scripts.OnClick
end)
check("column headers are clickable", leaderHeader ~= nil)
click(leaderHeader)
check("leader column sorts", rowFor(1) ~= nil)

-- Blizzard's window on request.
click(buttonText("Blizzard window"))
check("Blizzard window button opens the original", blizz.shown == true)
check("and closes ours", window().shown == false)
blizz:Hide()
ToggleGroupFinderFrame()
check("afterwards the key opens ours again", window().shown == true and blizz.shown == false)

ns.db.template.HEALER = 2
ns.Changed()
check("template change re-filters", shownIDs() == "1,2,3,5,6", shownIDs())

local ok, out = slash("OPENSPOT", "debug")
check("/openspot debug runs", ok, out)
check("debug report stored", type(OpenSpotDB.report) == "table" and #OpenSpotDB.report > 5,
  OpenSpotDB.report and table.concat(OpenSpotDB.report, "\n"))
ok, out = slash("OPENSPOT", "probe")
check("/openspot probe runs", ok and OpenSpotDB.report and OpenSpotDB.report[2]
  and OpenSpotDB.report[2]:find("player level 20", 1, true), OpenSpotDB.report and table.concat(OpenSpotDB.report or {}, "\n"))
ok, out = slash("OPENSPOT", "settings")
check("/openspot settings runs", ok, out)
ok, out = slash("OPENSPOT", "")
check("/openspot toggles the window", ok and window().shown == false, out)

print("checks run: " .. ran)
io.write(failed == 0 and "load check passed\n" or (failed .. " load checks failed\n"))
os.exit(failed == 0 and 0 or 1)
