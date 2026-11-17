# Verify client assumptions in game (HITL)

## State

Open

## What to build

The user runs the addon in Forever with the Browse tab open and runs /openspot debug; we read the SavedVariables report and fix what differs from the stand-in: how rows are hidden, member-count fields (incl. *_REMAINING), single-player recognition, activity kind and size.

See docs/prd/openspot.md and docs/adr/.

## Acceptance criteria

- [ ] Rows really disappear in the live Browse tab and the counter matches
- [ ] Report confirms member-count and activity fields
- [ ] Apply/search not tainted (no 'blocked action' errors)
- [ ] api-notes.md updated with verified facts

## Blocked by

- docs/issues/001-solo-role-filter-on-the-browse-tab.md
- docs/issues/002-raids-other-activities-and-single-player-listings.md
- docs/issues/004-party-mode-with-pre-filled-role-counts.md
- docs/issues/005-settings-panel-and-slash-command.md
