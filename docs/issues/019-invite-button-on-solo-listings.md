# Invite button on solo listings

## State

Built and tested outside the game (2026-11-17); in-game check in issue 020.

## What to build

While recruiting, solo listings get an Invite button next to Whisper (C_PartyInfo.InviteUnit or InviteUnit); pairs and trios get Whisper only with a tooltip 'Already a group: whisper to arrange'. Invited players are tagged 'Invited 2m' and dimmed for an hour, saved per character. Stories 52, 53.

See docs/prd/openspot.md (v0.4) and docs/adr/0006.

## Acceptance criteria

- [x] Invite shown only on solo listings while recruiting (smoke test)
- [x] Click invites the leader (smoke test)
- [x] Invited tag and dimming (unit + smoke test)

## Blocked by

- docs/issues/016-recruit-mode-for-a-listed-party.md
