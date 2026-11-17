# Open spots are a template minus role counts

A listing reports how many members have each role (tank/healer/damage) but not the composition the leader wants. OpenSpot therefore computes open spots as *template minus members with that role*: 5-man dungeons use 1 tank / 1 healer / 3 DPS (editable in settings); members without a role count as DPS; activities without a template (raids, other) count as having an open spot for every role while the listing is not full. One-member listings are judged like any group, and delisted listings are hidden while filtering. A "player finder" for building your own group is planned for v2.

## Consequences

The template is a guess. A leader running 2 healers or no healer will be judged against 1/1/3 unless the user edits the template.

## Revised 2026-11-17 (after the first in-game report)

The original decision hid single-player listings while filtering. The live client showed that a one-member listing is indistinguishable from a lone leader forming a group: same fields, and the server fills `TANK_REMAINING`/`HEALER_REMAINING`/`DAMAGER_REMAINING` for it on the same 1/1/3 template. 38 of 40 listings had one member, so hiding them left almost nothing. The user chose to judge them like groups.
