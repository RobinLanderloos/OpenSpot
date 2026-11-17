# Raids, other activities and single-player listings

## State

Completed (built and tested outside the game; in-game check is issue 006)

## What to build

Activities without a template (raids, other) count as open for every role while not full. Single-player listings are hidden while any role is ticked. Stories 9, 13.

See docs/prd/openspot.md and docs/adr/.

## Acceptance criteria

- [x] Raid/other listing with free slots fits for any ticked role; full one does not (unit tests)
- [x] Single-player listings hidden while filtering, shown with nothing ticked (unit tests)
- [x] Debug report records the fields used to recognise single-player listings

## Blocked by

- docs/issues/001-solo-role-filter-on-the-browse-tab.md
