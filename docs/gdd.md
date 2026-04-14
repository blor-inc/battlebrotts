# BotForge — Game Design Document

**Version:** 1.0
**Date:** 2026-04-14
**Engine:** Godot 4 (HTML5 export)
**Team Size:** 1–2 developers

---

## 1. Elevator Pitch

Build autonomous combat bots by choosing a chassis, bolting on weapons and armor, then programming their brain with simple if/then firmware rules. Watch your creation fight in top-down arenas where strategy beats stats — two identical loadouts perform completely differently based on firmware. It's mech tinkering meets programming puzzles meets spectator sport.

---

## 2. Core Loop

1. **Build** — Select chassis, equip weapons/armor/modules within weight budget
2. **Program** — Set Stances and Tactics (firmware rules) that govern autonomous behavior
3. **Fight** — Deploy bot into arena, watch the match play out (no direct control)
4. **Analyze** — Review combat log, identify what went wrong
5. **Iterate** — Tweak loadout or firmware, re-queue

Average loop iteration: 3–5 minutes.

---

## 3. Bot Customization

### 3.1 Chassis Types

| Chassis | HP | Speed (px/s) | Weight Cap | Weapon Slots | Module Slots |
|---|---|---|---|---|---|
| **Scout** | 80 | 200 | 30 kg | 1 | 3 |
| **Brawler** | 150 | 120 | 55 kg | 2 | 2 |
| **Fortress** | 250 | 70 | 80 kg | 3 | 1 |

Base chassis weight is excluded from the weight budget — only equipped items count against capacity.

### 3.2 Weapons

| Weapon | Damage | Range (tiles) | Fire Rate (shots/s) | Spread (°) | Energy/Shot | Weight (kg) |
|---|---|---|---|---|---|---|
| **Minigun** | 4 | 5 | 10 | 15 | 1 | 10 |
| **Railgun** | 45 | 12 | 0.5 | 0 | 20 | 15 |
| **Shotgun** | 6×5 pellets | 3 | 1.5 | 30 | 8 | 12 |
| **Missile Pod** | 30 (splash r=1 tile) | 8 | 0.8 | 5 | 12 | 18 |
| **Plasma Cutter** | 12 | 1.5 | 3 | 0 | 4 | 8 |
| **Arc Emitter** | 8 (chains to 1 extra target within 2 tiles) | 4 | 2 | 10 | 6 | 11 |
| **Flak Cannon** | 15 | 6 | 1.2 | 20 | 7 | 13 |

All bots share a single energy pool: **100 max energy**, regenerating at **5 energy/sec**.

### 3.3 Armor

| Armor | Damage Reduction | Weight (kg) | Special |
|---|---|---|---|
| **Plating** | 20% | 15 | None — reliable baseline |
| **Reactive Mesh** | 10% | 8 | Reflects 5 flat damage back to attacker on hit |
| **Ablative Shell** | 40% | 25 | Reduction drops to 10% once bot is below 30% HP |

Only one armor type can be equipped at a time. Armor occupies no slot — it's a dedicated equip.

### 3.4 Modules

| Module | Effect | Weight (kg) |
|---|---|---|
| **Overclock** | +30% fire rate for 4 sec, then 3 sec cooldown where fire rate is −20%. Activated via Tactic. | 5 |
| **Repair Nanites** | Restores 3 HP/sec passively. | 7 |
| **Shield Projector** | Activated: absorbs next 40 damage within 5 sec, 20 sec cooldown. | 10 |
| **Sensor Array** | +3 tile sight range, reveals bots behind partial cover. | 4 |
| **Afterburner** | Activated: +80% move speed for 2 sec, 12 sec cooldown. | 6 |
| **EMP Charge** | Activated: disables target's modules for 3 sec, 25 sec cooldown. Range: 4 tiles. | 9 |

### 3.5 Slot System

