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
  local browse = _G.LFGBrowseFrame
  Report.Say("LFGBrowseFrame: " .. tostring(browse ~= nil) .. ", hooked: " .. tostring(ns.Browse.diag.hooked)
    .. ", path: " .. tostring(ns.Browse.diag.path) .. ", redrawError: " .. tostring(ns.Browse.diag.redrawError))
  if browse then
    local methods = {}
    for k, v in pairs(browse) do
      if type(v) == "function" then methods[#methods + 1] = k end
    end
    table.sort(methods)
    Report.Say("browse methods: " .. table.concat(methods, ","))
    Report.Say("browse.results: " .. type(browse.results)
      .. (type(browse.results) == "table" and (" (" .. #browse.results .. ")") or ""))
  end
  local want = ns.CurrentWant()
  Report.Say("party size " .. ns.PartySize() .. ", want: " .. keys(want.mode == "party" and want.counts or want.roles)
    .. " mode=" .. want.mode .. ", template: " .. keys(ns.db.template))
  local rd = ns.Rows.diag
  Report.Say(("rows: hook=%s rows=%s box=%s lastWhisperTarget=%s error=%s"):format(tostring(rd.hook),
    tostring(rd.rows), tostring(rd.box), tostring(rd.lastTarget), tostring(rd.error)))
  Report.Add("whispers: " .. keys(OpenSpotCharDB.whispers or {}))
  local shown, total = ns.Browse.Counts()
  Report.Say("counter: showing " .. shown .. " of " .. total)

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

SLASH_OPENSPOT1 = "/openspot"
SlashCmdList.OPENSPOT = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "debug" then
    local ok, err = pcall(debugReport)
    if not ok then
      ns.db.report = { "debug failed: " .. tostring(err) }
      print("|cff40c0ffOpenSpot:|r debug failed: " .. tostring(err))
    end
  else
    ns.OpenOptions()
  end
end
