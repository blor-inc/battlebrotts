# [S13-001] Real-Time Arena Battle View

**Sprint:** 13 — Make Battles Visual  
**Assignee:** Nutts (dev-01)  
**Priority:** P0 — This IS the sprint  
**Branch:** `dev-01/S13-001-arena-battle-view`  
**PR Title:** `[S13-001] Real-Time Arena Battle View`

## Context

CD feedback from Eric's first playtest:
> "The biggest issue is the battle is not actually simulated visually like a realistic bot battle! Watching your bot perform, and not knowing if they'll pull through."

The match already runs tick-by-tick (`match_hud.gd` drives `step_simulation()` per tick with speed controls). The arena_view.gd already draws the grid and bot circles. **But there's no combat spectacle** — no projectiles, no damage numbers, no hit effects, no health bars in the arena. It's a stat engine with circles.

## What Exists

- `godot/game/ui/arena_view.gd` — Draws tile grid + bot circles (blue/red). Calls `queue_redraw()` on `update_positions()`.
- `godot/game/ui/match_hud.gd` — Has speed controls (1x/5x/20x/100x), HP/energy bars in the HUD panel, tick timer. Drives `step_simulation()` in `_process()`.
- `godot/game/ui/game_controller.gd` — `step_simulation()` runs one tick, emits `match_tick` signal with snapshot data (hp, energy, position, shield_hp, alive).
- `godot/game/combat/tick_system.gd` — The simulation engine. Has `projectiles` array, `_damage_queue`, runs all 7 tick phases.
- `godot/game/combat/projectile.gd` — Projectile data objects with position, velocity, `update()`, `has_arrived()`.

## Requirements

### 1. Enhance arena_view.gd — Visual Combat

The arena view must show the FIGHT, not just positions.

**Projectiles:**
- Draw all active projectiles from `tick_system.projectiles` each frame
- Bullets = small white circles (radius 3px)
- Missiles = slightly larger orange rectangles (4x8px)
- Arc Emitter = yellow line from attacker to target

**Damage Numbers:**
- When damage is dealt, spawn a floating number at the hit position
- White text for normal hits, yellow for crits
- Float upward and fade out over ~0.5 seconds (10 ticks)
- Track these as an array of `{position, text, color, remaining_ticks}`

**Health Bars (in-arena, above each bot):**
- Small HP bar above each bot (green→yellow→red based on %)
- Small energy bar below HP bar (blue)
- These are IN the arena view, not the HUD panel

**Shield Effect:**
- When a bot has `shield_hp > 0`, draw a translucent blue circle around it (radius slightly larger than bot)

**Hit Flash:**
- When a bot takes damage, flash it white for 2 ticks

**Bot Death:**
- When a bot dies, show a brief explosion effect (expanding red circle that fades)

### 2. Enhance game_controller.gd — Richer Snapshots

The `step_simulation()` snapshot needs more data for the arena view to render:

- Include `projectiles` array (position + type for each)
- Include `damage_events` from this tick (target position, damage amount, is_crit)
- Include `deaths` this tick (which bots died)

Add these to the snapshot dict emitted via `match_tick`.

### 3. Update match_hud.gd — Speed Controls

Current speed options are `[1, 5, 20, 100]`. Change to `[1, 2, 5]` per the GDD. Remove 20x and 100x — we want people to WATCH the fight.

### 4. Match Result Overlay

When the match ends, show a result overlay ON the arena view:
- Large text: "VICTORY!" (green) or "DEFEAT!" (red) or "DRAW!" (yellow)
- Subtext showing remaining HP
- Brief pause before allowing the player to continue

## Technical Notes

- All rendering should use Godot's `_draw()` method in arena_view.gd (same approach as current)
- For floating damage numbers, maintain an array and update/draw them in `_draw()` + `_process()`
- The tick_system already tracks projectiles — just need to expose their positions in snapshots
- Keep it simple — colored shapes, not sprites. This is a prototype.
- Reference GDD Section 5 (Combat System) and Section 10 (Art Direction) for specs

## Files to Modify

- `godot/game/ui/arena_view.gd` — Main visual enhancement
- `godot/game/ui/game_controller.gd` — Richer snapshots
- `godot/game/ui/match_hud.gd` — Speed control update
- `godot/game/combat/tick_system.gd` — Expose damage events per tick (add a `tick_events` array)

## Files to Reference (READ ONLY)

- `docs/gdd.md` — Sections 5 and 10
- `godot/game/combat/projectile.gd`
- `godot/game/entities/brott.gd`

## Acceptance Criteria

- [ ] Projectiles visually travel between bots
- [ ] Damage numbers float up on hit (white normal, yellow crit)  
- [ ] In-arena health/energy bars above each bot
- [ ] Shield visual when active
- [ ] Hit flash on damage
- [ ] Death explosion effect
- [ ] Speed controls: 1x, 2x, 5x
- [ ] Match result overlay
- [ ] All changes on `dev-01/S13-001-arena-battle-view` branch
- [ ] PR opened with title `[S13-001] Real-Time Arena Battle View`