- Each weapon or module occupies exactly **1 slot** of its type.
- Total equipped item weight must be ≤ chassis weight capacity.
- Armor has no slot cost but counts against weight.
- Example: Brawler (55 kg cap, 2 weapon slots, 2 module slots) could equip Minigun (10 kg) + Shotgun (12 kg) + Plating (15 kg) + Repair Nanites (7 kg) + Overclock (5 kg) = 49 kg ✓

---

## 4. Firmware System (THE TWIST)

Firmware is a priority-ordered list of **Tactic** rules evaluated top-to-bottom each tick, layered on top of a current **Stance** that provides default behavior. The first Tactic whose condition is true fires; if none match, the bot follows its current Stance defaults.

### 4.1 Stances

Each bot has exactly one active Stance at any time. Stances define default movement and engagement patterns.

| Stance | Movement Behavior | Engagement Behavior |
|---|---|---|
| **Aggressive** | Move directly toward nearest enemy. Close to within shortest weapon range. | Fire all weapons as soon as in range. Prioritize DPS uptime. |
| **Defensive** | Retreat to nearest cover. If no cover, maintain max weapon range from enemy. | Fire only when enemy is within 80% of max range. Prefer cover over optimal firing position. |
| **Kiting** | Maintain distance between 60–80% of max weapon range. Circle-strafe clockwise. | Fire while moving. Disengage if enemy closes within 40% of max range. |
| **Ambush** | Move to nearest cover and hold position. Do not move unless condition triggers. | Fire only when enemy enters 50% of max range (point-blank alpha strike). |

### 4.2 Tactics

Players build an ordered list of up to **8 Tactic rules**. Each rule is: `IF <condition> THEN <action>`.

**Available Conditions:**

| Condition | Parameters |
|---|---|
| `my_hp_below` | Threshold: 10–90% (step 10) |
| `my_hp_above` | Threshold: 10–90% |
| `my_energy_below` | Threshold: 10–90% |
| `my_energy_above` | Threshold: 10–90% |
| `enemy_hp_below` | Threshold: 10–90% |
| `enemy_distance_less` | Distance: 1–12 tiles |
| `enemy_distance_greater` | Distance: 1–12 tiles |
| `enemy_in_cover` | Boolean |
| `module_ready` | Module name (off cooldown) |
| `match_time_above` | Seconds: 10–120 |

**Available Actions:**

| Action | Description |
|---|---|
| `switch_stance` | Change to specified Stance |
| `activate_module` | Use a specific activated module |
| `set_target_priority` | `nearest` / `lowest_hp` / `highest_threat` |
| `set_weapon_mode` | `all_fire` / `conserve` (fire only primary) / `hold_fire` |
| `move_to_cover` | Override stance movement: go to nearest cover |
| `move_to_center` | Override stance movement: go to arena center |

### 4.3 Example Firmware Strategies

**"Glass Cannon" (Scout + Railgun)**
- Stance: Kiting
1. `IF my_hp_below 40% THEN activate_module Shield Projector`
2. `IF enemy_distance_less 3 THEN activate_module Afterburner`
3. `IF enemy_distance_less 3 THEN switch_stance Kiting` *(re-establish distance)*
4. `IF enemy_hp_below 30% THEN switch_stance Aggressive` *(finish them off)*
5. `IF my_energy_below 20% THEN set_weapon_mode conserve`

**"Juggernaut" (Fortress + Minigun + Shotgun + Missile Pod)**
- Stance: Aggressive
1. `IF my_hp_below 50% THEN activate_module Shield Projector`
2. `IF enemy_distance_less 2 THEN set_weapon_mode all_fire` *(shotgun range = max pain)*
3. `IF enemy_distance_greater 6 THEN set_weapon_mode conserve` *(missiles only)*
4. `IF enemy_in_cover THEN set_target_priority nearest` *(close the gap)*
5. `IF match_time_above 60 THEN switch_stance Aggressive` *(stop stalling)*

