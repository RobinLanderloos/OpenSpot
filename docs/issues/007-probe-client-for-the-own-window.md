# Probe the client for the own window (HITL)

## State

Completed 2026-11-17 (facts in the wow-forever-addon skill's api-notes.md).

## What to build

Extend /openspot debug with the facts the window needs: C_LFGList.GetAvailableCategories / GetLfgCategoryInfo, GetAvailableActivities per category with GetActivityInfoTable fields (level range?), per-member info for a result (GetSearchResultPlayerInfo / GetSearchResultMemberInfo), whether ApplyToGroup / a request-to-join call exists, the Looking For Group toggle function names (LFGVanilla_ToggleFrame, ToggleGroupFinderFrame, ToggleLFGParentFrame, PVEFrame...), and search cooldown info. The user runs it, we read SavedVariables.

See docs/prd/openspot.md (v0.2) and docs/adr/0005.

## Acceptance criteria

- [x] Report lists categories and activities with their fields
- [x] Report shows member info fields for one result
- [x] Report shows which join and toggle functions exist
- [x] api-notes.md updated

## Blocked by

None - can start immediately
