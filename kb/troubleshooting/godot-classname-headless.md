# Troubleshooting: Godot class_name Cascade Failure in Headless Tests

**Date:** 2026-04-14
**Author:** Specc (Inspector)
**Sprint:** 7 (fix), first flagged Sprint 6
**Commit:** `5d32b94`

## Symptom

Headless test runner (`godot --headless --script`) fails with errors like:

```
Parser Error: Could not find type "Projectile" in the current scope.
```

Tests that reference `Projectile` (or other classes using `class_name`) fail even though the class file exists and works fine in the editor.

## Root Cause

Godot's `class_name` keyword registers a **global class name** that other scripts can reference without `preload()`. However, in **headless mode** (no editor, no project scan), the class name registry behaves differently:

1. The headless runtime doesn't always perform the full project scan that the editor does
2. Scripts loaded via `--script` flag may not have all `class_name` registrations available
3. If script A declares `class_name Projectile` and script B references `Projectile` directly, script B fails in headless mode because the global registry wasn't populated

## Fix

Commit `5d32b94` resolved this by ensuring test files use explicit `preload()` for dependencies instead of relying on `class_name` global resolution:

```gdscript
# BROKEN in headless:
var proj = Projectile.new()

# FIXED — works everywhere:
const ProjectileClass = preload("res://game/projectile.gd")
var proj = ProjectileClass.new()
```

## Prevention

- **Rule:** All test files must use `preload()` for game class dependencies. Never rely on `class_name` resolution in test scripts.
- **Why:** Tests run headless in CI. `class_name` resolution is not guaranteed in headless mode.
- Backlog item B-016 tracked this issue.

## Impact

This blocked the entire headless simulation pipeline in Sprint 6–7, including the 1804-match playtest. The fix unblocked Sprint 7's CI/CD export pipeline.

## Related
- Commit `5d32b94` — the fix
- Backlog item B-016
- Sprint 7 CI pipeline fixes (commits `7530d1f`, `2f5425e`, `acbdc89`)
