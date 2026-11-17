# Party mode with pre-filled role counts

## State

Completed (built and tested outside the game; in-game check is issue 006)

## What to build

In a party the toggles become per-role counts, pre-filled from members' assigned roles and adjustable by hand. A listing fits only if every counted role is open and it has free slots for the whole party. Counts refresh on roster/role changes; leaving the party restores solo ticks. Stories 15-21.

See docs/prd/openspot.md and docs/adr/.

## Acceptance criteria

- [x] Counts pre-filled from assigned roles, NONE adds nothing (unit tests)
- [x] AND over counts plus free >= party size - 1 (unit tests)
- [x] Manual adjustment kept until the roster or roles change (unit tests)
- [x] Leaving the party restores solo ticks (unit tests)
- [x] Steppers shown in a party, toggles solo (smoke test)

## Blocked by

- docs/issues/001-solo-role-filter-on-the-browse-tab.md
- docs/issues/003-remember-ticks-per-character.md
