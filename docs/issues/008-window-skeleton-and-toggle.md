# Window skeleton opened by the Looking For Group key

## State

Open

## What to build

OpenSpot's own movable window (Escape closes, position saved), opened by the Looking For Group key/button and /openspot. A 'Blizzard window' button opens the original. Settings move to a button in the window.

See docs/prd/openspot.md (v0.2) and docs/adr/0005.

## Acceptance criteria

- [ ] Looking For Group key opens our window (or fallback: command + button on Blizzard's window, per ADR 0005)
- [ ] Blizzard window button opens the original
- [ ] Smoke test opens and closes it

## Blocked by

- docs/issues/007-probe-client-for-the-own-window.md
