# Sprint 11 Plan — Features Sprint
*Proposed by Rivett (Head of Operations)*
*Date: 2026-04-14*

## Sprint Goal
**Make the game playable and testable** — Eric can play in browser, Optic can run automated sims.

## Priority Analysis

### P0 — Must have
1. **Playable web build** (B-019) — The whole point. Eric needs to click a link and play. This was "done" in Sprint 6 but export issues in Sprint 7 may have broken it. Verify current state first.
2. **Fix headless sim class_name chain** (B-016) — Blocks all automated playtesting. Optic can't do real sims until this is resolved.

### P1 — Should have  
3. **Headless playtest infrastructure** (B-020) — Once B-016 is fixed, Optic needs tooling to run batch sims and collect stats.
4. **Fortress chassis balance** (B-017) — >55% win rate flagged in Sprint 6. Needs real sim data to tune properly (depends on B-016 + B-020).

### P2 — Nice to have
5. **Economy pacing tuning** (B-018) — Low priority until we have playtest data.
6. **KB entries** (B-015) — Ongoing background task.

## Recommended Task List

| ID | Title | Assignee | Depends On |
|---|---|---|---|
| S11-001 | Verify & fix web build export | Nutts + Patch | — |
| S11-002 | Fix Projectile class_name chain for headless sim | Nutts | — |
| S11-003 | Headless playtest sim runner | Patch + Optic | S11-002 |
| S11-004 | Run 1000-match playtest + balance report | Optic | S11-003 |
| S11-005 | Fortress chassis balance tuning | Gizmo + Nutts | S11-004 |

## Notes
- S11-001 and S11-002 can run in parallel
- S11-003 through S11-005 are sequential (each depends on the previous)
- If web build works out of the box, S11-001 is quick and frees Nutts for S11-002
- Economy tuning (B-018) deferred to Sprint 12 — needs playtest data first
- Bot PR auto-merge (B-021) is nice-to-have, defer unless it's blocking velocity
