# BattleBrotts — Technical Architecture

**Version:** 1.0
**Author:** Boltz (Lead Dev)
**Date:** 2026-04-14
**Engine:** Godot 4.4.1 (GDScript, HTML5 export)
**Reference:** [GDD v2](gdd.md)

---

## 1. Project Structure

```
battlebrotts/
├── godot/                        # Godot project root
│   ├── project.godot
│   ├── export_presets.cfg
│   ├── scenes/
│   │   ├── main.tscn             # Entry point — routes to menu or match
│   │   ├── ui/
│   │   │   ├── main_menu.tscn
│   │   │   ├── garage.tscn       # Build screen (chassis, weapons, armor, modules)
│   │   │   ├── brottbrain_editor.tscn  # Drag-and-drop behavior card editor
│   │   │   ├── match_hud.tscn    # HP/energy bars, combat log, speed controls
│   │   │   └── post_match.tscn   # Results, replay, economy
│   │   ├── arena/
│   │   │   ├── arena.tscn        # Base arena scene
│   │   │   ├── the_pit.tscn      # 16×16 open arena
│   │   │   ├── junkyard.tscn     # 20×20 cover-heavy
│   │   │   └── foundry.tscn      # 20×16 conveyor + lava hazards
│   │   └── entities/
│   │       ├── brott.tscn        # Brott entity (sprite, collision, UI)
│   │       └── projectile.tscn   # Bullet/missile/beam visual
│   ├── scripts/
│   │   ├── autoloads/
│   │   │   ├── game_state.gd     # Singleton: player data, economy, unlocks
│   │   │   └── match_manager.gd  # Singleton: match lifecycle, sim runner
│   │   ├── combat/
│   │   │   ├── tick_system.gd    # Core simulation loop (20 ticks/sec)
│   │   │   └── damage_calculator.gd
│   │   ├── ai/
│   │   │   ├── brottbrain.gd     # Behavior card evaluation engine
│   │   │   ├── behavior_card.gd  # Card data: trigger + action pair
│   │   │   └── stance.gd         # Stance movement/engagement logic
│   │   ├── entities/
│   │   │   ├── brott.gd          # Brott node script
│   │   │   └── projectile.gd     # Projectile movement + hit detection
│   │   ├── movement/
│   │   │   ├── pathfinder.gd     # A* on tile grid (recalc every 10 ticks)
│   │   │   └── steering.gd       # Stance-based movement behaviors
│   │   ├── arena/
│   │   │   ├── arena_manager.gd  # Tile map, LoS, cover, environment
│   │   │   └── environment.gd    # Conveyor belts, lava, destructibles
│   │   └── data/
│   │       ├── chassis_data.gd
│   │       ├── weapon_data.gd
│   │       ├── armor_data.gd
│   │       └── module_data.gd
│   ├── resources/                # .tres resource files
│   │   ├── chassis/
│   │   ├── weapons/
│   │   ├── armor/
│   │   └── modules/
│   └── assets/
│       ├── sprites/
│       ├── audio/
│       └── ui/
├── docs/
│   ├── gdd.md
│   └── architecture.md           # This file
├── data.json                     # Dashboard data
├── index.html                    # Dashboard
└── STATUS.md
```

---

## 2. Scene Tree

### Main Scene
```
Main (Node)
├── GameState (Autoload)
├── MatchManager (Autoload)
└── SceneRoot (Node)
    └── [current scene loaded dynamically]
```

### Match Scene (during combat)
```
Arena (Node2D)
├── TileMap (TileMapLayer)         # Arena layout: walls, cover, hazards
├── Brotts (Node2D)                # Container for all Brott instances
│   ├── Brott_P1 (CharacterBody2D)
│   │   ├── Sprite2D
│   │   ├── CollisionShape2D       # Circle, radius 12px
│   │   ├── HealthBar (Control)
│   │   └── StanceIcon (Sprite2D)
│   └── Brott_E1 (CharacterBody2D)
│       └── ...
├── Projectiles (Node2D)           # Active projectiles
├── VFX (Node2D)                   # Particles, explosions
├── Camera2D                       # Fixed, shows full arena
└── UI (CanvasLayer)
    └── MatchHUD
        ├── PlayerInfo
        ├── EnemyInfo
        ├── CombatLog
        └── SpeedControls
```

### Garage Scene (build/edit)
```
Garage (Control)
├── ChassisSelector
├── WeaponSlots
├── ArmorSlot
├── ModuleSlots
├── WeightBudget (Label)
├── BrottPreview (SubViewport)
└── BrottBrainButton               # Opens editor (hidden until Bronze unlock)
```

---

## 3. Core Systems

### 3.1 Tick System

The simulation runs at **20 ticks/sec** (50ms per tick). Each tick executes 7 phases in strict order:

