# Sprint 9 Plan — Dashboard Polish
*Created by Rivett (Head of Operations) — 2026-04-14*

## Sprint Goal
Fix remaining dashboard issues from Eric's feedback. Small polish sprint.

**Priority: Accuracy → Usability → Speed**

## Track Assignments

| Track | Agent | Priority | Description |
|---|---|---|---|
| A: Sprint Config Update | Rivett (Ops) | 🔴 P0 | Mark S8 complete, set S9 as current in sprint-config.json |
| B: Attribution Fix | Patch (DevOps) | 🔴 P0 | Activity shows "Eric" for agent commits (PAT maps to brotatotes). Parse Co-authored-by or PR author. |
| C: Scrollable Sections | Patch (DevOps) | 🟡 P1 | Add scrollable CSS to Open PRs and Build Status sections |
| D: Dashboard Verify | Rivett (Ops) | 🟡 P1 | Verify live dashboard after fixes merge |
| E: Sprint-End Config | Rivett (Ops) | 🟢 P2 | Update sprint-config.json at sprint end |

## Track A: Sprint Config Update (Rivett) ✅
- Update sprint-config.json: S8 → complete (5/5), S9 → active
- DONE

## Track B: Attribution Fix (Patch)
- Root cause: shared PAT maps all commits to brotatotes (Eric's GitHub)
- Dashboard workflow uses `git log --format='%an'` which shows "brotatotes" for PAT-authenticated pushes
- Fix: In update-dashboard.yml Python script, check for `Co-authored-by:` trailers in commit body, or cross-reference with PR author via GitHub API
- Agent commits should show actual agent name (Patch, Nutts, etc.), not Eric

## Track C: Scrollable PR/Build Sections (Patch)
- Add `scrollable` class to PR and Build Status `<div>` containers in index.html
- CSS `.scrollable` already exists (max-height:500px, overflow-y:auto)
- Simple HTML change

## Track D: Dashboard Verify (Rivett)
- After B+C merge, check live dashboard at https://blor-inc.github.io/battlebrotts/
- Checklist: sprint number, task completion, agent names, scrollable sections, mobile

## Track E: Sprint-End Config (Rivett)
- Mark all S9 tasks as done in sprint-config.json
- Don't repeat Sprint 8's mistake of leaving it stale
