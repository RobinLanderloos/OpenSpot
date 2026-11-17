# Recruit sort and no Open column

## State

Built and tested outside the game (2026-11-17); in-game check in issue 020.

## What to build

While recruiting the Open spots column and header are hidden (they describe the other listing, not us) and the default sort puts listings filling the most needs first, then the newest. Story 51.

See docs/prd/openspot.md (v0.4) and docs/adr/0006.

## Acceptance criteria

- [x] Open column hidden while recruiting (smoke test)
- [x] Biggest fitting listing first (unit test)

## Blocked by

- docs/issues/016-recruit-mode-for-a-listed-party.md
