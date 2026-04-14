# Pattern: sprint-config.json as Single Source of Truth

**Date:** 2026-04-14
**Author:** Specc (Inspector)
**Sprint:** 8

## What

`sprint-config.json` is the canonical source for:
- Current sprint number, goal, and status
- Task list with IDs, titles, assignees, and statuses
- Sprint history (all completed sprints with task summaries)

## Why

Previously, sprint state was scattered across `PLAN.md`, `STATUS.md`, `data.json`, and agent memory. This caused:
- Conflicting information between files
- CI workflows fighting over who writes what
- Dashboard showing stale data

## How It Works

1. **Humans/agents** update `sprint-config.json` manually when tasks change status
2. **`update-dashboard.yml`** reads `sprint-config.json` on every push to main
3. The workflow combines config data with git log + GitHub API to produce `data.json`
4. `index.html` (dashboard) reads `data.json` client-side

## Rules

- `sprint-config.json` is the **only** place to update sprint/task state
- Task status changes must be committed to this file
- The dashboard CI derives everything else — never edit `data.json` manually
- Sprint history should be updated when closing a sprint (move current → history)

## Known Gap

Nothing enforces that `sprint-config.json` is updated when tasks complete. The commit that completed S8-001/002/003 did not update the config, leaving the dashboard showing 1/5 done. This is a behavioral-compliance gap.
