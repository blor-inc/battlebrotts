# Sprint 8 Plan — Operations Health
*Created by Rivett (Head of Operations) — 2026-04-14*

## Sprint Goal
Fix the dashboard architecture once and for all. Clean up CI conflicts. Healthy process = healthy product.

**Priority: Process quality → Product quality → Speed**

## Track Assignments

| Track | Agent | Priority | Description |
|---|---|---|---|
| A: Dashboard Redesign | Patch (DevOps) | 🔴 P0 | Decouple dashboard from STATUS.md. Query git/PR API directly. |
| B: Squash Merge Attribution | Patch (DevOps) | 🟡 P1 | GitHub API: attribute squash merges to PR author, not bot. |
| C: STATUS.md Auto-Gen Fix | Patch (DevOps) | 🟡 P1 | PR-based flow (branch protection blocks direct push). Reconcile with dashboard workflow. |
| D: KB Entries | Specc (Inspector) | 🟢 P2 | Write KB entries for structural decisions. Handled by The Bott. |
| E: Backlog Cleanup | Rivett (Ops) | 🟢 P2 | Clean stale items, update backlog. |

## Track A: Dashboard Architecture Redesign (Patch)
**This is the THIRD attempt. It must work.**
- Root cause: status-gen.yml and update-dashboard.yml fight over STATUS.md format
- Fix: Dashboard workflow queries git log + GitHub PR API directly. No STATUS.md dependency.
- Add studio-lead-dev[bot] to author map
- Must pass Eric's checklist:
  - Current sprint number
  - Non-empty sprint history
  - Open PRs visible
  - Real activity with named actors (no "unknown")
  - Scrollable full history
  - Responsive on mobile

## Track B: Squash Merge Attribution (Patch)
- GitHub API call to set `squash_merge_commit_title` and `squash_merge_commit_message` so PR author gets credit

## Track C: STATUS.md Auto-Gen Fix (Patch)
- status-gen.yml can't push to main (branch protection)
- Options: PR-based flow OR merge into dashboard workflow
- Recommend: merge into dashboard workflow to eliminate the conflict entirely

## Track D: KB Entries (Specc — via The Bott)
- Structural decision entries needed in game-dev-studio KB

## Track E: Backlog Cleanup (Rivett)
- Remove completed items from tasks/backlog.md
- Add Sprint 7/8 findings
