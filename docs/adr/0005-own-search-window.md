---
status: accepted
---
# Our own search window replaces Blizzard's Browse tab

Supersedes ADR 0001. Filtering inside `LFGBrowseFrame` worked (we swap the result list it draws), but changing what a row *looks like* meant reaching into Blizzard's recycled row frames, and a per-row message button never appeared in the live client. Every planned visual (whispered marks, open-spot column, class icons for v2 class exclusion) would hit the same wall. OpenSpot therefore gets its own window: category tabs, an activity checklist, a Search button (`C_LFGList.Search` from our own click, proven by ForeverDungeonJournal), and rows we draw ourselves. The Looking For Group key/button opens our window; a "Blizzard window" button opens the original, which still handles listing your own group. Fit logic in `Core/` is unchanged.

## Consequences

- We own activity picking, search, sorting and row actions, and must keep them working across client patches.
- Redirecting the Looking For Group toggle hooks a Blizzard function; if that causes errors in game, fall back to opening ours by command/minimap button next to Blizzard's.
- Searching always needs a click; no auto-refresh.
