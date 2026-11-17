# Remove the Browse-tab hook and verify everything in game (HITL)

## State

Open

## What to build

Drop the v1 Browse-tab filter, then the user checks the whole window in game (solo and party). Only after this passes is anything published.

See docs/prd/openspot.md (v0.2) and docs/adr/0005.

## Acceptance criteria

- [ ] Old hook removed, tests pass
- [ ] User confirms every feature works in game
- [ ] api-notes and memory updated

## Blocked by

- docs/issues/008-window-skeleton-and-toggle.md
- docs/issues/009-activities-search-and-filtered-results.md
- docs/issues/010-row-columns-and-sorting.md
- docs/issues/011-whisper-button-and-whispered-tracking.md
- docs/issues/012-request-to-join.md
- docs/issues/013-member-tooltip.md
