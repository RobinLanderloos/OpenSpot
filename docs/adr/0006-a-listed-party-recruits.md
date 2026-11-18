---
status: accepted
---
# A listed party recruits players instead of looking for a group

In a party, OpenSpot used to look only for groups with room for the whole party (ADR 0003). When forming a group, the user wants the opposite: players who fill the roles the party still misses. OpenSpot picks the direction from the party's own listing: **in a party and listed** (`C_LFGList.HasActiveEntryInfo`) means recruiting; in a party and not listed means joining, as before. People list a group when they are forming one, so this needs no extra control on a UI the user already found obtuse.

While recruiting:

- **Needs** = template of the listed activity minus the party's assigned roles, with roleless party members counted as DPS (the same rule ADR 0002 uses for listings). For raids and other activities, any free slot is open for every role. Needs are re-filled when roles change and can be adjusted by hand (left +1, right -1) until they change again.
- **A listing fits** when every member fills a spot the party misses: per role no more than needed, and no more members than free slots. Pairs and trios count, not only solo players. Listing members without a role count as DPS. The party's own listing is hidden.
- With no needs (party full or every count 0) nothing is filtered.

## Considered options

- Recruiting replaces joining in every party: loses "find a group for my duo".
- A visible Join / Recruit switch: explicit, but one more control.

## Consequences

- Invite works only on solo listings: a pair's leader is already in a party, so inviting fails. Pairs and trios get Whisper only. If `InviteUnit` turns out to be blocked on Forever, recruiting ships with Whisper only.
- Revised 2026-11-18: Invite is not tied to recruiting. It shows on every solo listing whenever the player may invite (solo, or party leader/assistant), in its own column. A solo player who lists themselves is usually looking for a group, so listing solo does not switch to recruiting; the user still wanted to invite other solo players from there.
- A party that lists itself but wants to join another group must delist first.
