# Solo role filter on the Browse tab

## State

Completed (built and tested outside the game; in-game check is issue 006)

## What to build

Tank / Healer / DPS toggles on Forever's Browse tab. Ticking roles hides 5-man dungeon listings without an open spot for any ticked role (template 1/1/3, unassigned members count as DPS, full groups always hidden). A 'Showing X of Y (roles)' line shows under the list. Nothing ticked = no filtering. Filter re-applies on every results refresh. Ships with `/openspot debug`, writing each listing's raw member counts, activity, size and verdict into SavedVariables. Stories 1-5, 7, 8, 10, 12, 14, 22, 23, 25, 26.

See docs/prd/openspot.md and docs/adr/.

## Acceptance criteria

- [x] Fit evaluates dungeon listings against the 1/1/3 template, OR over ticked roles (unit tests)
- [x] Unassigned members count as DPS; full listings never fit (unit tests)
- [x] Summary text 'Showing X of Y (Tank, DPS)' (unit tests)
- [x] Toggles and counter appear on the Browse tab and hide non-fitting rows (smoke test)
- [x] /openspot debug stores a report in OpenSpotDB.report
- [x] Search, apply and whisper still go through Blizzard's window

## Blocked by

None - can start immediately
