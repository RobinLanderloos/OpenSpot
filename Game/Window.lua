-- OpenSpot's own group search window (docs/adr/0005): category tabs, an
-- activity checklist, a Search button, role filter, and result rows we draw
-- ourselves (activity, leader, members, open spots, age, Whisper, Join).
local addonName, ns = ...

local L, Fit, Rows, Activities, Whispers, Search =
  ns.L, ns.Fit, ns.Rows, ns.Activities, ns.Whispers, ns.Search

local Window = {}
ns.Window = Window

local ROW_HEIGHT, VISIBLE_ROWS = 24, 14
local WIDTH, HEIGHT = 860, 500
local LEFT_WIDTH = 210

-- Column x positions and widths inside a result row (row width 610). Rows
-- and headers both use this, so they always line up.
local COL = {
  activity = { 4, 132 }, leader = { 140, 104 }, members = { 248, 124 }, count = { 338, 34 },
  open = { 376, 62 }, age = { 442, 44 }, whisper = { 492, 58 }, join = { 554, 54 },
}

local frame
local tabs, activityChecks, roleButtons, rowFrames, headers = {}, {}, {}, {}, {}
local state = { offset = 0, sortBy = "fit", rows = {}, shown = {} }

local function charDB() return OpenSpotCharDB end

local function category()
  local db = charDB()
  return db.category or 2
end

local function ticks()
  local db = charDB()
  db.activities = type(db.activities) == "table" and db.activities or {}
  return db.activities
end

local function whisperStore()
  local db = charDB()
  db.whispers = type(db.whispers) == "table" and db.whispers or {}
  return db.whispers
end

local function suitedOnly()
  return charDB().suitedOnly ~= false
end

local function offered()
  local list = Search.Activities(category())
  if suitedOnly() then return Activities.Suited(list, UnitLevel("player") or 1) end
  return Activities.Sorted(list)
end

-- ---------------------------------------------------------------- helpers
local function button(parent, text, width, height)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, height or 22)
  b:SetText(text)
  return b
end

local function tooltip(widget, title, text)
  widget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    if text then GameTooltip:AddLine(text, 1, 1, 1, true) end
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function classColor(classFilename)
  local c = RAID_CLASS_COLORS and classFilename and RAID_CLASS_COLORS[classFilename]
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end

local function roleText(role)
  return L[role] or L.NO_ROLE
end