**"Roach" (Scout + Plasma Cutter + Repair Nanites + Afterburner + Sensor Array)**
- Stance: Ambush
1. `IF my_hp_below 30% THEN switch_stance Defensive`
2. `IF my_hp_above 70% THEN switch_stance Ambush`
3. `IF enemy_distance_less 2 THEN activate_module Afterburner` *(escape)*
4. `IF enemy_distance_less 2 THEN switch_stance Kiting`
5. `IF module_ready Afterburner THEN switch_stance Ambush` *(re-engage when escape is available)*

*Strategy: hide, heal with nanites, ambush with plasma cutter, flee when caught. Outlast the enemy.*

---

## 5. Combat System

### 5.1 Tick System

- Simulation runs at **20 ticks/sec** (50 ms per tick).
- Each tick, in order:
  1. **Firmware evaluation** — check Tactic rules top-to-bottom, fire first match
  2. **Energy regen** — +0.25 energy this tick (5/sec)
  3. **Module tick** — cooldown timers decrement, passive effects apply (e.g., Repair Nanites: +0.15 HP/tick)
  4. **Movement** — bot moves according to Stance/override at its speed
  5. **Weapon fire** — each weapon checks fire rate timer, fires if ready and target in range/LoS
  6. **Projectile update** — projectiles advance, hit detection resolved
  7. **Damage application** — HP adjusted, death check
- Combat is **fully deterministic** given the same seed — enables headless replay and automated testing.

### 5.2 Damage Formula

```
effective_damage = base_damage × (1 - armor_reduction) × crit_multiplier

crit_chance = 5%
crit_multiplier = 1.5× (if crit) or 1.0× (if not)
```

- **Splash damage** (Missile Pod): full damage at impact tile, 50% damage at radius tiles.
- **Reactive Mesh reflect**: 5 flat damage applied to attacker after armor calc, ignores attacker's armor.
- **Minimum damage**: 1 (no attack deals 0).
- **Pellet weapons** (Shotgun): each pellet rolls independently. 6 damage × 5 pellets, each with its own hit check based on spread.

**Hit calculation for spread weapons:**
Each pellet/bullet has a random angle offset within ±(spread/2). If the offset ray intersects the target's hitbox (circle, radius = 12 px), it hits.

### 5.3 Movement & Targeting

- **Pathfinding**: A* on the tile grid (32×32 px tiles). Recalculated every 10 ticks (2×/sec).
- **Default target selection**: Nearest enemy (Euclidean distance). Overridable via `set_target_priority`:
  - `nearest` — closest by distance
  - `lowest_hp` — lowest current HP
  - `highest_threat` — highest DPS output in last 40 ticks
- **Collision**: Bots cannot overlap. Bots colliding with walls or each other slide along the surface.
- **Circle-strafe** (Kiting stance): bot moves perpendicular to the line between itself and its target, maintaining range band.

### 5.4 Line of Sight & Range

- **LoS**: Raycast from bot center to target center on the tile grid. If the ray passes through a wall tile, LoS is blocked. Cover tiles block 50% of rays (randomly determined per shot — effectively a 50% miss chance).
- **Range bands** (for Stance behavior, in tiles):
  - **Melee**: 0–2
  - **Close**: 2–5
  - **Mid**: 5–8
  - **Long**: 8–12
- Weapons cannot fire beyond their listed range. No damage falloff within range.

---

## 6. Progression

### 6.1 League Structure

| League | Opponents | Unlock Requirement | New Content Unlocked |
|---|---|---|---|
| **Scrapyard** (Tutorial) | 3 | Start of game | Scout chassis, Minigun, Plasma Cutter, Plating |
| **Bronze** | 5 | Beat Scrapyard | Brawler chassis, Shotgun, Arc Emitter, Reactive Mesh, Overclock, Repair Nanites |
| **Silver** | 5 | Beat 3/5 Bronze | Fortress chassis, Railgun, Flak Cannon, Shield Projector, Sensor Array |
| **Gold** | 5 | Beat 3/5 Gold | Missile Pod, Ablative Shell, Afterburner, EMP Charge |
| **Platinum** | 5 | Beat 3/5 Gold | All items available. Enemy bots use advanced firmware. |
| **Champion** | 3 | Beat 5/5 Platinum | Endgame. Handcrafted boss bots with unique loadouts. |

