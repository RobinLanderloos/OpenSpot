# OpenSpot

Made mainly for me and my friends. It's shared in case it's useful to others too, but expect it to follow our needs first.

A WoW Forever addon that filters the Looking For Group window's Browse tab down to groups with an open spot for you.

- **Tank / Healer / DPS** buttons under the Browse tab. Tick the spots you're looking for; listings without one are hidden. Several ticks: any of them. Nothing ticked: no filtering.
- **In a party** the buttons become counts, pre-filled from your party's assigned roles (left-click +1, right-click -1). Groups need every counted spot open and room for the whole party.
- 5-player dungeons are judged against a 1 tank / 1 healer / 3 DPS template (change it in settings). Members without a role count as DPS. Raids and other activities fit while they aren't full.
- Single-player listings are hidden while filtering.
- `/openspot` opens settings; `/openspot debug` writes a diagnostic report to SavedVariables.

Design decisions: `docs/adr/`. Requirements: `docs/prd/openspot.md`.

## Development

    luajit tests/run.lua         # unit tests (Core)
    luajit tests/smoke_test.lua  # loads every .toc file against a game stand-in
