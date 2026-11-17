-- The settings panel (Options > AddOns > OpenSpot), also /openspot.
local addonName, ns = ...

local L, Fit = ns.L, ns.Fit
local category
local refreshers = {}

local function help(widget, title, text)
  widget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    GameTooltip:AddLine(text, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Parses a template number box: whole numbers 0..5, anything else is nil.
function ns.ParseTemplateValue(text)
  local n = tonumber(text)
  if not n or n ~= math.floor(n) or n < 0 or n > 5 then return nil end
  return n
end

local function numberBox(panel, anchor, role)
  local text = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -14)
  text:SetWidth(80)
  text:SetJustifyH("LEFT")
  text:SetText(L[role])
  local box = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
  box:SetSize(40, 20)
  box:SetPoint("LEFT", text, "RIGHT", 8, 0)
  box:SetAutoFocus(false)
  box:SetMaxLetters(1)
  local function show() box:SetText(tostring(ns.db.template[role])) end
  local function apply()
    local value = ns.ParseTemplateValue(box:GetText())
    if value then ns.db.template[role] = value end
    show()
    box:ClearFocus()
    ns.Changed()
  end
  box:SetScript("OnEnterPressed", apply)
  box:SetScript("OnEditFocusLost", apply)
  box:SetScript("OnEscapePressed", function(self) show(); self:ClearFocus() end)
  help(box, L.TEMPLATE_HEADER, L.TEMPLATE_HELP)
  refreshers[#refreshers + 1] = show
  return text
end

local function build()
  local panel = CreateFrame("Frame")
  panel:Hide()
  panel.name = L.SETTINGS_TITLE

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(L.SETTINGS_TITLE)
  local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  sub:SetText(L.HELP)

  local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -20)
  header:SetText(L.TEMPLATE_HEADER)
  local explain = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  explain:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
  explain:SetWidth(520)
  explain:SetJustifyH("LEFT")
  explain:SetText(L.TEMPLATE_HELP)

  local last = explain
  for _, role in ipairs(Fit.ROLES) do last = numberBox(panel, last, role) end

  panel:SetScript("OnShow", function()
    for _, fn in ipairs(refreshers) do fn() end
  end)

  category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
  if category then Settings.OpenToCategory(category:GetID()) end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  local ok, err = pcall(build)
  if not ok then print("|cff40c0ffOpenSpot:|r the settings panel could not be built: " .. tostring(err)) end
end)
