# OpenSpot: show only the groups that have a spot for me

## Problem Statement

Forever's Looking For Group window (Browse tab) lists every group for the chosen activities, plus single players looking for a group. Most of those groups are already full in the role I play: as DPS I scroll past groups that only need a healer, as a tank past groups that already have one. When I'm queueing with a friend, the group also needs room for both of us in our roles, and the window gives no help with that.

## Solution

OpenSpot adds Tank / Healer / DPS toggles to the Browse tab. I tick the open spots I'm looking for, and listings without such a spot disappear. A line says "Showing X of Y" so I know the filter is on. In a party the toggles become counts, pre-filled from my party's assigned roles, and only groups with room for all of us remain. With nothing ticked the window behaves exactly as before.

## User Stories

1. As a DPS player, I want to tick "DPS" in the Browse tab, so that only groups with an open DPS spot are shown.
2. As a tank, I want to tick "Tank", so that groups that already have a tank disappear.
3. As a healer, I want to tick "Healer", so that I only see groups that still need a healer.
4. As a hybrid player, I want to tick both Tank and DPS, so that I see groups needing either role.
5. As a player, I want nothing ticked to mean no filtering, so that the window works as normal when I don't care.
6. As a player, I want my ticks remembered per character, so that my healer alt keeps Healer ticked and my warrior keeps Tank.
7. As a player, I want a "Showing X of Y listings" line, so that I know the filter is active and how much it hides.
8. As a player, I want the counter to name the active roles, so that I can tell at a glance what I'm filtering on.
9. As a player, I want one-member listings judged like any group (Forever can't tell a lone leader from a single player), and delisted listings hidden while filtering, so that I only see listings I could still join.
10. As a player, I want 5-man dungeon groups judged against 1 tank / 1 healer / 3 DPS, so that "open spot" matches normal dungeon groups.
11. As a player, I want to change the 5-man template in settings, so that I can match how my server forms groups (e.g. 2 healers for harder content).
12. As a player, I want members without a role to count as DPS, so that groups with unset roles are judged sensibly.
13. As a player, I want raids and other activities to count as open for every role while not full, so that they aren't wrongly hidden by a 5-man template.
14. As a player, I want full groups always hidden while filtering, so that I never see a group I can't join.
15. As a player in a party, I want the filter to require room for every member, so that we don't apply to a group with space for only one of us.
16. As a player in a party, I want role counts pre-filled from my party's assigned roles, so that I don't have to set them up each time.
17. As a player in a party, I want to adjust those counts by hand, so that I can fix members who set no role or plan to switch.
18. As a player in a party, I want the counts to refresh when someone joins, leaves or changes role, so that the filter stays correct.
19. As a player in a party, I want a listing to need every counted role open (not just one), so that both my friend and I fit.
20. As a player in a party, I want a listing to need enough free slots for the whole party, so that a 4-member group isn't shown to our pair.
21. As a player who leaves a party, I want my solo ticks back, so that I don't have to re-tick them.
22. As a player, I want the filter to re-apply whenever the results refresh, so that new search results are filtered too.
23. As a player, I want searching, applying and whispering to keep working exactly as in Blizzard's window, so that the addon never breaks the group finder.
24. As a player, I want a slash command to open settings, so that I can change the template without hunting for it.
25. As the developer, I want a `/openspot debug` report written to SavedVariables, so that I can see what the client returns without the player copying chat.
27. As a player, I want a message button on each listing that opens a whisper to its leader, so that I can ask for a spot in one click.
28. As a player, I want listings whose leader I whispered in the last hour marked and dimmed (whatever way I whispered), so that I don't message the same leader twice; remembered per character across reloads.
26. As the developer, I want the debug report to list each listing's member counts, activity, size and fit verdict, so that I can check the filter against reality.

## Implementation Decisions

- **Filter layer, not a new window** (ADR 0001). Controls are attached to the Browse tab; results are filtered there. Blizzard keeps search, activity picking and apply.
- **Core/Fit** (deep, pure module): `Fit.Evaluate(listing, want, settings)` returns `fits, reason`. `Fit.OpenSpots(listing, settings)` returns `{ TANK, HEALER, DAMAGER, free }`.
  - `listing`: `{ numMembers, maxMembers, kind = "dungeon" | "raid" | "other", counts = { TANK, HEALER, DAMAGER, NOROLE }, delisted }`.
  - `want`: `{ mode = "solo", roles = { TANK = bool, ... } }` or `{ mode = "party", counts = { TANK = n, ... }, size = n }`.
  - Template rule (ADR 0002): dungeon open = max(0, template - members of that role), unassigned members added to DAMAGER; other kinds = `free` for every role while free > 0.
  - Solo = OR over ticked roles; party = AND over counts plus `free >= size` (every party member needs a slot; ADR 0003). No ticks/zero counts = everything fits.
- **Core/Selection** (pure): holds solo ticks and party counts; `Selection.FromParty(roles)` builds counts from assigned roles (NONE adds nothing); switching party → solo restores the solo ticks; `Selection.Want(state, partySize)` produces the `want` for Fit.
- **Core/Summary** (pure): the "Showing X of Y (Tank, DPS)" text.
- **Game/Listing** adapter: turns a search result ID into a `listing` (from `C_LFGList.GetSearchResultInfo`, `GetSearchResultMemberCounts`, `GetActivityInfoTable` for max size and dungeon/raid kind). Verified in game: one-member listings look exactly like groups, so there is no separate single-player case.
- **Game/Browse** hook: re-filters after each results update of `LFGBrowseFrame`. How rows are removed (filtering the result list before display vs. hooking the update) is the main unknown; first build ships with a debug report to settle it.
- **Game/Controls**: three toggles (solo) / three count steppers (party) and the counter line on the Browse tab.
- **Game/Party**: listens to `GROUP_ROSTER_UPDATE` / role changes and pre-fills counts.
- **Game/Options**: 5-man template numbers; registered with the `Settings` API; `/openspot`.
- **Saved data**: account-wide `OpenSpotDB` (template, report), per-character `OpenSpotCharDB` (solo ticks).
- Non-fits are hidden, not dimmed; no per-row badge (ADR 0004).

## Testing Decisions

- Good tests check behaviour through the module's public functions (a listing in → verdict out), never internals.
- Unit tests (LuaJIT, `tests/run.lua`) for Core/Fit, Core/Selection, Core/Summary, written test-first.
- `tests/smoke_test.lua` loads every .toc file against a game stand-in, fires ADDON_LOADED/PLAYER_LOGIN/GROUP_ROSTER_UPDATE, clicks toggles and checks the counter text.
- Prior art: WhosHiring and DustOrGold `tests/` folders.
- Passing tests outside the game don't prove the Browse tab hook works; that needs an in-game check.

## Out of Scope

- Excluding groups that contain specific classes (v2).
- Player finder: filtering single-player listings by class and role when building your own group (v2).
- Our own browser window.
- Per-dungeon templates, raid role templates.
- Publishing to WowUp Hub / CurseForge (later decision; repo private).

## Further Notes

- On retail, `GetSearchResultMemberCounts` also returns `TANK_REMAINING` etc. If Forever fills those, they could replace the template for dungeons; the debug report records them.
- Searches need a real click, so the addon never searches on its own.
