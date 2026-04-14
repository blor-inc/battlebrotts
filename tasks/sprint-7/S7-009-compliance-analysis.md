# S7-009 — Compliance-Reliant Process Analysis
*Rivett (Head of Operations) — 2026-04-14*

## Specc's Audit Flags
From inspector audits, three processes depend on agent compliance rather than structural enforcement:

### 1. KB Maintenance
**Current state:** 5 KB entries exist in `game-dev-studio/kb/`. All created in Sprint 6 by Patch.
**Problem:** No structural mechanism ensures KB gets updated when architectural decisions are made.
**Risk level:** 🟡 Medium — KB is valuable but not blocking. Missing entries = lost institutional memory.

**Structural solution:** Add a "Decision Record" checkbox to the PR template (Task 6 covers this). If a PR changes architecture or adds a new system, the checklist requires a KB entry link. This shifts KB maintenance from "remember to do it" to "CI reminds you."

**Accepted risk:** KB entries for non-PR decisions (design discussions, verbal agreements) will always be compliance-reliant. Acceptable — most decisions flow through PRs anyway.

### 2. Message Log Completeness
**Current state:** `battlebrotts/messages/log.md` has 38 lines covering sprints 3-6. Entries are written manually by Rivett.
**Problem:** If Rivett forgets or a session ends abruptly, messages are lost.
**Risk level:** 🟢 Low — The message log is supplementary. Git history, PR descriptions, and agent logs in `game-dev-studio/agents/*/log.md` provide redundant records.

**Structural solution:** The existing `check-agent-logs.yml` CI workflow already enforces that PRs include agent log updates. For cross-agent message logging, the FRAMEWORK.md protocol routes all comms through Rivett — this is inherently compliance-reliant by design (a coordinator logs what they coordinate).

**Accepted risk:** Message log will remain compliance-reliant. The redundancy from git history + PR descriptions + agent logs makes this acceptable. Recommend: add a "Session Wrap" checklist item to HEARTBEAT.md so Rivett's heartbeat reminds to update the log.

### 3. PLAN.md Maintenance
**Current state:** PLAN.md exists with Sprint 6 plan. Created manually by Rivett at sprint start.
**Problem:** If PLAN.md isn't updated at sprint boundaries, the CD has stale planning data.
**Risk level:** 🟡 Medium — PLAN.md is the CD's planning artifact.

**Structural solution:** The `status-gen.yml` workflow already auto-generates STATUS.md from git/PR data. Extend the same pattern: at sprint start, Rivett creates PLAN.md (this is a creative/planning act — can't be fully automated). But the dashboard should pull from both STATUS.md AND PLAN.md, making staleness visible. The existing dashboard fix (Task 1) should incorporate this.

**Accepted risk:** PLAN.md creation is inherently a judgment call. Can't automate "decide what to build next." But we can make staleness visible through the dashboard.

## Summary Table

| Process | Structural Fix | Residual Risk | Accept? |
|---|---|---|---|
| KB maintenance | PR checklist requires KB link for arch changes | Non-PR decisions untracked | ✅ Yes |
| Message log | Redundant with git+PRs+agent logs; heartbeat reminder | Session crash = lost entries | ✅ Yes |
| PLAN.md | Dashboard shows staleness; sprint-start protocol | Requires Rivett to initiate | ✅ Yes |

## Actions
- [x] Analysis complete (this document)
- [ ] PR template KB checkbox → covered by Task 6
- [ ] Dashboard staleness indicator → covered by Task 1
- [ ] Add session-wrap reminder to operational protocol
