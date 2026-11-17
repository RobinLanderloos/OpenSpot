local ns, test, eq = ...
local Whispers = ns.Whispers

test("a whispered leader is remembered", function()
  local store = {}
  Whispers.Record(store, "Densler", 1000)
  eq(Whispers.SentAt(store, "Densler", 1100), 1000)
end)

test("a whisper is forgotten after an hour", function()
  local store = {}
  Whispers.Record(store, "Densler", 1000)
  eq(Whispers.SentAt(store, "Densler", 1000 + 3599), 1000, "just inside")
  eq(Whispers.SentAt(store, "Densler", 1000 + 3600), nil, "expired")
end)

test("names match regardless of case and realm suffix", function()
  local store = {}
  Whispers.Record(store, "densler-Forever", 1000)
  eq(Whispers.SentAt(store, "Densler", 1100), 1000, "plain name")
  eq(Whispers.SentAt(store, "DENSLER-Forever", 1100), 1000, "upper with realm")
end)

test("nothing sent gives nil, and nil names are safe", function()
  local store = {}
  eq(Whispers.SentAt(store, "Nobody", 1000), nil, "unknown")
  eq(Whispers.SentAt(store, nil, 1000), nil, "nil name")
  Whispers.Record(store, nil, 1000)
  eq(next(store), nil, "nil not recorded")
end)

test("prune drops expired entries only", function()
  local store = {}
  Whispers.Record(store, "Old", 1000)
  Whispers.Record(store, "New", 4000)
  Whispers.Prune(store, 4700)
  eq(store.old, nil, "old gone")
  eq(Whispers.SentAt(store, "New", 4700), 4000, "new kept")
end)

test("label shows minutes since sending", function()
  eq(Whispers.Label(1000, 1030), "Whispered <1m")
  eq(Whispers.Label(1000, 1000 + 180), "Whispered 3m")
  eq(Whispers.Label(1000, 1000 + 3599), "Whispered 59m")
end)
