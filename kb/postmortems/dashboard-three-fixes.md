# Postmortem: Dashboard Architecture — Three Attempts

**Date:** 2026-04-14
**Author:** Specc (Inspector)
**Sprint:** 8
**Severity:** Process failure, resolved on third attempt

## Timeline

### Attempt 1: Sprint 4 (S4-002)
- **What:** Dashboard Overhaul — responsive redesign, PR #14
- **Problem:** Dashboard data was manually maintained in `data.json`. Went stale immediately.
- **Root cause:** No automation. Dashboard was a static snapshot updated by hand.

### Attempt 2: Sprint 5 (S5-001)
- **What:** Dashboard Auto-Generation CI, PR #17
- **Approach:** `status-gen.yml` workflow auto-generated `STATUS.md` from git/PR data. Dashboard read from `STATUS.md`.
- **Problem:** Two conflicting workflows both wrote to `main` on push events, creating infinite loops and merge conflicts. Author map was incomplete — many commits showed as "unknown." Test count was hardcoded.
- **Root cause:** Dual-source-of-truth conflict. `status-gen.yml` and `update-dashboard.yml` both triggered on push and both committed to main. STATUS.md was both input and output.

### Attempt 3: Sprint 8 (S8-001, S8-002, S8-003)
- **What:** Full architecture redesign — commit `4b88fbf`
- **Approach:**
  1. Created `sprint-config.json` as the **single source of truth** for sprint/task state
  2. **Deleted** `status-gen.yml` entirely — eliminated the conflict
  3. `update-dashboard.yml` reads from `sprint-config.json` + git log + GitHub API
  4. Fixed author map: added Eric, The Bott, `studio-lead-dev[bot]`
  5. Populated full sprint history (sprints 1–7)
  6. Real test count (375, was hardcoded 166+)
  7. Squash merge attribution — GitHub repo setting changed so PR author is preserved
- **Result:** Fundamentally works. Eric confirmed "much better." Remaining issues documented below.

## Remaining Issues (Post-Sprint 8)

1. **Sprint progress shows 1/5 done** — `sprint-config.json` was not updated after tasks S8-001/002/003 were completed in commit `4b88fbf`. The config still shows them as `in-progress` / `todo`.
2. **Activity timeline shows "Eric" for agent commits** — squash merge via GitHub uses Eric's account, so `git log` shows `Eric <erichao2018@gmail.com>` as author. The `author_map` correctly maps "eric" → "eric" agent, but cannot distinguish Eric's own commits from agent work merged via his account. The `Co-authored-by: Patch` trailer is present but the dashboard script doesn't parse co-author trailers.
3. **PR and Build sections not scrollable** — Activity timeline has `.scrollable` class (max-height 500px with overflow-y auto), but PR and Build `<div>` containers have no scroll constraint. With many open PRs, the page extends indefinitely.

## Lessons Learned

1. **Single source of truth from day one.** The Sprint 4 → 5 → 8 progression was avoidable. If `sprint-config.json` had existed from Sprint 4, the dual-write conflict never would have occurred.
2. **Workflow-on-push writing to the same branch is dangerous.** Two workflows both triggering on `push` to `main` and both committing back to `main` is a guaranteed loop/conflict. Any CI that writes to its own trigger branch needs explicit loop-breaking (e.g., `[skip ci]` in commit messages, or conditional triggers).
3. **Author maps need a co-author fallback.** Squash merges through GitHub always attribute to the merger. The dashboard should parse `Co-authored-by` trailers to attribute correctly.
4. **Sprint config must be updated when tasks complete.** This is currently a behavioral-compliance process — nothing enforces it.

## Related
- `sprint-config.json` — the single source of truth
- `.github/workflows/update-dashboard.yml` — the surviving dashboard CI
- xref: game-dev-studio/kb/decisions/status-auto-generation.md
