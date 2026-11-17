# Solo ticks mean OR; in a party they mean AND with counts

The user chooses the open spots they want with Tank/Healer/DPS toggles (not derived from the Blizzard role checkboxes). Solo, a listing fits if it has an open spot for **any** ticked role. In a party, the group needs room for everyone, so each role has a count and a listing fits only if it has **every** required count open and enough free slots for the whole party. Counts are pre-filled from the party's assigned roles (`UnitGroupRolesAssigned`) whenever the party changes and can be adjusted by hand; members without a role pre-fill nothing. Leaving the party restores the solo ticks. Solo ticks are saved per character.

## Revised 2026-11-17: only for an unlisted party

The party counts described here now apply only while the party has no listing of its own. A listed party recruits instead (ADR 0006): the buttons hold what the party needs, not what it is.