Total: **26 matches** to complete all leagues.

### 6.2 Difficulty Curve

- **Scrapyard**: Enemies use 1 weapon, no modules, Aggressive stance only, 0 Tactics.
- **Bronze**: Enemies use armor + 1 module, 1–2 Tactics.
- **Silver**: Full loadouts, 3–4 Tactics, mix of Stances.
- **Gold**: Optimized builds, 5–6 Tactics, counter-strategies to common player builds.
- **Platinum**: Near-optimal firmware, adaptive target priority, 7–8 Tactics.
- **Champion**: Bespoke designs that exploit specific weaknesses. Each is a puzzle.

Enemy bot stat scaling: **none**. Enemies use the same items and stats as the player. Difficulty comes from better firmware and loadout synergy.

---

## 7. Economy

### 7.1 Currency

Single currency: **Scrap (₴)**.

| Result | Scrap Earned |
|---|---|
| Win | 100 ₴ |
| Loss | 40 ₴ |
| Win (first time vs. opponent) | 150 ₴ (bonus) |

### 7.2 Item Costs

**Chassis:**
| Item | Cost |
|---|---|
| Scout | Free (starter) |
| Brawler | 200 ₴ |
| Fortress | 400 ₴ |

**Weapons:**
| Item | Cost |
|---|---|
| Minigun | Free (starter) |
| Plasma Cutter | Free (starter) |
| Shotgun | 120 ₴ |
| Arc Emitter | 150 ₴ |
| Flak Cannon | 200 ₴ |
| Railgun | 300 ₴ |
| Missile Pod | 350 ₴ |

**Armor:**
| Item | Cost |
|---|---|
| Plating | Free (starter) |
| Reactive Mesh | 150 ₴ |
| Ablative Shell | 300 ₴ |

**Modules:**
| Item | Cost |
|---|---|
| Overclock | 100 ₴ |
| Repair Nanites | 120 ₴ |
| Sensor Array | 150 ₴ |
| Shield Projector | 200 ₴ |
| Afterburner | 180 ₴ |
| EMP Charge | 250 ₴ |

All purchases are permanent. No consumables.

### 7.3 Repair Costs

After each match, the bot takes wear damage regardless of outcome:
- **Win**: Repair cost = 10% of bot's total equipment value
- **Loss**: Repair cost = 25% of bot's total equipment value
- Repair is mandatory before next match
- This creates an economic pressure that prevents players from hoarding scrap

Example: Bot with 500 ₴ of equipment → 50 ₴ repair on win, 125 ₴ on loss.

---

## 8. Arena Design

### 8.1 Arena Types

| Arena | Size (tiles) | Features | Strategy Impact |
|---|---|---|---|
| **The Pit** | 16×16 | Open floor, no cover, 4 pillars in center | Pure build vs build. Nowhere to hide. Favors DPS and armor. |
| **Junkyard** | 20×20 | Scattered cover blocks (8–10), 2 elevated platforms | Rewards Defensive/Ambush stances. Cover-based play. |
| **Foundry** | 20×16 | Conveyor belts (push bots 1 tile/sec in belt direction), lava tiles (10 damage/sec on contact) | Environmental awareness matters. Kiting around hazards. |

### 8.2 Environmental Features

- **Walls**: Block movement and LoS completely.
- **Cover blocks**: Half-height. Block 50% of shots (per-shot random). Bots can path around them. Destructible: 50 HP, removed when destroyed.
- **Pillars**: Indestructible cover. Block movement and LoS.
- **Conveyor belts**: Push any bot on them 1 tile/sec in the indicated direction. Can push into walls (no damage) or hazards.
- **Lava tiles**: 10 damage/sec to any bot standing on them. Ignores armor.

---

## 9. Match Format

