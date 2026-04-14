# S3-001: Comprehensive Test Suites for All Existing Code

**Sprint:** 3
**Assignee:** Glytch (QA)
**Status:** In Progress
**Priority:** CRITICAL — blocks all other Sprint 3 work

## Objective
Write comprehensive automated tests for ALL existing game code (~1600 lines across 12 files). Tests must be runnable headlessly via `godot --headless --script`.

## Test Architecture
Since we don't have a Godot test framework, create a simple test runner:
- `tests/test_runner.gd` — SceneTree script that runs all test suites, prints results, exits with code 0 (pass) or 1 (fail)
- `tests/test_*.gd` — Individual test suite files
- Each test function starts with `test_` and returns bool or uses assert
- Runner collects pass/fail counts and prints summary

**Run command:** `godot --headless --path godot/ --script res://tests/test_runner.gd`

Note: All game code lives in `game/` but the Godot project root is `godot/`. Tests should be at `tests/` (sibling to `game/`). The test runner script path for Godot is relative to the project root.

Actually, looking at the project structure: the Godot project is in `godot/` but game scripts are in `game/`. We need to check how scripts are referenced. The test files should probably live alongside the game code or be symlinked into the godot project.

**Simplest approach:** Put tests in `game/tests/` so they're alongside the source. The test runner goes in `godot/tests/test_runner.gd` (or we adjust). Actually let's keep it simple: put everything in `tests/` at repo root, and have the test runner script reference game classes directly (they use `class_name` so they're globally available in Godot).

Wait — for `godot --headless --script`, the script must be in the project directory or use `res://` paths. Since game files use `class_name`, they're autoloaded by Godot. So:
- Put test files in `godot/tests/`
- Run with `godot --headless --path godot/ --script res://tests/test_runner.gd`
- Game classes (DamageCalculator, Brott, etc.) are available via class_name

**But the game .gd files are in `game/` not `godot/`!** Need to check if Godot can see them. They might need to be in the Godot project directory or symlinked.

**Decision:** Create tests at `godot/tests/` and symlink or copy game files. OR — just put tests alongside game code. Check how the project is set up first.

Actually, just ask Glytch to figure out the project structure and make tests work. They're QA, that's their job.

## Required Test Suites

### 1. `test_damage_calculator.gd` — Damage Formula
- Normal damage: base × (1 - armor_reduction)
- Crit damage: base × (1 - armor_reduction) × 1.5
- No armor: full damage
- Plating: 20% reduction
- Reactive Mesh: 10% reduction + 5 flat reflect
- Ablative Shell: 40% reduction above 30% HP, 10% below 30% HP
- Minimum damage: always ≥ 1
- Splash: 50% of base damage, then armor applies
- Pellets: each pellet independent (shotgun = 5 pellets × 6 damage)
- Full weapon shot for each weapon type

### 2. `test_brott.gd` — Brott Entity
- Factory creation with valid loadout
- Weight validation (over-weight should assert)
- HP ratio calculation
- Damage application (reduces HP, sets alive=false at 0)
- Shield absorption (damage absorbed by shield first)
- Energy spend/regen
- Distance calculation

### 3. `test_data_validation.gd` — GDD v2 Stat Verification
Verify ALL stats match the GDD v2 exactly:
- **Chassis:** Scout (80 HP, 200 speed, 30 kg, 1W/3M), Brawler (150, 120, 55, 2W/2M), Fortress (250, 70, 80, 3W/1M)
- **Weapons:** All 7 weapons — damage, range, fire_rate, spread, energy_cost, weight, pellets, splash_radius, chain_targets
- **Armor:** Plating (20%, 15kg), Reactive Mesh (10%, 8kg, 5 reflect), Ablative Shell (40%/10%, 25kg)
- **Modules:** All 6 modules — weight, passive/activated, all effect values

### 4. `test_arena.gd` — Arena System
- Arena initialization (correct size, all floor)
- Tile setting and getting
- Out of bounds returns WALL
- Movement blocking (wall, pillar block; floor, cover, hazard don't)
- LoS blocking (wall, pillar block; floor doesn't)
- Cover provides cover only when HP > 0
- Cover destruction (damage, HP depletion, becomes floor)
- Bresenham line tracing
- LoS through clear path (not blocked)
- LoS through wall (blocked)
- LoS with cover in path (not blocked, cover_count incremented)
- World↔tile coordinate conversion
- Walkable neighbors (4-dir and 8-dir)
- Diagonal corner-cutting prevention
- Layout loading (the_pit, junkyard)

### 5. `test_pathfinder.gd` — A* Pathfinding
- Same start/goal returns [start]
- Straight line path (no obstacles)
- Path around obstacle
- No path to blocked goal returns []
- Hazard avoidance (prefers non-hazard route)
- Path caching (returns cached within RECALC_INTERVAL)
- Cache invalidation on force_recalc
- Diagonal movement
- Heuristic is admissible (octile distance)

### 6. `test_brottbrain.gd` — BrottBrain + Behavior Cards
- Card trigger evaluation (each TriggerType with edge cases)
- Card priority order (first matching card wins)
- No card matches → stance default
- Max 8 cards limit
- Card add/remove/move operations
- Default brain creation and behavior
- Action output structure

### 7. `test_steering.gd` — Stance Behaviors
- Aggressive: moves toward enemy, stops at weapon range
- Defensive: moves to cover, retreats if too close
- Kiting: maintains 60-80% range band, strafes clockwise
- Ambush: moves to cover, holds position

### 8. `test_tick_system.gd` — Combat Simulation
- Tick advances tick counter
- Energy regen per tick (0.25)
- Module passive effects (repair nanites healing)
- Weapon fires when in range, has energy, cooldown ready
- Weapon doesn't fire when out of range / no energy / on cooldown
- Damage queue processes at end of tick
- Reactive mesh reflect damage works
- Match ends when one team eliminated
- Match ends at 120s timeout (team with higher avg HP% wins)
- Draw detection (both teams eliminated, or tied HP at timeout)
- Determinism: same seed produces same result

## GDD v2 Reference Stats (for data validation tests)
See `docs/gdd.md` — this IS the GDD v2.

## Deliverables
- All test files in `godot/tests/` (or wherever makes sense for the project structure)
- Test runner that prints clear PASS/FAIL output
- Tests must be runnable headlessly
- Open PR on branch `qa/S3-001-test-suites`

## Work Log
