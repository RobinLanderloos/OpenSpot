-- /openspot (settings) and /openspot debug (report into SavedVariables).
local addonName, ns = ...

local L, Report = ns.L, ns.Report

local function keys(t)
  local out = {}
  for k, v in pairs(t) do
    local value = type(v) == "table" and ("{" .. table.concat((function()
      local inner = {}
      for ik, iv in pairs(v) do inner[#inner + 1] = tostring(ik) .. "=" .. tostring(iv) end
      return inner
    end)(), ",") .. "}") or tostring(v)
    out[#out + 1] = tostring(k) .. "=" .. value
  end
  table.sort(out)
  return table.concat(out, " ")
end

local function debugReport()
  Report.Start()
  Report.Say("toggle hooked: " .. tostring(ns.Toggle.diag.hooked) .. ", useBlizzard: " .. tostring(ns.db.useBlizzard))
  Report.Add("search: " .. keys(ns.Search.diag.lastSearch or {}) .. " | apply: " .. keys(ns.Search.diag.lastApply or {})
    .. " | lastWhisperTarget: " .. tostring(ns.Search.diag.lastWhisperTarget))
  Report.Add("whispers: " .. keys(OpenSpotCharDB.whispers or {}))
  local want = ns.CurrentWant()
  Report.Say("party size " .. ns.PartySize() .. ", want: " .. keys(want.mode == "party" and want.counts or want.roles)
    .. " mode=" .. want.mode .. ", template: " .. keys(ns.db.template))
  local shown, total = ns.Window.Shown()
  Report.Say("window: showing " .. #shown .. " of " .. total)

  local ok, count, results = pcall(C_LFGList.GetFilteredSearchResults)
  if not ok or type(results) ~= "table" then
    ok, count, results = pcall(C_LFGList.GetSearchResults)
  end
  if not ok or type(results) ~= "table" or #results == 0 then
    Report.Say(L.DEBUG_NO_RESULTS)
  else
    Report.Say(#results .. " results")
    for i, id in ipairs(results) do
      if i > 40 then break end
      local info = C_LFGList.GetSearchResultInfo(id)
      local counts = C_LFGList.GetSearchResultMemberCounts and C_LFGList.GetSearchResultMemberCounts(id)
      local activity = info and ns.Listing.ActivityInfo(info)
      local listing = ns.Listing.FromResult(id)
      local fit = listing and ns.Fit.Evaluate(listing, want, ns.Settings())
      Report.Add(("#%d fit=%s kind=%s members=%s delisted=%s"):format(id, tostring(fit),
        listing and listing.kind or "?", listing and listing.numMembers or "?",
        listing and tostring(listing.delisted) or "?"))
      if info then Report.Add("  info: " .. keys(info)) end
      if counts then Report.Add("  counts: " .. keys(counts)) end
      if activity then
        Report.Add(("  activity: %s max=%s category=%s"):format(tostring(activity.fullName),
          tostring(activity.maxNumPlayers), tostring(activity.categoryID)))
      end
    end
  end
  Report.Finish(ns.db)
  print("|cff40c0ffOpenSpot:|r " .. L.DEBUG_DONE)
end

-- /openspot probe: client facts for our own search window (issue 007).
-- Everything goes into the report only (Report.Add), not into chat.
local function call(fn, ...)
  if type(fn) ~= "function" then return "missing" end
  local result = { pcall(fn, ...) }
  if not result[1] then return "error: " .. tostring(result[2]) end
  local out = {}
  for i = 2, #result do
    local v = result[i]
    out[#out + 1] = type(v) == "table" and ("{" .. keys(v) .. "}") or tostring(v)
  end
  return table.concat(out, " ; ")
end

local function probeReport()
  Report.Start()
  local C = C_LFGList
  Report.Add("player level " .. tostring(UnitLevel("player")))

  local fns = {}
  for k, v in pairs(C) do fns[#fns + 1] = k .. (type(v) == "function" and "" or ("=" .. type(v))) end
  table.sort(fns)
  Report.Add("C_LFGList: " .. table.concat(fns, ","))

  Report.Add("GetAvailableCategories(): " .. call(C.GetAvailableCategories))
  local ok, categories = pcall(C.GetAvailableCategories)
  if ok and type(categories) == "table" then
    for _, cat in ipairs(categories) do
      Report.Add("category " .. cat .. ": " .. call(C.GetLfgCategoryInfo, cat))
      local okA, activities = pcall(C.GetAvailableActivities, cat)
      if okA and type(activities) == "table" then
        Report.Add("  " .. #activities .. " activities")
        for i, id in ipairs(activities) do
          if i > 80 then break end
          Report.Add("  activity " .. id .. ": " .. call(C.GetActivityInfoTable, id))
        end
      end
    end
  end

  -- Per-member info and join calls on one current result with members.
  local okR, _, results = pcall(C.GetFilteredSearchResults)
  local picked
  if okR and type(results) == "table" then
    for _, id in ipairs(results) do
      local info = C.GetSearchResultInfo(id)
      if info and (info.numMembers or 0) > 1 then picked = id; break end
    end
    picked = picked or results[1]
  end
  if picked then
    Report.Add("result " .. picked .. " info: " .. call(C.GetSearchResultInfo, picked))
    for i = 1, 5 do
      Report.Add(("  member %d PlayerInfo: %s"):format(i, call(C.GetSearchResultPlayerInfo, picked, i)))
      Report.Add(("  member %d MemberInfo: %s"):format(i, call(C.GetSearchResultMemberInfo, picked, i)))
    end
    Report.Add("  LeaderInfo: " .. call(C.GetSearchResultLeaderInfo, picked))
  else
    Report.Add("no search results to probe members (search first)")
  end

  -- How the Looking For Group window is toggled.
  local toggles = {}
  for _, name in ipairs({ "LFGVanilla_ToggleFrame", "ToggleGroupFinderFrame", "ToggleLFGParentFrame",
    "PVEFrame_ToggleFrame", "ToggleLFDParentFrame", "GroupFinderVanillaStyle_LoadUI", "ChatFrame_SendTell",
    "LFGParentFrame", "PVEFrame", "LFGMicroButton", "LFDMicroButton", "GroupFinderMicroButton" }) do
    toggles[#toggles + 1] = name .. "=" .. type(_G[name])
  end
  Report.Add("globals: " .. table.concat(toggles, " "))
  local micro = {}
  for k, v in pairs(_G) do
    if type(k) == "string" and k:find("MicroButton$") and type(v) == "table" then micro[#micro + 1] = k end
  end
  table.sort(micro)
  Report.Add("micro buttons: " .. table.concat(micro, ","))
  if GetNumBindings then
    for i = 1, GetNumBindings() do
      local command, _, key1, key2 = GetBinding(i)
      if type(command) == "string" and (command:find("LFG") or command:find("GROUP")) then
        Report.Add(("binding %s = %s %s"):format(command, tostring(key1), tostring(key2)))
      end
    end
  end
  Report.Finish(ns.db)
  print("|cff40c0ffOpenSpot:|r " .. L.DEBUG_DONE)
end

SLASH_OPENSPOT1 = "/openspot"
SlashCmdList.OPENSPOT = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "probe" then
    local ok, err = pcall(probeReport)
    if not ok then
      ns.db.report = { "probe failed: " .. tostring(err) }
      print("|cff40c0ffOpenSpot:|r probe failed: " .. tostring(err))
    end
  elseif msg == "debug" then
    local ok, err = pcall(debugReport)
    if not ok then
      ns.db.report = { "debug failed: " .. tostring(err) }
      print("|cff40c0ffOpenSpot:|r debug failed: " .. tostring(err))
    end
  elseif msg == "settings" or msg == "config" then
    ns.OpenOptions()
  else
    ns.Window.Toggle()
  end
end