- **Format**: 1v1 (player bot vs enemy bot)
- **Win condition**: Reduce enemy HP to 0
- **Loss condition**: Your bot reaches 0 HP
- **Draw condition**: If neither bot is destroyed after **120 seconds**, the bot with higher remaining HP% wins. If tied, it's a draw (counts as a loss for progression, but awards 40 ₴).
- **Target match length**: 30–60 seconds for most fights. 120 sec timeout prevents stalemate builds.

---

## 10. Art Direction

### Visual Style
- **Top-down 2D**, camera fixed overhead
- **Tile size**: 32×32 pixels
- **Bot size**: 24×24 pixels (fits within a tile with clearance)
- **Style**: Clean pixel art or simple vector shapes. Asset-pack friendly.
- **Color coding**: Player bot = blue tones. Enemy bot = red tones. Neutral environment = grey/brown.

### Camera
- Fixed camera showing the full arena. No scrolling needed (max arena 20×20 tiles = 640×640 px game area).
- UI panels on sides/bottom.

### UI Layout
```
┌─────────────────────────────────┐
│  [Player Bot Info]  [Enemy Bot] │
│  HP ████████░░  HP ██████░░░░   │
│  EN ██████░░░░  EN ████░░░░░░   │
├─────────────────────────────────┤
│                                 │
│         ARENA VIEW              │
│        (640×640 px)             │
│                                 │
├─────────────────────────────────┤
│  [Combat Log]  [Speed: 1x 2x]  │
│  > Minigun hits for 3 dmg       │
│  > Shield Projector activated   │
└─────────────────────────────────┘
```

### Visual Feedback
- **Damage numbers**: Float up from hit location, white for normal, yellow for crit
- **Projectiles**: Visible bullets/missiles traveling between bots
- **Shield**: Blue circle overlay when Shield Projector active
- **Health bar**: Above each bot, green→yellow→red
- **Stance indicator**: Small icon below bot showing current stance

---

## 11. Key Metrics for Playtest Lead

### Balance Metrics
- **Win rate by chassis**: Should be 45–55% for each across all matchups
- **Weapon usage distribution**: No single weapon should appear in >60% of winning builds
- **Time-to-kill by tier**: Scrapyard 15–30s, Bronze 20–40s, Silver 25–50s, Gold/Platinum 30–60s
- **Economy flow**: Player should afford 1 new item every 2–3 matches
- **Firmware diversity**: Track how many distinct Tactic combinations lead to wins — more = better
- **Stance usage**: All 4 stances should appear in winning strategies

### Feel Metrics
- **Match length distribution**: Target bell curve centered at 45s, hard cap 120s
- **Pacing**: At least 1 significant event (stance switch, module activation, HP threshold crossed) every 5 seconds
- **Build diversity across leagues**: % of unique loadouts in player wins per league
- **Comeback rate**: % of matches where the bot that took first damage wins — target ~35%
- **Stalemate rate**: % of matches hitting 120s timeout — target <5%

### Simulation Tests
- Run 10,000 combat simulations per balance pass
- Test every weapon against every armor type
- Test every chassis matchup (Scout v Brawler, Scout v Fortress, Brawler v Fortress)
- Verify no item combination produces >70% win rate against the field
- Verify economy allows completing the game without grinding (target: <40 total matches)

---

## 12. Player Fantasy

The core feelings we're targeting:

1. **"I'm a mad scientist."** — The joy of tinkering, building, and experimenting with different combinations. The garage/workshop is your lab.

2. **"My creation is alive."** — Watching your bot make decisions autonomously based on YOUR firmware. Pride when it does something clever. Horror when it does something stupid.

3. **"I cracked the code."** — The eureka moment when a firmware tweak turns a losing matchup into a win. The puzzle satisfaction of outsmarting the enemy through programming, not reflexes.

4. **"Just one more fight."** — The loop of lose → analyze → tweak → try again is addictive. Each loss teaches you something. Each win validates your design.

5. **"Wait, I can do THAT?"** — Discovering unexpected synergies between items and firmware rules. The Roach build (ambush + heal + flee) should feel like a discovery, not an obvious path.

---

*This document is the source of truth for BotForge's design. All implementation should reference this. Changes require Game Designer approval and updated version number.*
