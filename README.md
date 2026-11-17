# OpenSpot

Made mainly for me and my friends. It's shared in case it's useful to others too, but expect it to follow our needs first.

A group finder for WoW Forever that shows only the groups with an open spot for you.

- **Its own window**, opened by the Looking For Group key (`I`) or `/openspot`. A "Blizzard window" button opens the game's own window, e.g. to list your own group.
- **Category tabs and an activity checklist.** Tick one or more dungeons (limited to your level by default) and press **Search**. Ticks are remembered per character.
- **Tank / Healer / DPS buttons**: tick the open spots you're looking for; listings without one are hidden. Several ticks: any of them. Nothing ticked: no filtering. A "Showing X of Y" line shows what's hidden.
- **In a party** the buttons become counts, pre-filled from your party's assigned roles (left-click +1, right-click -1). Groups need every counted spot open and room for the whole party.
- **Rows** show activity, leader, members' classes, open spots (T/H/D), and age. Hover a row for every member's name, level, class and role. Click a column header to sort; the default puts the fullest groups first.
- **Whisper** and **Join** buttons per row. Leaders you whispered (any way) in the last hour are tagged "Whispered 3m" and their row is dimmed.
- 5-player dungeons are judged against a 1 tank / 1 healer / 3 DPS template (change it in Settings). Members without a role count as DPS. Larger activities fit while they aren't full. Delisted groups are hidden while filtering.
- `/openspot settings`, `/openspot debug` (diagnostic report), `/openspot probe` (client facts).

Design decisions: `docs/adr/`. Requirements: `docs/prd/openspot.md`.

## Development

    luajit tests/run.lua         # unit tests (Core)
    luajit tests/smoke_test.lua  # loads every .toc file against a game stand-in
