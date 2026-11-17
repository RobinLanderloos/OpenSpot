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

-- Search results: 5-man dungeon groups (activity 799) plus one raid and one
-- single player. Counts are TANK, HEALER, DAMAGER, NOROLE.
local RESULTS = {
  [1] = { 799, 3, { 1, 0, 2, 0 } }, -- needs healer + dps
  [2] = { 799, 4, { 1, 1, 2, 0 } }, -- needs dps
  [3] = { 799, 4, { 0, 1, 3, 0 } }, -- needs tank
  [4] = { 799, 5, { 1, 1, 3, 0 } }, -- full
  [5] = { 799, 1, { 0, 0, 1, 0 } }, -- one member: judged like a group
  [6] = { 900, 15, { 2, 4, 9, 0 } }, -- raid with room
}
_G.C_LFGList = {
  GetSearchResultInfo = function(id)
    local r = RESULTS[id]; return r and { searchResultID = id, activityIDs = { r[1] }, numMembers = r[2], leaderName = "Leader" .. id }
  end,
  GetSearchResultMemberCounts = function(id)
    local c = RESULTS[id][3]; return { TANK = c[1], HEALER = c[2], DAMAGER = c[3], NOROLE = c[4] }
  end,
  GetActivityInfoTable = function(id)
    if id == 799 then return { fullName = "The Deadmines", maxNumPlayers = 5, categoryID = 2 } end
    return { fullName = "Molten Core", maxNumPlayers = 40, categoryID = 114 }
  end,
  GetFilteredSearchResults = function() return 6, { 1, 2, 3, 4, 5, 6 } end,
}

-- Group state the tests change.
local group = { size = 1, roles = {} }
_G.IsInGroup = function() return group.size > 1 end
_G.IsInRaid = function() return false end
_G.GetNumGroupMembers = function() return group.size > 1 and group.size or 0 end
_G.UnitExists = function(unit) local i = tonumber(unit:match("%d+")); return i and i < group.size end
_G.UnitGroupRolesAssigned = function(unit)
  if unit == "player" then return group.roles[1] or "NONE" end
  return group.roles[(tonumber(unit:match("%d+")) or 0) + 1] or "NONE"
end

-- Stand-in for Forever's browse frame: UpdateResultList fetches, UpdateResults draws.
local drawn
local browse = CreateFrame("Frame", "LFGBrowseFrame", UIParent)
rawset(browse, "UpdateResultList", function(self)
  local _, results = C_LFGList.GetFilteredSearchResults()
  rawset(self, "results", results)
  self:UpdateResults()
end)
-- The scroll box shows one row frame per drawn result.
local rowFrames = {}
local box = CreateFrame("Frame", nil, browse)
rawset(box, "Update", function(self)
  for i, id in ipairs(drawn or {}) do
    local row = rowFrames[i] or CreateFrame("Button", nil, self)
    rowFrames[i] = row
    rawset(row, "GetElementData", function() return { resultID = id } end)
  end
end)
rawset(box, "ForEachFrame", function(self, fn)
  for i = 1, #(drawn or {}) do fn(rowFrames[i]) end
end)
rawset(browse, "ScrollBox", box)
rawset(browse, "UpdateResults", function(self) drawn = rawget(self, "results"); self.ScrollBox:Update() end)
local told
_G.ChatFrame_SendTell = function(name) told = name end
_G.LFGBrowseFrame = browse

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
local function check(name, condition, detail)
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

local function drawnIDs() return table.concat(drawn or {}, ",") end
local function roleButton(label)
  return find(function(w) return rawget(w, "text") and w.text:match("^" .. label) and w.scripts.OnClick end)
end

check("the bar is attached to the browse frame", find(function(w) return rawget(w, "name") == "OpenSpotBar" end) ~= nil)

browse:UpdateResultList()
check("nothing ticked shows everything", drawnIDs() == "1,2,3,4,5,6", drawnIDs())

roleButton("DPS").scripts.OnClick(roleButton("DPS"), "LeftButton")
check("DPS ticked: dps-needing groups and the raid", drawnIDs() == "1,2,5,6", drawnIDs())
check("counter shows", shownTexts():find("Showing 4 of 6 listings (DPS)", 1, true) ~= nil, shownTexts())

browse:UpdateResultList()
check("a new search is filtered too", drawnIDs() == "1,2,5,6", drawnIDs())

roleButton("Tank").scripts.OnClick(roleButton("Tank"), "LeftButton")
check("Tank + DPS", drawnIDs() == "1,2,3,5,6", drawnIDs())
check("ticks saved per character", OpenSpotCharDB.selection.solo.TANK == true)

-- Party of 2: tank + dps.
group.size, group.roles = 2, { "TANK", "DAMAGER" }
fire("GROUP_ROSTER_UPDATE")
check("party: needs tank and dps open plus 2 free", drawnIDs() == "5,6", drawnIDs())
check("party button shows count", roleButton("Tank") and roleButton("Tank").text == "Tank 1", roleButton("Tank") and roleButton("Tank").text)
roleButton("Tank").scripts.OnClick(roleButton("Tank"), "RightButton")
check("right-click lowers the count", drawnIDs() == "1,5,6", drawnIDs())

group.size, group.roles = 1, {}
fire("GROUP_ROSTER_UPDATE")
check("solo ticks are back after leaving", drawnIDs() == "1,2,3,5,6", drawnIDs())

ns.db.template.HEALER = 2
ns.Changed()
check("template change re-filters", drawnIDs() == "1,2,3,5,6", drawnIDs())

local ok, out = slash("OPENSPOT", "debug")
check("/openspot debug runs", ok, out)
check("debug report stored", type(OpenSpotDB.report) == "table" and #OpenSpotDB.report > 5,
  OpenSpotDB.report and table.concat(OpenSpotDB.report, "\n"))
ok, out = slash("OPENSPOT", "")
check("/openspot opens settings", ok, out)

io.write(failed == 0 and "load check passed\n" or (failed .. " load checks failed\n"))
os.exit(failed == 0 and 0 or 1)
