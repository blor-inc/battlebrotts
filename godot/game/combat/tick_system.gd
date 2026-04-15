# tick_system.gd — Main combat simulation loop from GDD v2 §5.1
# BattleBrotts Core Combat · S1-003
#
# Tick order (20 ticks/sec, 50 ms per tick):
#   1. BrottBrain evaluation
#   2. Energy regen
#   3. Module tick
#   4. Movement
#   5. Weapon fire
#   6. Projectile update
#   7. Damage application
#
# Combat is fully deterministic given the same RNG seed.
class_name TickSystem

const _Projectile = preload("res://game/combat/projectile.gd")

const TICKS_PER_SECOND: int = 20
const TICK_DELTA: float = 1.0 / TICKS_PER_SECOND  # 0.05s
const PIXELS_PER_TILE: float = 32.0
const MAX_MATCH_TICKS: int = 120 * TICKS_PER_SECOND  # 120s timeout

# ── State ────────────────────────────────────────────────
var brotts: Array = []       # all Brott instances in the match
var tick: int = 0
var rng: RandomNumberGenerator
var match_over: bool = false
var winner_team: int = -1    # -1 = undecided

# Pending damage events applied at end of tick (step 7).
# Each entry: { "target": Brott, "damage": float, "attacker": Brott,
#               "reflect_damage": float, "is_crit": bool }
var _damage_queue: Array = []

# Active projectiles in flight
var projectiles: Array = []

# Visual events emitted each tick for rendering (cleared each tick)
# Each entry: { "type": String, "position": Vector2, ... }
var tick_events: Array = []

# ─────────────────────────────────────────────────────────
# Init
# ─────────────────────────────────────────────────────────
func _init() -> void:
	rng = RandomNumberGenerator.new()

func setup(seed_value: int, combatants: Array) -> void:
	rng.seed = seed_value
	brotts = combatants
	tick = 0
	match_over = false
	winner_team = -1
	projectiles.clear()

# ─────────────────────────────────────────────────────────
# Run one tick — returns true if match continues
# ─────────────────────────────────────────────────────────
func run_tick() -> bool:
	if match_over:
		return false

	_damage_queue.clear()
	tick_events.clear()

	# 1. BrottBrain evaluation (stub — future S1-004)
	_step_brottbrain()

	# 2. Energy regen
	_step_energy_regen()

	# 3. Module tick
	_step_module_tick()

	# 4. Movement
	_step_movement()

	# 5. Weapon fire
	_step_weapon_fire()

	# 6. Projectile update (stub — instant hit for now)
	_step_projectile_update()

	# 7. Damage application
	_step_damage_application()

	tick += 1

	# Check win/loss/timeout
	_check_match_end()

	return not match_over

# ─────────────────────────────────────────────────────────
# Run the full match to completion. Returns winner_team.
# ─────────────────────────────────────────────────────────
func run_match() -> int:
	while run_tick():
		pass
	return winner_team

# ═════════════════════════════════════════════════════════
# TICK STEPS
# ═════════════════════════════════════════════════════════

# 1. BrottBrain — stub for now, just assign nearest enemy as target
func _step_brottbrain() -> void:
	for b: Brott in brotts:
		if b.is_dead():
			continue
		# Simple nearest-enemy targeting
		var best_dist := INF
		var best_target: Brott = null
		for other: Brott in brotts:
			if other.is_dead() or other.team == b.team:
				continue
			var d := b.position.distance_to(other.position)
			if d < best_dist:
				best_dist = d
				best_target = other
		b.target = best_target

# 2. Energy regen
func _step_energy_regen() -> void:
	for b: Brott in brotts:
		if b.is_dead():
			continue
		b.regen_energy()

# 3. Module tick — passive effects + cooldown tracking
func _step_module_tick() -> void:
	for b: Brott in brotts:
		if b.is_dead():
			continue
		for mid in b.module_ids:
			var mdata := ModuleData.get_module(mid)
			var mstate: Dictionary = b.module_states[mid]

			# Decrement cooldowns
			if mstate["cooldown_ticks"] > 0:
				mstate["cooldown_ticks"] -= 1
			if mstate["active_ticks"] > 0:
				mstate["active_ticks"] -= 1

			# Passive: Repair Nanites
			if mdata["effect"] == "heal_per_tick" and mdata["passive"]:
				b.apply_heal(mdata["heal_per_tick"])

			# Shield Projector: decay active ticks, clear shield when expired
			if mdata["effect"] == "absorb_shield":
				if mstate["active_ticks"] <= 0:
					b.shield_hp = 0.0

