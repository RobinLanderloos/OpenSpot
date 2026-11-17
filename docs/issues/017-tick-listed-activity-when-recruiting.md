# Tick the listing's activity when recruiting starts

## State

Built and tested outside the game (2026-11-17); in-game check in issue 020.

## What to build

When recruit mode starts, the listed activity is ticked (added to the existing ticks) and its category tab chosen, so the first Search finds people for that dungeon. Story 49.

See docs/prd/openspot.md (v0.4) and docs/adr/0006.

## Acceptance criteria

- [x] Listed activity ticked on entering recruit mode, other ticks kept (smoke test)

## Blocked by

- docs/issues/016-recruit-mode-for-a-listed-party.md
