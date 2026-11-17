-- A message button on every row of the Browse tab that opens a whisper to
-- the listing's leader, and a mark on rows whose leader was whispered in the
-- last hour (any whisper counts, not only via the button).
local addonName, ns = ...

local L, Whispers = ns.L, ns.Whispers

local Rows = { diag = {} }
ns.Rows = Rows

local function store()
  OpenSpotCharDB.whispers = type(OpenSpotCharDB.whispers) == "table" and OpenSpotCharDB.whispers or {}
  return OpenSpotCharDB.whispers
end

-- The search result ID a row frame shows (element data differs per client).
local function resultIDOf(row)
  local data = row.GetElementData and row:GetElementData()
  if type(data) == "number" then return data end
  if type(data) == "table" then return data.resultID or data.searchResultID end
  return rawget(row, "resultID")
end

local function leaderOf(resultID)
  local info = resultID and C_LFGList.GetSearchResultInfo(resultID)
  return info and info.leaderName
end

local function openWhisper(name)
  if type(ChatFrame_SendTell) == "function" then
    ChatFrame_SendTell(name)
  elseif type(ChatFrameUtil) == "table" and ChatFrameUtil.SendTell then
    ChatFrameUtil.SendTell(name)
  end
end

local function decorate(row)
  local id = resultIDOf(row)
  local leader = leaderOf(id)
  local button = rawget(row, "openSpotMessage")
  if not button then
    button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    button:SetSize(64, 18)
    button:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    button:SetFrameLevel((row:GetFrameLevel() or 1) + 5)
    button:SetScript("OnClick", function(self)
      if self.leader then openWhisper(self.leader) end
    end)
    button:SetScript("OnEnter", function(self)
      if not self.leader then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L.MESSAGE_TIP:format(self.leader))
      if self.sentLabel then GameTooltip:AddLine(self.sentLabel, 1, 1, 1) end
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rawset(row, "openSpotMessage", button)
  end
  button.leader = leader
  button:SetShown(leader ~= nil)
  local sentAt = leader and Whispers.SentAt(store(), leader, time())
  button.sentLabel = sentAt and Whispers.Label(sentAt, time()) or nil
  button:SetText(button.sentLabel or L.MESSAGE)
  -- Rows are reused for other listings, so always reset the dimming.
  row:SetAlpha(sentAt and 0.6 or 1)
end

function Rows.Refresh()
  local browse = ns.Browse.Frame()
  local box = browse and browse.ScrollBox
  if type(box) ~= "table" then Rows.diag.box = "none"; return end
  local count = 0
  local function each(row)
    count = count + 1
    local ok, err = pcall(decorate, row)
    if not ok then Rows.diag.error = tostring(err) end
  end
  if box.ForEachFrame then
    box:ForEachFrame(each)
  elseif box.GetFrames then
    for _, row in ipairs(box:GetFrames()) do each(row) end
  end
  Rows.diag.rows = count
end

function Rows.Attach(browse)
  local box = browse.ScrollBox
  if type(box) == "table" and type(box.Update) == "function" then
    hooksecurefunc(box, "Update", Rows.Refresh) -- scrolling and new data
    Rows.diag.hook = "ScrollBox.Update"
  end
  -- Keep "Sent 3m" labels current while the window is open.
  local elapsed = 0
  local ticker = CreateFrame("Frame", nil, browse)
  ticker:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed >= 15 then elapsed = 0; Rows.Refresh() end
  end)
  Rows.Refresh()
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, _, target)
  if event == "PLAYER_LOGIN" then
    Whispers.Prune(store(), time())
  else
    Rows.diag.lastTarget = target
    Whispers.Record(store(), target, time())
    Rows.Refresh()
  end
end)
