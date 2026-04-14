# 🤖⚔️ BattleBrotts Studio — Status
*Updated by Rivett (PM) — 2026-04-14T13:18Z*

## Current Sprint
**Sprint 3 — Tests & Combat Features** 🔄 IN PROGRESS

## Sprint 3 Tasks
| ID | Title | Assignee | Status |
|---|---|---|---|
| S3-001 | Comprehensive Test Suites | Glytch (QA) | 🔄 In Progress |
| S3-002 | Match Lifecycle + Weapon Fire + Energy | Nutts (Dev-01) | ⏳ Waiting (after tests) |
| S3-003 | PR Reviews (test requirement enforced) | Boltz (Lead Dev) | ⏳ Waiting |

## Sprint 3 Plan
### Priority 1: Tests (Glytch)
- Combat tick system tests
- Damage formula tests (normal, crit, splash, pellets, reactive mesh, min damage)
- Pathfinding tests (basic pathing, obstacles, hazard costs)
- BrottBrain evaluation tests (card priority, triggers, actions, defaults)
- Steering tests (each stance behavior)
- Arena tests (LoS raycasting, cover, destructible cover)
- Data validation (all stats match GDD v2)

### Priority 2: Features (Nutts — after tests land)
- MatchManager autoload (start/end match, win/loss/draw at 120s)
- Weapon fire + projectile system (tick phases 5-6)
- Energy system integration (100 max, 5/sec regen, costs)

### New Rule
**No code merges without tests.** Every PR with game code must include or reference tests.

## Completed (Sprint 2)
- ✅ S2-001: Arena Tile System + LoS (Nutts) — PR #10
- ✅ S2-002: A* Pathfinding (Nutts) — PR #10
- ✅ S2-003: BrottBrain Evaluation Engine (Nutts) — PR #10
- ✅ S2-004: Stance Movement Behaviors (Nutts) — PR #10

## Completed (Sprint 1)
- ✅ S1-001: Architecture Document (Boltz) — PR #8
- ✅ S1-002: CI/CD + Godot Web Export (Patch) — PR #6, #9
- ✅ S1-003: Core Combat Simulation (Nutts) — PR #7
- ✅ S1-004: Dashboard Automation (Patch) — PR #9

## Codebase Summary
### game/combat/ (Sprint 1)
- `tick_system.gd` — 20 tick/sec simulation loop with 7 phases
- `damage_calculator.gd` — damage formula with armor, crits, min damage

### game/data/ (Sprint 1)
- `chassis_data.gd`, `weapon_data.gd`, `armor_data.gd`, `module_data.gd`

### game/entities/ (Sprint 1)
- `brott.gd` — Brott entity with stats, weapons, armor, modules

### game/arena/ (Sprint 2)
- `arena_manager.gd` — tile grid, LoS raycasting, 5 tile types, 2 layouts
- `pathfinder.gd` — A* with 8-dir movement, caching, hazard avoidance

### game/ai/ (Sprint 2)
- `behavior_card.gd` — trigger/action card system (7 triggers, 5 actions)
- `brottbrain.gd` — priority card evaluation engine (max 8 cards)
- `steering.gd` — 4 stance behaviors (Aggressive, Defensive, Kiting, Ambush)

## Agent Status
| Agent | Status | Current |
|---|---|---|
| 🎬 Eric | ✅ Active | Creative Director oversight |
| 🤖 The Bott | ✅ Active | Head of Product |
| 📋 Rivett | 🔄 Active | Managing Sprint 3 |
| 🎯 Gizmo | ⚪ Idle | Awaiting next design task |
| 👨‍💻 Boltz | ⏳ Standby | Awaiting PRs to review |
| 💻 Nutts | ⏳ Standby | Awaiting test completion |
| 🎮 Optic | ⚪ Idle | Awaiting builds |
| 🧪 Glytch | 🔄 Active | Writing test suites |
| 🕵️ Specc | ⚪ Idle | Awaiting audit request |
| 🔧 Patch | ⚪ Idle | Dashboard update pending |
