# Remember ticks per character

## State

Completed (built and tested outside the game; in-game check is issue 006)

## What to build

Solo ticks are saved in per-character SavedVariables and restored on login. Story 6.

See docs/prd/openspot.md and docs/adr/.

## Acceptance criteria

- [x] Ticks survive /reload and differ per character
- [x] Selection state round-trips through its saved form (unit tests)

## Blocked by

- docs/issues/001-solo-role-filter-on-the-browse-tab.md
