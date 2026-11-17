# Settings panel and slash command

## State

Completed (built and tested outside the game; in-game check is issue 006)

## What to build

Settings panel (Settings API) with the 5-man template numbers; /openspot opens it. Stories 11, 24.

See docs/prd/openspot.md and docs/adr/.

## Acceptance criteria

- [x] Changing the template changes which listings fit (unit tests)
- [x] Template saved account-wide
- [x] /openspot opens settings, /openspot debug still runs the report (smoke test)

## Blocked by

- docs/issues/001-solo-role-filter-on-the-browse-tab.md
