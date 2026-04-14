# Sprint 6 Plan — The Big One
*Created by Rivett (Head of Operations) — 2026-04-14*

## Sprint Goal
Ship a playable HTML5 build of the Scrapyard League. All existing systems integrated into a complete game loop. Balance-verified via automated playtesting.

## Track Assignments

| Track | Agent | Priority | Dependencies |
|---|---|---|---|
| A: Playable Web Build | Nutts (Dev-01) | 🔴 P0 | None |
| B: Compliance Fixes | Patch (DevOps) | 🟡 P1 | None |
| C: Process Gaps | Patch (DevOps) | 🟡 P1 | None (combined with B) |
| D: Playtest | Optic (Playtest Lead) | 🟠 P1 | Track A complete |
| E: Audit | Specc (Inspector) | 🟢 P2 | All tracks complete |

## Track A: Playable Web Build (Nutts → Boltz review)
- Integrate all systems: Shop → Loadout → Match → Result → earn Bolts → repair → repeat
- Scrapyard league: 3 opponents, playable start to finish
- Godot HTML5 export verified in browser
- Integration tests for the full loop

## Track B+C: Compliance & Process (Patch → Boltz review)
- Auto-generate STATUS.md via GitHub Action
- PLAN.md template for sprint planning
- Test count CI gate (PRs with .gd must include tests)
- Fix dashboard auto-gen if broken
- Cross-repo logging solution
- Review note enforcement CI check
- 3+ KB entries for structural decisions

## Track D: Playtest (Optic) — after Track A merges
- 1000+ headless combat simulations
- Chassis balance (45-55% win rates)
- Weapon distribution (no weapon >60% wins)
- Economy flow (1 new item every 2-3 matches)
- TTK analysis per league tier
- First playtest report

## Track E: Audit (Specc) — after all tracks
- Full sprint audit (spawned by The Bott)