-- ------------------------------------------------------------ result rows
local function updateRows()
  if not frame then return end
  local now = time()
  for i = 1, VISIBLE_ROWS do
    local row = rowFrames[i]
    local data = state.shown[i + state.offset]
    if not data then
      row:Hide()
    else
      row.data = data
      row.activity:SetText(data.activity)
      local sentAt = data.leader and Whispers.SentAt(whisperStore(), data.leader, now)
      local leader = data.leader or "?"
      row.leader:SetText(leader)
      row.tag:SetText(sentAt and Whispers.Label(sentAt, now) or "")
      for k = 1, 5 do
        local m, icon = data.members[k], row.classes[k]
        if m then
          local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[m.classFilename]
          if coords then
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            icon:SetVertexColor(1, 1, 1)
          else
            icon:SetColorTexture(classColor(m.classFilename))
          end
          icon:Show()
        else
          icon:Hide()
        end
      end
      row.count:SetText(("%d/%d"):format(data.listing.numMembers, data.listing.maxMembers))
      row.open:SetText(Rows.OpenText(Fit.OpenSpots(data.listing, ns.Settings())))
      row.age:SetText(Rows.AgeText(data.age))
      local status = Search.ApplicationStatus(data.id)
      row.join:SetText(status and (L["STATUS_" .. status] or status) or L.JOIN)
      row.join:SetEnabled(status == nil)
      row.join:SetShown(Search.CanApply())
      row:SetAlpha(sentAt and 0.6 or 1)
      row:Show()
    end
  end
  frame.empty:SetShown(#state.shown == 0)
  local total = #state.shown
  if total > VISIBLE_ROWS then
    frame.position:SetText(L.ROWS_POSITION:format(state.offset + 1,
      math.min(state.offset + VISIBLE_ROWS, total), total))
  else
    frame.position:SetText("")
  end
end

local function refilter()
  if not frame then return end
  local want, settings = ns.CurrentWant(), ns.Settings()
  local shown = {}
  for _, r in ipairs(state.rows) do
    if Fit.Evaluate(r.listing, want, settings) then shown[#shown + 1] = r end
  end
  Rows.Sort(shown, state.sortBy)
  state.shown = shown
  state.offset = math.max(0, math.min(state.offset, #shown - VISIBLE_ROWS))
  frame.counter:SetText(ns.Summary.Text(#shown, #state.rows, want) or L.SHOWING_ALL:format(#state.rows))
  updateRows()
end

function Window.LoadResults()
  state.rows = Search.Rows()
  refilter()
end

local function showMembers(row)
  local data = row.data
  if not data then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:SetText(data.activity)
  if data.comment and data.comment ~= "" then GameTooltip:AddLine(data.comment, 1, 1, 1, true) end
  for _, m in ipairs(data.members) do
    local r, g, b = classColor(m.classFilename)
    GameTooltip:AddDoubleLine(("%s%s"):format(m.name, m.isLeader and (" " .. L.LEADER_MARK) or ""),
      ("%s %s %s"):format(tostring(m.level or "?"), m.class or "", roleText(m.role)), r, g, b, 1, 1, 1)
  end
  GameTooltip:Show()
end

local function buildRow(parent, i)
  local row = CreateFrame("Button", nil, parent)
  row:SetSize(WIDTH - LEFT_WIDTH - 40, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
  local bg = row:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.04 or 0.0)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

  local function text(x, width, font)
    local fs = row:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
    fs:SetPoint("LEFT", row, "LEFT", x, 0)
    fs:SetWidth(width)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
  end
  row.activity = text(COL.activity[1], COL.activity[2])
  row.leader = text(COL.leader[1], COL.leader[2])
  row.tag = text(COL.leader[1], COL.leader[2], "GameFontGreenSmall")
  row.tag:ClearAllPoints()
  row.tag:SetPoint("LEFT", row, "LEFT", COL.leader[1], -6)
  row.leader:ClearAllPoints()
  row.leader:SetPoint("LEFT", row, "LEFT", COL.leader[1], 4)
  row.classes = {}
  for k = 1, 5 do
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", row, "LEFT", COL.members[1] + (k - 1) * 17, 0)
    row.classes[k] = icon
  end
  row.count = text(COL.count[1], COL.count[2])
  row.open = text(COL.open[1], COL.open[2])
  row.age = text(COL.age[1], COL.age[2])

  row.whisper = button(row, L.WHISPER, COL.whisper[2], 20)
  row.whisper:SetPoint("LEFT", row, "LEFT", COL.whisper[1], 0)
  row.whisper:SetScript("OnClick", function() Search.Whisper(row.data and row.data.leader) end)
  row.join = button(row, L.JOIN, COL.join[2], 20)
  row.join:SetPoint("LEFT", row, "LEFT", COL.join[1], 0)
  row.join:SetScript("OnClick", function()
    if row.data then
      Search.Apply(row.data.id, ns.CurrentWant())
      updateRows()
    end
  end)

  row:SetScript("OnEnter", showMembers)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return row
end

-- ------------------------------------------------------ activities pane
local function updateActivities()
  if not frame then return end
  local list, t = offered(), ticks()
  for i, a in ipairs(list) do
    local check = activityChecks[i]
    if not check then
      check = CreateFrame("CheckButton", nil, frame.activityContent, "UICheckButtonTemplate")
      check:SetSize(22, 22)
      check:SetPoint("TOPLEFT", frame.activityContent, "TOPLEFT", 0, -(i - 1) * 22)
      check.label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
      check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
      check.label:SetWidth(LEFT_WIDTH - 50)
      check.label:SetJustifyH("LEFT")
      check:SetScript("OnClick", function(self)
        Activities.Toggle(ticks(), self.activityID)
        self:SetChecked(ticks()[self.activityID] == true)
        -- The tick is a real click, so it may start the search itself.
        Window.RunSearch(true)
      end)
      activityChecks[i] = check
    end
    check.activityID = a.id
    local range = (a.min > 0 or a.max > 0) and (" |cff999999%d-%d|r"):format(a.min, a.max) or ""
    check.label:SetText(a.name .. range)
    check:SetChecked(t[a.id] == true)
    check:Show()
  end
  for i = #list + 1, #activityChecks do activityChecks[i]:Hide() end
  frame.activityContent:SetHeight(math.max(1, #list * 22))
  frame.suited:SetChecked(suitedOnly())
end

local function updateTabs()
  for _, tab in ipairs(tabs) do
    if tab.categoryID == category() then tab:LockHighlight() else tab:UnlockHighlight() end
  end
end

local function updateRoleButtons()
  if not frame then return end
  local want = ns.CurrentWant()
  for _, role in ipairs(Fit.ROLES) do
    local b = roleButtons[role]
    local on
    if want.mode == "party" then
      b:SetText(("%s %d"):format(L[role], want.counts[role] or 0))
      on = (want.counts[role] or 0) > 0
    else
      b:SetText(L[role])
      on = want.roles[role]
    end
    b:SetAlpha(on and 1 or 0.5)
    if on then b:LockHighlight() else b:UnlockHighlight() end
  end
end

local function onRoleClick(role, mouse)
  if ns.PartySize() > 1 then
    ns.Selection.Adjust(ns.selection, role, mouse == "RightButton" and -1 or 1)
  else
    ns.Selection.Toggle(ns.selection, role)
    ns.SaveSelection()
  end
  ns.Changed()
end

-- Search needs a click; the button waits for results (or 3 s) before
-- allowing the next one.
local searching = false
local function setSearching(on)
  searching = on
  frame.search:SetEnabled(not on)
  frame.search:SetText(on and L.SEARCHING or L.SEARCH)
end

-- fromTick: started by (un)ticking an activity. Unticking the last one
-- clears the list instead of asking to tick something.
function Window.RunSearch(fromTick)
  local ids = Activities.Ticked(ticks(), offered())
  if #ids == 0 then
    if fromTick then
      frame.status:SetText("")
      state.rows = {}
      refilter()
    else
      frame.status:SetText(L.TICK_FIRST)
    end
    return
  end
  frame.status:SetText("")
  local ok, err = Search.Run(category(), ids)
  if not ok then
    frame.status:SetText(L.SEARCH_FAILED:format(tostring(err)))
    return
  end
  setSearching(true)
  C_Timer.After(3, function() if searching then setSearching(false) end end)
end

-- ----------------------------------------------------------------- build
local function build()
  frame = CreateFrame("Frame", "OpenSpotWindow", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(WIDTH, HEIGHT)
  frame:SetFrameStrata("HIGH")
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    ns.db.window = { point = point, relPoint = relPoint, x = x, y = y }
  end)
  local pos = ns.db.window
  if type(pos) == "table" and pos.point then
    frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
  else
    frame:SetPoint("CENTER")
  end
  frame:Hide()
  tinsert(UISpecialFrames, "OpenSpotWindow") -- Escape closes it

  if type(frame.TitleText) == "table" then frame.TitleText:SetText(L.WINDOW_TITLE) end

  -- Category tabs.
  local prev
  for _, cat in ipairs(Search.Categories()) do
    local tab = button(frame, cat.name, 120, 22)
    tab.categoryID = cat.id
    if prev then tab:SetPoint("LEFT", prev, "RIGHT", 4, 0) else tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -30) end
    tab:SetScript("OnClick", function()
      charDB().category = cat.id
      updateTabs()
      updateActivities()
    end)
    tabs[#tabs + 1] = tab
    prev = tab
  end

  -- Left: suited-only toggle, activity checklist, Search.
  frame.suited = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  frame.suited:SetSize(22, 22)
  frame.suited:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -58)
  frame.suitedLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  frame.suitedLabel:SetPoint("LEFT", frame.suited, "RIGHT", 2, 0)
  frame.suitedLabel:SetText(L.SUITED_ONLY)
  frame.suited:SetScript("OnClick", function(self)
    charDB().suitedOnly = self:GetChecked() and true or false
    updateActivities()
  end)

  local scroll = CreateFrame("ScrollFrame", "OpenSpotActivityScroll", frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -84)
  scroll:SetSize(LEFT_WIDTH - 30, HEIGHT - 160)
  frame.activityContent = CreateFrame("Frame", nil, scroll)
  frame.activityContent:SetSize(LEFT_WIDTH - 30, 1)
  scroll:SetScrollChild(frame.activityContent)

  frame.search = button(frame, L.SEARCH, LEFT_WIDTH - 24, 26)
  frame.search:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 42)
  frame.search:SetScript("OnClick", function() Window.RunSearch(false) end)
  frame.status = frame:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
  frame.status:SetPoint("BOTTOMLEFT", frame.search, "TOPLEFT", 0, 4)
  frame.status:SetWidth(LEFT_WIDTH - 24)
  frame.status:SetJustifyH("LEFT")

  -- Right: role filter and counter.
  local right = LEFT_WIDTH + 8
  local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  label:SetPoint("TOPLEFT", frame, "TOPLEFT", right, -62)
  label:SetText(L.FILTER_LABEL)
  prev = label
  for _, role in ipairs(Fit.ROLES) do
    local b = button(frame, L[role], 76, 22)
    b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(_, mouse) onRoleClick(role, mouse) end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(L[role])
      GameTooltip:AddLine(ns.PartySize() > 1 and L.TIP_PARTY or L.TIP_SOLO, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    roleButtons[role] = b
    prev = b
  end
  frame.counter = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  frame.counter:SetPoint("LEFT", prev, "RIGHT", 10, 0)

  -- Column headers (click to sort).
  local list = CreateFrame("Frame", nil, frame)
  list:SetPoint("TOPLEFT", frame, "TOPLEFT", right, -116)
  list:SetSize(WIDTH - right - 14, VISIBLE_ROWS * ROW_HEIGHT)
  list:EnableMouseWheel(true)
  list:SetScript("OnMouseWheel", function(_, delta)
    state.offset = math.max(0, math.min(state.offset - delta * 3, #state.shown - VISIBLE_ROWS))
    updateRows()
  end)
  for _, col in ipairs({
    { "activity", L.COL_ACTIVITY, COL.activity }, { "leader", L.COL_LEADER, COL.leader },
    { "members", L.COL_MEMBERS, COL.members }, { "fit", L.COL_OPEN, COL.open }, { "age", L.COL_AGE, COL.age },
  }) do
    local h = CreateFrame("Button", nil, frame)
    h:SetSize(col[3][2], 18)
    h:SetPoint("BOTTOMLEFT", list, "TOPLEFT", col[3][1], 4)
    -- Own left-aligned label: a button's text is centred.
    local label = h:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("LEFT", h, "LEFT", 0, 0)
    label:SetText(col[2])
    h.label = label
    h:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    h:SetScript("OnClick", function()
      state.sortBy = col[1]
      refilter()
    end)
    headers[#headers + 1] = h
  end
  for i = 1, VISIBLE_ROWS do rowFrames[i] = buildRow(list, i) end
  frame.empty = list:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  frame.empty:SetPoint("CENTER", list, "CENTER")
  frame.empty:SetText(L.NO_RESULTS)
  frame.position = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  frame.position:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 4, -6)

  -- Bottom: Blizzard's window and settings.
  local blizzard = button(frame, L.BLIZZARD_WINDOW, 150, 22)
  blizzard:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
  blizzard:SetScript("OnClick", function()
    frame:Hide()
    ns.Toggle.OpenBlizzard()
  end)
  tooltip(blizzard, L.BLIZZARD_WINDOW, L.BLIZZARD_WINDOW_TIP)
  local settings = button(frame, L.SETTINGS, 100, 22)
  settings:SetPoint("RIGHT", blizzard, "LEFT", -6, 0)
  settings:SetScript("OnClick", function() ns.OpenOptions() end)

  frame:SetScript("OnShow", function()
    updateTabs()
    updateActivities()
    updateRoleButtons()
    Window.LoadResults()
  end)

  -- Keep "Whispered 3m" labels current while open.
  local elapsed = 0
  frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed >= 15 then elapsed = 0; updateRows() end
  end)
end

function Window.Toggle()
  if not frame then build() end
  if frame:IsShown() then frame:Hide() else frame:Show() end
end

function Window.Frame() return frame end
function Window.Shown() return state.shown, #state.rows end

ns.listeners[#ns.listeners + 1] = function()
  if frame and frame:IsShown() then
    updateRoleButtons()
    refilter()
  end
end

local reloadPending = false
local events = CreateFrame("Frame")
events:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
events:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
events:RegisterEvent("LFG_LIST_SEARCH_FAILED")
events:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
events:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, a1, a2)
  if event == "PLAYER_LOGIN" then
    Whispers.Prune(whisperStore(), time())
    return
  end
  if event == "CHAT_MSG_WHISPER_INFORM" then
    Search.diag.lastWhisperTarget = a2
    Whispers.Record(whisperStore(), a2, time())
    if frame and frame:IsShown() then updateRows() end
    return
  end
  if not frame then return end
  if event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
    setSearching(false)
    Window.LoadResults()
  elseif event == "LFG_LIST_SEARCH_FAILED" then
    setSearching(false)
    frame.status:SetText(L.SEARCH_FAILED:format(tostring(a1)))
  elseif frame:IsShown() and not reloadPending then
    -- A listing changed (members, delisted) or an application moved on.
    -- These come one per listing, so reload once for a burst of them.
    reloadPending = true
    C_Timer.After(0.3, function()
      reloadPending = false
      if frame:IsShown() then Window.LoadResults() end
    end)
  end
end)
