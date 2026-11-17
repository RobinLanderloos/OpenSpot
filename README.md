# OpenSpot

Made mainly for me and my friends. It's shared in case it's useful to others too, but expect it to follow our needs first.

A group finder for WoW Forever that shows only the groups with an open spot for you.

- **Its own window**, docked to the right of the game's Looking For Group window when you open that with its key (`I`) or button, and closed with it. `/openspot` opens it on its own (drag it anywhere; it remembers where). The "Blizzard window" button opens the game's window next to it.
- **Category tabs and an activity checklist.** Ticking or unticking a dungeon searches right away (limited to your level by default); **Search** refreshes. Ticks are remembered per character.
- **Tank / Healer / DPS buttons**: tick the open spots you're looking for; listings without one are hidden. Several ticks: any of them. Nothing ticked: no filtering. A "Showing X of Y" line shows what's hidden.
- **In a party** the buttons become counts, pre-filled from your party's assigned roles (left-click +1, right-click -1). Groups need every counted spot open and room for the whole party.
- **Recruiting**: when your party has listed itself (in Blizzard's window), the buttons switch to "Looking for:" and show what you still need (template minus your party's roles; members without a role count as DPS). Only players who fill those spots are shown, including DPS pairs and trios, and your own listing is hidden. Solo players get an **Invite** button and are tagged "Invited 2m"; groups get Whisper. Delist and it goes back to finding a group for your party.
- **Rows** show activity, leader, members' class icons with a role badge (shield, cross, sword; no badge and greyed without a role), open spots (T/H/D), and age. Hover a row for every member's name, level, class and role. Click a column header to sort; the default puts the fullest groups first.
- A **Whisper** button per row. Leaders you whispered (any way) in the last hour are tagged "Whispered 3m" and their row is dimmed.
- 5-player dungeons are judged against a 1 tank / 1 healer / 3 DPS template (change it in Settings). Members without a role count as DPS. Larger activities fit while they aren't full. Delisted groups are hidden while filtering.
- `/openspot settings`, `/openspot debug` (diagnostic report), `/openspot probe` (client facts).

Design decisions: `docs/adr/`. Requirements: `docs/prd/openspot.md`.

## Development

    luajit tests/run.lua         # unit tests (Core)
    luajit tests/smoke_test.lua  # loads every .toc file against a game stand-in