```
┌─────────────────────────────────────────────────────┐
│ TICK LOOP (per tick, all Brotts processed per phase) │
├──────┬──────────────────────────────────────────────┤
│  1   │ BrottBrain Evaluation                         │
│      │ Check behavior cards top→bottom, fire first   │
│      │ match. If none match, follow current stance.   │
├──────┼──────────────────────────────────────────────┤
│  2   │ Energy Regen                                  │
│      │ +0.25 energy/tick (= 5/sec). Cap at 100.      │
├──────┼──────────────────────────────────────────────┤
│  3   │ Module Tick                                   │
│      │ Decrement cooldowns. Apply passives            │
│      │ (Repair Nanites: +0.15 HP/tick).               │
├──────┼──────────────────────────────────────────────┤
│  4   │ Movement                                      │
│      │ Execute stance/override movement at chassis    │
│      │ speed. A* recalc every 10 ticks.               │
├──────┼──────────────────────────────────────────────┤
│  5   │ Weapon Fire                                   │
│      │ Each weapon checks cooldown + range + LoS +    │
│      │ energy. Fire if ready. Consume energy.         │
├──────┼──────────────────────────────────────────────┤
│  6   │ Projectile Update                             │
│      │ Advance projectiles. Resolve hits.             │
│      │ (Phase 1: instant-hit. Phase 2: travel time.)  │
├──────┼──────────────────────────────────────────────┤
│  7   │ Damage Application                            │
│      │ Apply queued damage. Check deaths. Reflect     │
│      │ damage (Reactive Mesh). Check match end.       │
└──────┴──────────────────────────────────────────────┘
```

**Determinism:** All RNG uses a seeded `RandomNumberGenerator`. Same seed → same match.

### 3.2 Damage System

```
effective_damage = base_damage × (1 - armor_reduction) × crit_multiplier

crit_chance  = 5%
crit_mult    = 1.5× on crit, 1.0× otherwise
min_damage   = 1 (no hit deals 0)
```

**Special cases:**
- **Pellet weapons** (Shotgun: 6dmg × 5 pellets): each pellet rolls independently — individual hit check based on spread angle vs target hitbox
- **Splash** (Missile Pod): 100% at impact, 50% at radius tiles
- **Reactive Mesh**: reflects 5 flat damage to attacker, ignores attacker's armor
- **Ablative Shell**: 40% reduction → 10% when wearer < 30% HP
- **Lava**: 10 dmg/sec, ignores armor entirely

**Hit detection for spread weapons:**
Each pellet gets random angular offset within ±(spread/2). Ray from attacker to target + offset. Hit if ray intersects target circle (radius 12px).

### 3.3 Movement System

- **Pathfinding:** A* on tile grid (32×32 px tiles). Recalculated every 10 ticks.
- **Speed:** Chassis-dependent (Scout 200, Brawler 120, Fortress 70 px/sec)
- **Collision:** `CharacterBody2D` with `move_and_slide()`. Brotts cannot overlap.
- **Stance behaviors:**
  - Aggressive: move toward nearest enemy, close to weapon range
  - Defensive: retreat to cover, maintain max range
  - Kiting: maintain 60-80% max range, circle-strafe clockwise
  - Ambush: move to cover, hold, fire at 50% range
- **Overrides:** BrottBrain actions ("Get to Cover", "Hold the Center") temporarily override stance movement

### 3.4 Energy System

- **Pool:** 100 max energy, 5/sec regen (0.25/tick)
- **Costs:** Per weapon per shot (Minigun 1, Railgun 20, etc.)
- **Gating:** Weapons won't fire if insufficient energy. BrottBrain "Conserve" mode only fires cheapest weapon.

### 3.5 BrottBrain System

```
BrottBrain
├── stance: Stance (current active stance)
├── cards: Array[BehaviorCard] (max 8, priority ordered)
└── evaluate(brott, enemies, arena) → Optional[Action]

BehaviorCard
├── trigger: TriggerCard (condition to check)
└── action: ActionCard (what to do if true)
```

**Evaluation:** Each tick, iterate cards top→bottom. First card whose trigger evaluates true fires its action. If no card fires, follow current stance defaults.

**Progressive disclosure:**
- Scrapyard: BrottBrain hidden, uses hardcoded defaults
- Bronze unlock: editor becomes available
- Silver+: full access

### 3.6 Line of Sight

- **Raycast** from Brott center to target center on tile grid
- **Walls:** Block LoS completely
- **Cover:** 50% miss chance (random per shot)
- **Pillars:** Indestructible, block LoS and movement
- **Cover blocks:** Destructible (50 HP), half-height

### 3.7 Progression System

