# Recruit mode for a listed party

## State

Built and tested outside the game (2026-11-17); in-game check in issue 020.

## What to build

In a party with its own listing, OpenSpot recruits: the role buttons hold what the party needs (template of the listed activity minus the party's roles, roleless members as DPS; any free slot for raids/other), labelled 'Looking for:', adjustable by hand until roles change. A listing fits when every member fills a missing spot (pairs and trios included, NOROLE as DPS) and it is no bigger than the free slots. The party's own listing is hidden. Summary: 'Recruiting: 3 DPS · Showing X of Y', or 'Your group is full' with nothing filtered. An unlisted party keeps the ADR 0003 behaviour. Stories 44-48, 50, 54; ADR 0006.

See docs/prd/openspot.md (v0.4) and docs/adr/0006.

## Acceptance criteria

- [x] Needs from template minus party roles, NONE as DPS (unit tests)
- [x] Hand adjustment kept until roles change (unit tests)
- [x] Fit: every member within needs, size within free slots (unit tests)
- [x] No needs: nothing filtered, 'Your group is full' (unit tests)
- [x] Listed party recruits, unlisted party joins (smoke test)
- [x] Own listing hidden (smoke test)

## Blocked by

None - can start immediately
