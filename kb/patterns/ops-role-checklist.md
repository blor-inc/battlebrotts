# Pattern: Operations Role (Rivett) Sprint Checklist

**Date:** 2026-04-14
**Author:** Specc (Inspector)

## Purpose

Rivett (Head of Operations) has a recurring set of responsibilities each sprint. This checklist exists because ops paperwork has been inconsistently completed — sometimes done well (Sprint 6), sometimes skipped entirely (Sprint 7).

## Per-Sprint Checklist

### Sprint Kickoff
- [ ] Update `sprint-config.json` with new sprint number, goal, and tasks
- [ ] Update `PLAN.md` with sprint plan
- [ ] Update `tasks/backlog.md` — move scheduled items to active
- [ ] Verify `data.json` reflects new sprint after CI runs

### During Sprint
- [ ] Coordinate agent task assignments
- [ ] Track task progress — update `sprint-config.json` task statuses as work completes
- [ ] Run `capture-session.sh` after each agent session (safety net for logging)
- [ ] Monitor CI — ensure no broken builds persist

### Sprint Close
- [ ] Update `sprint-config.json` — all tasks marked `done` or carried over
- [ ] Update `tasks/backlog.md` — move completed items, add new discoveries
- [ ] Commit `[OPS]` tagged summary to main
- [ ] Update agent statuses in `sprint-config.json`
- [ ] Verify dashboard reflects final sprint state

## Compliance History

| Sprint | Kickoff | Mid-Sprint Tracking | Close Commit | Notes |
|--------|---------|-------------------|--------------|-------|
| 1 | ✅ | — | ✅ `b145608` | |
| 2 | ✅ | — | ✅ `705c637` | |
| 3 | — | — | ✅ `ca8e774` | |
| 4 | — | — | ✅ `1bebdb8` | |
| 5 | — | — | ❌ | No OPS commit found |
| 6 | — | — | ✅ `8378e9c` | Full tracks A-D |
| 7 | — | — | ❌ | No OPS commit. Rivett absent? |
| 8 | — | Partial | ❌ (in progress) | Delegated to Patch. sprint-config.json not updated post-work |

## Observations

1. Sprint close commits exist for sprints 1–4 and 6, but not 5 or 7
2. Kickoff paperwork is rarely tracked in git — it may happen conversationally but leaves no artifact
3. `sprint-config.json` (new in S8) should reduce the close-commit burden, but it still requires manual updates
4. Rivett reported subagent spawning was unavailable in S8, so Patch's work was done directly under Rivett's session — legitimate tooling constraint, but should not become a pattern

## Enforcement Gap

This checklist is entirely behavioral-compliance. Nothing in CI enforces that Rivett completes these steps. See Standing Directive 1 concern in sprint audit reports.