```
GameState (Autoload)
├── current_league: String
├── bolts: int (currency)
├── owned_items: Array[String]
├── unlocked_items: Array[String] (available for purchase)
├── match_history: Array[MatchResult]
└── player_brotts: Array[BrottConfig]
```

Leagues: Scrapyard → Bronze → Silver → Gold → Platinum → Champion (26 total matches).

**Economy:** Win = 100🔩, Loss = 40🔩, First-win bonus = 150🔩. Repair cost: 10% equipment value on win, 25% on loss.

---

## 4. Data Flow

### Signal Architecture

```
TickSystem ──tick_completed──→ Arena (update visuals)
           ──damage_dealt────→ MatchHUD (damage numbers, HP bars)
           ──brott_destroyed─→ MatchManager (check win condition)
           ──match_ended─────→ MatchManager (transition to post-match)

BrottBrain ──stance_changed──→ Brott (update movement behavior)
           ──module_activated→ Brott (trigger module effect)

GameState  ──bolts_changed───→ UI (update currency display)
           ──item_purchased──→ Garage (refresh available items)
           ──league_advanced─→ UI (unlock notification)
```

### Data Ownership

| System | Owns | Reads From |
|---|---|---|
| TickSystem | Tick counter, damage queue, match state | All Brotts, Arena |
| DamageCalculator | Nothing (stateless) | WeaponData, ArmorData |
| BrottBrain | Card evaluation state | Brott stats, enemy stats, Arena |
| GameState | Player progress, economy, inventory | MatchManager (results) |
| MatchManager | Match lifecycle, team setup | GameState, TickSystem |
| Arena | Tile map, LoS cache, environment state | TileMap data |

### Communication Rules
1. **Signals** for events (damage dealt, death, match end, UI updates)
2. **Direct reference** for per-tick queries (Brott position, HP, energy — too frequent for signals)
3. **Autoload access** for global state (GameState, MatchManager)
4. **No cross-Brott direct refs** — Brotts query the TickSystem or Arena for information about other Brotts

---

## 5. Autoloads

| Name | Script | Purpose |
|---|---|---|
| `GameState` | `autoloads/game_state.gd` | Player data, economy, unlocks, settings |
| `MatchManager` | `autoloads/match_manager.gd` | Match lifecycle: setup, run, teardown, transition |

**GameState** persists across scenes. Saves to `user://save.json`.
**MatchManager** owns the TickSystem instance during combat. Handles pre-match setup (spawn Brotts, load arena) and post-match (results, rewards, repair costs).

---

## 6. GDScript Conventions

### Naming
- **Classes:** `PascalCase` (`class_name DamageCalculator`)
- **Functions:** `snake_case` (`func calc_hit()`)
- **Variables:** `snake_case` (`var base_damage`)
- **Constants:** `UPPER_SNAKE` (`const MAX_ENERGY = 100`)
- **Signals:** `snake_case` past tense (`signal damage_dealt`)
- **Private:** Prefix `_` (`func _step_movement()`, `var _damage_queue`)
- **Enums:** `PascalCase` name, `UPPER_SNAKE` values

### File Organization
- One class per file (match filename to class_name)
- Group: `@export` vars → `@onready` vars → constants → signals → public functions → private functions
- Comments for **why**, not what

### Patterns
- **Data classes** (chassis, weapons, armor, modules): Static dictionaries with getter functions. No Godot Resources for v1 — keep it simple.
- **Composition over inheritance:** Brotts use component pattern (BrottBrain, equipment slots) rather than deep class hierarchies.
- **State machines** for match lifecycle: `SETUP → RUNNING → PAUSED → ENDED`

---

## 7. Implementation Phases

### Phase 1 (Sprint 1) — Core Combat
- Tick system with all 7 phases
- Data definitions (all chassis, weapons, armor, modules)
- Damage formula with all edge cases
- Basic movement (move toward target, no A* yet)
- Energy system

### Phase 2 (Sprint 2) — Arena + AI
- A* pathfinding on tile grid
- LoS raycasting
- BrottBrain evaluation engine
- Stance movement behaviors
- Arena tile system (walls, cover, hazards)

### Phase 3 (Sprint 3) — Gameplay Loop
- Garage/build screen
- BrottBrain drag-and-drop editor
- Progression (leagues, unlocks)
- Economy (Bolts, purchases, repairs)
- Match flow (menu → build → fight → results → iterate)

### Phase 4 (Sprint 4) — Polish
- Visual effects (particles, screen shake, slow-mo kills)
- Combat log
- 2v2 and 3v3 team battles
- Balance pass (10,000 sim runs per Playtest Lead)
- Audio

---

*This document is the technical source of truth. All implementation should align with this architecture. Deviations require Lead Dev approval and documented rationale in `kb/decisions/`.*
