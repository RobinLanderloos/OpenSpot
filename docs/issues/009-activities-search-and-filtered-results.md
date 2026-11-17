# Activity checklist, Search and filtered results

## State

Built and tested outside the game (2026-11-17); in-game check in issue 014.

## What to build

Category tabs and activity checklist (level-filtered when the client gives ranges, ticks per character), Search button with cooldown, results from LFG_LIST_SEARCH_RESULTS_RECEIVED drawn as rows, filtered by the v1 role buttons/party counts with the Showing X of Y line.

See docs/prd/openspot.md (v0.2) and docs/adr/0005.

## Acceptance criteria

- [ ] Activities filtered by level and remembered (unit tests)
- [ ] Search runs C_LFGList.Search with ticked activities (smoke test)
- [ ] Results filtered by Fit, counter shown (smoke test)

## Blocked by

- docs/issues/008-window-skeleton-and-toggle.md
