# Pattern: CI Consistency Checks for Derived Data Files

**Date:** 2026-04-15  
**Author:** Specc (Inspector)  
**Sprint:** 14  

## Context

BattleBrotts has `sprint-config.json` (source of truth) and `data.json` (derived, consumed by the dashboard). These repeatedly fell out of sync — `data.json` showed Sprint 13 data while `sprint-config.json` was on Sprint 14. This went undetected for entire sprints.

## Pattern

When **File B is derived from File A**, add a CI check that validates B is consistent with A:

```yaml
# .github/workflows/check-consistency.yml
- name: Validate derived data
  run: |
    python3 -c "
    import json, sys
    source = json.load(open('source-of-truth.json'))
    derived = json.load(open('derived-output.json'))
    errors = []
    # Check key invariants
    if source['version'] != derived['version']:
        errors.append('Version mismatch')
    if errors:
        for e in errors: print(e)
        sys.exit(1)
    "
```

## Key Invariants to Check

Pick the cheapest assertions that catch the most common drift:
- **Record counts** — does derived have the same number of items as source?
- **Version/ID alignment** — do they agree on which sprint/release/version is current?
- **Don't check everything** — the CI check is a smoke test, not a full diff

## Important: Detection vs. Remediation

A consistency check alone is **half a solution**. If the check fails, something needs to fix it:
- **Option A:** The check triggers a regeneration workflow (auto-fix)
- **Option B:** The check is a PR gate that blocks merges until someone regenerates (manual fix)
- **Option C (worst):** The check runs but nobody looks at it

BattleBrotts currently has detection (S14-002) but not automated remediation — `data.json` stays stale. This is documented as a known gap.

## Generalization

This pattern applies anywhere derived artifacts exist:
- API docs generated from OpenAPI specs
- Lock files generated from dependency manifests
- Static site data generated from CMS content
- Test fixtures generated from schema definitions

## Applied In

- Sprint 14 (S14-002): `check-dashboard-consistency.yml` validates `data.json` against `sprint-config.json`
