# Whisper button and whispered tracking

## State

Built and tested outside the game (2026-11-17); in-game check in issue 014.

## What to build

Whisper button per row opens a whisper to the leader. Any whisper to a leader tags the row 'Whispered 3m' and dims it for an hour, per character.

See docs/prd/openspot.md (v0.2) and docs/adr/0005.

## Acceptance criteria

- [ ] Whisper memory with 1-hour expiry (unit tests)
- [ ] Button opens whisper; whispered rows tagged and dimmed (smoke test)

## Blocked by

- docs/issues/010-row-columns-and-sorting.md
