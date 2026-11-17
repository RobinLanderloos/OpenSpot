# Role badges on member icons

## State

Built and tested outside the game (2026-11-17); in-game check in issue 020.

## What to build

Every member in a result row is a 30px class icon with a 16px role badge (shield = tank, cross = healer, sword = DPS) on its corner, in 48px rows; members without a role get no badge and a greyed icon. (History, 2026-11-17: 16px icons with 10px portrait badges were unreadable; role icons in class-coloured borders were tried and dropped by the user.) Shown in every mode. Story 43.

See docs/prd/openspot.md (v0.4) and docs/adr/0006.

## Acceptance criteria

- [x] Each member shows a class icon with a role badge (smoke test)
- [x] No-role members: no badge, greyed icon (smoke test)
- [ ] Role icons readable in game (issue 020)

## Blocked by

None - can start immediately
