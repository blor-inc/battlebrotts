# S3-002: Match Lifecycle + Weapon Fire + Energy System

**Sprint:** 3
**Assignee:** Nutts (Dev-01)
**Status:** Done
**PR:** #13

## Deliverables

### 1. MatchManager Autoload (`game/autoloads/match_manager.gd`)
- Match lifecycle: IDLE → RUNNING → PAUSED → ENDED
- `setup_match(team_a, team_b, seed)` — configure combatants
- `start_match()` / `pause_match()` / `resume_match()`
- `step()` — run one tick (for frame-by-frame playback)
- `run_to_completion()` — instant sim to end
- `reset()` — clean slate for next match
- Win/loss/draw detection via TickSystem
- 120s timeout with HP-ratio tiebreaker
- Signals: `match_started`, `match_ended`, `tick_completed`
- Result dict: winner_team, outcome, ticks, duration_sec, team_stats, seed

### 2. Projectile System (`game/combat/projectile.gd`)
- Hitscan weapons (minigun, railgun, shotgun, arc_emitter): instant damage
- Missile weapons (missile_pod): travel at 6 px/tick with homing
- Max flight time: 60 ticks (3 seconds)
- Splash damage resolved on arrival
- Integrated into TickSystem phases 5-6

### 3. Tick System Updates (`game/combat/tick_system.gd`)
- Phase 5: Creates Projectile objects for non-hitscan weapons
- Phase 6: Updates projectile positions, resolves arrivals
- Projectile pool management (active list, cleanup on arrival/expiry)

### 4. Energy System (already integrated in Sprint 1, verified)
- 100 max energy, 5/sec regen (0.25/tick)
- Weapons deduct energy on fire; no energy = no shot
- Verified through MatchManager integration tests

### 5. Tests
- `test_match_manager.gd` — 16 tests covering lifecycle, win/loss/draw, timeout, energy, signals
- `test_projectile.gd` — 8 tests covering hitscan, missile travel, homing, arrival, max ticks
