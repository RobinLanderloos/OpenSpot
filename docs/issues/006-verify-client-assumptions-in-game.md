# Verify client assumptions in game (HITL)

## State

Completed 2026-11-17: hook works via the `results` path (55 to 2 with DPS ticked, rows hidden, bar placed fine). One-member listings are indistinguishable from groups, so ADR 0002 was revised to judge them like groups. Taint not yet observed over a longer session.

## What to build

The user runs the addon in Forever with the Browse tab open and runs /openspot debug; we read the SavedVariables report and fix what differs from the stand-in: how rows are hidden, member-count fields (incl. *_REMAINING), single-player recognition, activity kind and size.

See docs/prd/openspot.md and docs/adr/.

## Acceptance criteria

- [x] Rows really disappear in the live Browse tab and the counter matches
- [x] Report confirms member-count and activity fields
- [ ] Apply/search not tainted (no 'blocked action' errors)
- [x] api-notes.md updated with verified facts

## Blocked by

- docs/issues/001-solo-role-filter-on-the-browse-tab.md
- docs/issues/002-raids-other-activities-and-single-player-listings.md
- docs/issues/004-party-mode-with-pre-filled-role-counts.md
- docs/issues/005-settings-panel-and-slash-command.md