# 4. Movement — move toward target at chassis speed (A* stubbed)
func _step_movement() -> void:
	for b: Brott in brotts:
		if b.is_dead() or b.target == null:
			continue
		var direction := (b.target.position - b.position).normalized()
		var move_px := b.speed * TICK_DELTA  # px this tick

		# Don't overshoot — stop at minimum weapon range (if any weapon equipped)
		var min_range_px := _min_weapon_range_px(b)
		var dist := b.position.distance_to(b.target.position)

		if dist > min_range_px:
			var step := minf(move_px, dist - min_range_px)
			b.position += direction * step

# 5. Weapon fire — check cooldown, range, energy, then fire
func _step_weapon_fire() -> void:
	for b: Brott in brotts:
		if b.is_dead() or b.target == null or b.target.is_dead():
			continue
		for i in b.weapon_ids.size():
			var wid: String = b.weapon_ids[i]
			var wdata := WeaponData.get_weapon(wid)

			# Cooldown tick
			if b.weapon_cooldowns[i] > 0:
				b.weapon_cooldowns[i] -= 1
				continue

			# Range check (tiles)
			var dist_tiles := b.distance_to_brott(b.target)
			if dist_tiles > wdata["range"]:
				continue

			# Energy check
			if not b.spend_energy(float(wdata["energy_cost"])):
				continue

			# Fire! Calc damage per pellet
			var hits := DamageCalculator.calc_weapon_shot(
				wid, b.target.armor_id, b.target.hp_ratio(), rng)

			# Check if this weapon uses projectiles (non-hitscan)
			var proj_speed: float = _Projectile.PROJECTILE_SPEEDS.get(wid, 0.0)

			if proj_speed > 0.0:
				# Create a projectile — damage resolved on arrival in phase 6
				for hit in hits:
					if _spread_hit_check(wdata, dist_tiles, rng):
						var proj = _Projectile.create(
							wid, b, b.target,
							hit["damage"], hit["is_crit"],
							float(wdata["splash_radius"]),
							wdata["chain_targets"])
						projectiles.append(proj)
			else:
				# Hitscan — instant damage this tick
				for hit in hits:
					if _spread_hit_check(wdata, dist_tiles, rng):
						_damage_queue.append({
							"target": b.target,
							"damage": hit["damage"],
							"attacker": b,
							"reflect_damage": hit["reflect_damage"],
							"is_crit": hit["is_crit"],
						})

				# Splash damage for hitscan splash weapons
				if wdata["splash_radius"] > 0:
					for other: Brott in brotts:
						if other == b.target or other.is_dead() or other.team == b.team:
							continue
						var splash_dist := b.target.distance_to_brott(other)
						if splash_dist <= wdata["splash_radius"]:
							var splash := DamageCalculator.calc_splash(
								float(wdata["damage"]), other.armor_id,
								other.hp_ratio(), rng)
							_damage_queue.append({
								"target": other,
								"damage": splash["damage"],
								"attacker": b,
								"reflect_damage": splash["reflect_damage"],
								"is_crit": splash["is_crit"],
							})

			# Chain damage (Arc Emitter)
			if wdata["chain_targets"] > 0 and hits.size() > 0:
				_apply_chain(b, b.target, wdata)

			# Reset cooldown
			b.weapon_cooldowns[i] = WeaponData.fire_interval_ticks(wid)

# 6. Projectile update — move projectiles, resolve arrivals
func _step_projectile_update() -> void:
	var still_alive: Array = []
	for proj in projectiles:
		proj.update()
		if proj.has_arrived():
			_resolve_projectile_hit(proj)
		elif proj.alive:
			still_alive.append(proj)
		# else: expired, discard
	projectiles = still_alive

func _resolve_projectile_hit(proj) -> void:
	if proj.target == null or proj.target.is_dead():
		return
	# Apply direct damage
	var hit := DamageCalculator.calc_hit(
		proj.damage, proj.target.armor_id,
		proj.target.hp_ratio(), rng)
	_damage_queue.append({
		"target": proj.target,
		"damage": hit["damage"],
		"attacker": proj.attacker,
		"reflect_damage": hit["reflect_damage"],
		"is_crit": hit["is_crit"],
	})
	# Splash damage
	if proj.splash_radius > 0:
		for other: Brott in brotts:
			if other == proj.target or other.is_dead() or other.team == proj.attacker.team:
				continue
			var splash_dist: float = proj.target.distance_to_brott(other)
			if splash_dist <= proj.splash_radius:
				var splash := DamageCalculator.calc_splash(
					proj.damage, other.armor_id,
					other.hp_ratio(), rng)
				_damage_queue.append({
					"target": other,
					"damage": splash["damage"],
					"attacker": proj.attacker,
					"reflect_damage": splash["reflect_damage"],
					"is_crit": splash["is_crit"],
				})

# 7. Damage application — process queue, apply reflect
func _step_damage_application() -> void:
	for event in _damage_queue:
		var target: Brott = event["target"]
		var attacker: Brott = event["attacker"]
		if target.is_dead():
			continue
		target.apply_damage(event["damage"])

		# Emit visual event for damage number
		tick_events.append({
			"type": "damage",
			"position": target.position,
			"amount": event["damage"],
			"is_crit": event["is_crit"],
		})

		# Emit hit flash event
		tick_events.append({
			"type": "hit",
			"target_id": target.id,
		})

		# Check if target just died
		if target.is_dead():
			tick_events.append({
				"type": "death",
				"position": target.position,
				"target_id": target.id,
			})

		# Reactive Mesh reflect (flat damage, ignores attacker armor)
		if event["reflect_damage"] > 0.0 and attacker.alive:
			attacker.apply_damage(event["reflect_damage"])

# ═════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════

func _min_weapon_range_px(b: Brott) -> float:
	var min_range := INF
	for wid in b.weapon_ids:
		var r: float = float(WeaponData.get_weapon(wid)["range"]) * PIXELS_PER_TILE
		min_range = minf(min_range, r)
	if min_range == INF:
		return 0.0
	return min_range

## Spread-based hit check. 0-spread weapons always hit.
## For spread weapons: model as probability based on target angular size vs spread.
func _spread_hit_check(wdata: Dictionary, dist_tiles: float, r: RandomNumberGenerator) -> bool:
	var spread_deg: float = wdata["spread"]
	if spread_deg <= 0.0:
		return true
	if dist_tiles <= 0.0:
		return true

	# Target hitbox radius = 12 px (GDD §5.2). Angular size at distance.
	var target_radius_px := 12.0
	var dist_px := dist_tiles * PIXELS_PER_TILE
	# Half-angle subtended by target
	var target_half_angle := rad_to_deg(atan2(target_radius_px, dist_px))
	var spread_half := spread_deg / 2.0

	# Random offset within ±spread/2
	var offset := r.randf_range(-spread_half, spread_half)
	return absf(offset) <= target_half_angle

## Arc Emitter chain: find nearest enemy within chain_range of primary target
func _apply_chain(attacker: Brott, primary_target: Brott, wdata: Dictionary) -> void:
	var chain_range: float = wdata.get("chain_range", 2.0)
	var best_dist := INF
	var chain_target: Brott = null
	for other: Brott in brotts:
		if other == primary_target or other == attacker or other.is_dead():
			continue
		if other.team == attacker.team:
			continue
		var d := primary_target.distance_to_brott(other)
		if d <= chain_range and d < best_dist:
			best_dist = d
			chain_target = other
	if chain_target != null:
		var hit := DamageCalculator.calc_hit(
			float(wdata["damage"]), chain_target.armor_id,
			chain_target.hp_ratio(), rng)
		_damage_queue.append({
			"target": chain_target,
			"damage": hit["damage"],
			"attacker": attacker,
			"reflect_damage": hit["reflect_damage"],
			"is_crit": hit["is_crit"],
		})

## Check win condition
func _check_match_end() -> void:
	if tick >= MAX_MATCH_TICKS:
		# Timeout: team with higher total HP% wins
		_resolve_timeout()
		return

	# Check if all brotts on a team are dead
	var teams_alive := {}
	for b: Brott in brotts:
		if b.alive:
			teams_alive[b.team] = true

	if teams_alive.size() <= 1:
		match_over = true
		if teams_alive.size() == 1:
			winner_team = teams_alive.keys()[0]
		else:
			winner_team = -1  # mutual destruction = draw

func _resolve_timeout() -> void:
	match_over = true
	var team_hp: Dictionary = {}  # team → total HP ratio
	var team_count: Dictionary = {}
	for b: Brott in brotts:
		if not team_hp.has(b.team):
			team_hp[b.team] = 0.0
			team_count[b.team] = 0
		team_count[b.team] += 1
		team_hp[b.team] += b.hp_ratio()

	# Average HP%
	var best_team := -1
	var best_avg := -1.0
	var is_tie := false
	for t in team_hp:
		var avg: float = team_hp[t] / float(team_count[t])
		if avg > best_avg:
			best_avg = avg
			best_team = t
			is_tie = false
		elif avg == best_avg:
			is_tie = true

	winner_team = -1 if is_tie else best_team
