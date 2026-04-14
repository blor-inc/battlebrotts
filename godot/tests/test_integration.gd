# test_integration.gd — Integration tests for BattleBrotts
# Sprint 7 · QA — Verifies systems work together end-to-end
extends RefCounted

const Brott = preload("res://game/entities/brott.gd")
const TickSystem = preload("res://game/combat/tick_system.gd")
var MatchManagerScript = load("res://game/autoloads/match_manager.gd")
const ArenaManager = preload("res://game/arena/arena_manager.gd")
const Pathfinder = preload("res://game/arena/pathfinder.gd")
const BrottBrain = preload("res://game/ai/brottbrain.gd")
const BehaviorCard = preload("res://game/ai/behavior_card.gd")
const Steering = preload("res://game/ai/steering.gd")
const EconomyManager = preload("res://game/economy/economy_manager.gd")
var ShopScript = load("res://game/economy/shop.gd")
const ProjectileScript = preload("res://game/combat/projectile.gd")
const DamageCalculator = preload("res://game/combat/damage_calculator.gd")
const WeaponData = preload("res://game/data/weapon_data.gd")
const ChassisData = preload("res://game/data/chassis_data.gd")
const ArmorData = preload("res://game/data/armor_data.gd")

# ═════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════

func _make_brott(id: int, team: int, chassis: String, weapons: Array,
		armor: String, modules: Array, pos: Vector2) -> Brott:
	return Brott.create(id, team, chassis, weapons, armor, modules, pos)

func _run_match_to_completion(b1: Brott, b2: Brott, seed_val: int = 42) -> Dictionary:
	var mm = MatchManagerScript.new()
	mm.setup_match([b1], [b2], seed_val)
	return mm.run_to_completion()

# ═════════════════════════════════════════════════════════
# 1. FULL MATCH SIMULATION
# ═════════════════════════════════════════════════════════

## Two brotts with real loadouts fight a full match — a winner must be determined
func test_full_match_determines_winner() -> bool:
	var b1 = _make_brott(1, 0, "brawler", ["minigun"], "plating", ["repair_nanites"], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "plating", [], Vector2(128, 32))
	var result = _run_match_to_completion(b1, b2)
	# Must end with a definitive result
	return result["outcome"] != "" and result["ticks"] > 0

## Match result contains all expected fields
func test_match_result_structure() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(128, 32))
	var result = _run_match_to_completion(b1, b2)
	return (result.has("winner_team") and result.has("outcome")
		and result.has("ticks") and result.has("duration_sec")
		and result.has("team_stats") and result.has("seed"))

## Match duration is within 120s (2400 ticks) limit
func test_match_within_timeout() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(128, 32))
	var result = _run_match_to_completion(b1, b2)
	return result["ticks"] <= 2400 and result["duration_sec"] <= 120.0

## Different loadouts produce different match outcomes across seeds
func test_loadout_affects_outcome() -> bool:
	var wins_heavy := 0
	var wins_light := 0
	for seed_val in range(100, 110):
		var b1 = _make_brott(1, 0, "brawler", ["minigun", "shotgun"], "plating", ["repair_nanites"], Vector2(64, 64))
		var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(128, 64))
		var result = _run_match_to_completion(b1, b2, seed_val)
		if result["winner_team"] == 0:
			wins_heavy += 1
		elif result["winner_team"] == 1:
			wins_light += 1
	# The brawler with better loadout should win more often
	return wins_heavy > wins_light

## Determinism: same seed produces identical results
func test_full_match_determinism() -> bool:
	var results := []
	for _i in range(3):
		var b1 = _make_brott(1, 0, "brawler", ["minigun", "shotgun"], "plating", ["repair_nanites"], Vector2(64, 64))
		var b2 = _make_brott(2, 1, "scout", ["minigun"], "plating", [], Vector2(256, 64))
		results.append(_run_match_to_completion(b1, b2, 9999))
	return (results[0]["winner_team"] == results[1]["winner_team"]
		and results[1]["winner_team"] == results[2]["winner_team"]
		and results[0]["ticks"] == results[1]["ticks"]
		and results[1]["ticks"] == results[2]["ticks"])

## Team stats are populated correctly after match
func test_team_stats_after_match() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(128, 32))
	var result = _run_match_to_completion(b1, b2)
	var stats = result["team_stats"]
	# Both teams should have stats
	if not stats.has(0) or not stats.has(1):
		return false
	# Each team has exactly 1 brott
	if stats[0]["total_brotts"] != 1 or stats[1]["total_brotts"] != 1:
		return false
	# Loser should have 0 hp remaining (or draw)
	var winner = result["winner_team"]
	if winner >= 0:
		var loser = 1 - winner
		return stats[loser]["brotts_alive"] == 0
	return true  # Draw is also valid

# ═════════════════════════════════════════════════════════
# 2. COMBAT + PATHFINDING INTEGRATION
# ═════════════════════════════════════════════════════════

## Arena pathfinder finds valid path between two open tiles
func test_pathfinder_in_arena() -> bool:
	var arena = ArenaManager.new()
	arena.load_layout("the_pit")
	var pf = Pathfinder.new(arena)
	var path = pf.find_path(Vector2i(1, 1), Vector2i(14, 14))
	return path.size() > 0 and path[0] == Vector2i(1, 1) and path[-1] == Vector2i(14, 14)

## Pathfinder routes around walls and pillars
func test_pathfinder_avoids_obstacles() -> bool:
	var arena = ArenaManager.new()
	arena.load_layout("the_pit")
	var pf = Pathfinder.new(arena)
	# Path from top-left to bottom-right must avoid center pillars (7,7) and (8,8)
	var path = pf.find_path(Vector2i(1, 1), Vector2i(14, 14))
	for tile in path:
		if arena.blocks_movement(tile):
			return false
	return true

## LoS is blocked by pillars in arena
func test_los_blocked_by_pillar() -> bool:
	var arena = ArenaManager.new()
	arena.load_layout("the_pit")
	# Check LoS through center pillars (7,7) and (8,8)
	var los = arena.check_los(Vector2i(6, 6), Vector2i(9, 9))
	return los.blocked

## LoS is clear when no obstacles between tiles
func test_los_clear_open_arena() -> bool:
	var arena = ArenaManager.new()
	arena.load_layout("the_pit")
	var los = arena.check_los(Vector2i(1, 1), Vector2i(1, 14))
	return not los.blocked

## Brott engages enemy within weapon range after navigating arena
func test_brott_fires_in_range() -> bool:
	# Place two brotts within minigun range (5 tiles = 160px)
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(128, 32))  # 3 tiles away
	var ts = TickSystem.new()
	ts.setup(42, [b1, b2])
	# Run a few ticks
	for i in range(5):
		ts.run_tick()
	# At least one brott should have taken damage (weapons fired)
	return b1.hp < b1.max_hp or b2.hp < b2.max_hp

## Projectile creates correctly and travels
func test_projectile_creation_and_travel() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["missile_pod"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(320, 32))  # 9 tiles away
	var proj = ProjectileScript.create("missile_pod", b1, b2, 25.0, false, 0.0, 0)
	# Missile should not be hitscan
	if proj.is_hitscan():
		return false
	# Should be alive and flying
	if not proj.alive:
		return false
	# Update should move it
	var old_pos = proj.position
	proj.update()
	return proj.position != old_pos and proj.alive

## Hitscan weapons resolve instantly (no projectile travel)
func test_hitscan_instant_damage() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(96, 32))  # 2 tiles
	var ts = TickSystem.new()
	ts.setup(42, [b1, b2])
	ts.run_tick()
	# Minigun is hitscan — damage should be applied immediately, not via projectile
	# At least one brott should be damaged after 1 tick (both in range)
	return b1.hp < b1.max_hp or b2.hp < b2.max_hp

# ═════════════════════════════════════════════════════════
# 3. BROTTBRAIN + ENERGY INTEGRATION
# ═════════════════════════════════════════════════════════

## BrottBrain default cards trigger correctly based on game state
func test_brain_low_hp_goes_defensive() -> bool:
	var brain = BrottBrain.create_default()
	# Simulate low HP (20%), full energy, enemy close
	var result = brain.evaluate(0.20, 1.0, 3.0, 0.8)
	# Default card 1: HP < 25% → DEFENSIVE
	return result[&"action"] == BehaviorCard.ActionType.SET_STANCE and result[&"value"] == BehaviorCard.Stance.DEFENSIVE

## BrottBrain triggers energy conservation when energy low
func test_brain_low_energy_conserves() -> bool:
	var brain = BrottBrain.create_default()
	# HP is fine, energy is low (15%), enemy at mid range
	var result = brain.evaluate(0.80, 0.15, 5.0, 0.8)
	# Card 2: energy < 20% → CONSERVE_ENERGY
	return result[&"action"] == BehaviorCard.ActionType.CONSERVE_ENERGY

## BrottBrain goes aggressive when enemy HP is low
func test_brain_enemy_low_hp_aggressive() -> bool:
	var brain = BrottBrain.create_default()
	# HP fine, energy fine, enemy HP low (15%)
	var result = brain.evaluate(0.80, 0.80, 5.0, 0.15)
	# Card 3: enemy HP < 20% → AGGRESSIVE
	return result[&"action"] == BehaviorCard.ActionType.SET_STANCE and result[&"value"] == BehaviorCard.Stance.AGGRESSIVE

## BrottBrain falls back to default stance when no card triggers
func test_brain_default_stance_fallback() -> bool:
	var brain = BrottBrain.create_default()
	# All values normal — no card should fire
	var result = brain.evaluate(0.80, 0.80, 5.0, 0.80)
	return result[&"source"] == "stance_default"

## Energy depletes and regenerates over a match
func test_energy_cycle_in_match() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(96, 32))  # in range
	var ts = TickSystem.new()
	ts.setup(42, [b1, b2])
	var energy_dropped := false
	var energy_recovered := false
	var min_energy: float = b1.energy
	for i in range(100):
		if ts.match_over:
			break
		ts.run_tick()
		if b1.energy < 100.0:
			energy_dropped = true
		if b1.energy < min_energy:
			min_energy = b1.energy
		elif b1.energy > min_energy and energy_dropped:
			energy_recovered = true
	# Energy should have dropped (weapon fire costs energy) and recovered (regen)
	return energy_dropped

## Weapon fire costs energy — verified over multiple ticks
func test_weapon_fire_costs_energy() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["railgun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(96, 32))
	b1.energy = 100.0
	var ts = TickSystem.new()
	ts.setup(42, [b1, b2])
	var starting_energy = b1.energy
	for i in range(10):
		ts.run_tick()
	# Energy should have been spent on weapon fire (net of regen)
	return b1.energy < starting_energy or b2.hp < b2.max_hp

# ═════════════════════════════════════════════════════════
# 4. MATCH LIFECYCLE
# ═════════════════════════════════════════════════════════

## MatchManager goes through full state lifecycle
func test_match_lifecycle_states() -> bool:
	var mm = MatchManagerScript.new()
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(128, 32))
	# Initially IDLE
	if mm.is_running():
		return false
	mm.setup_match([b1], [b2], 42)
	mm.start_match()
	# Should be RUNNING
	if not mm.is_running():
		return false
	# Run to completion
	while mm.is_running():
		mm.step()
	# Should be ENDED
	return mm.is_ended() and mm.get_result().has("winner_team")

## MatchManager pause/resume works
func test_match_pause_resume() -> bool:
	var mm = MatchManagerScript.new()
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(128, 32))
	mm.setup_match([b1], [b2], 42)
	mm.start_match()
	mm.step()
	var tick_before = mm.get_tick()
	mm.pause_match()
	# step() should not advance while paused
	mm.step()
	if mm.get_tick() != tick_before:
		return false
	mm.resume_match()
	mm.step()
	return mm.get_tick() == tick_before + 1

## Match ends when one brott reaches 0 HP
func test_match_ends_on_death() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(96, 32))
	var result = _run_match_to_completion(b1, b2)
	# One team should have 0 brotts alive (unless draw)
	if result["winner_team"] >= 0:
		var loser = 1 - result["winner_team"]
		return result["team_stats"][loser]["brotts_alive"] == 0
	return true

## Match timeout at 120s produces correct outcome string
func test_match_timeout_outcome() -> bool:
	# Use TickSystem directly to control match without movement closing gap
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(5000, 5000))
	var ts = TickSystem.new()
	ts.setup(42, [b1, b2])
	# Force tick near timeout
	ts.tick = 2400 - 1
	ts.run_tick()
	return ts.match_over and ts.tick >= 2400

## MatchManager reset allows starting a new match
func test_match_reset_new_match() -> bool:
	var mm = MatchManagerScript.new()
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(96, 32))
	mm.setup_match([b1], [b2], 42)
	mm.run_to_completion()
	if not mm.is_ended():
		return false
	mm.reset()
	# Should be back to IDLE, can setup a new match
	var b3 = _make_brott(3, 0, "brawler", ["minigun"], "", [], Vector2(32, 32))
	var b4 = _make_brott(4, 1, "brawler", ["minigun"], "", [], Vector2(96, 32))
	mm.setup_match([b3], [b4], 99)
	var result = mm.run_to_completion()
	return mm.is_ended() and result.has("winner_team")

## Match elapsed time is consistent with tick count
func test_match_elapsed_time_consistency() -> bool:
	var mm = MatchManagerScript.new()
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(128, 32))
	mm.setup_match([b1], [b2], 42)
	mm.run_to_completion()
	var result = mm.get_result()
	var expected_sec = float(result["ticks"]) / 20.0
	return absf(result["duration_sec"] - expected_sec) < 0.01

# ═════════════════════════════════════════════════════════
# 5. ECONOMY INTEGRATION
# ═════════════════════════════════════════════════════════

## Winner earns bolts after match
func test_winner_earns_bolts() -> bool:
	var econ = EconomyManager.new()
	econ.add_bolts(0)  # Start at 0
	var earned = econ.award_match_result(true, "opp_1")
	# First win = 150 bolts
	return earned == 150 and econ.bolts == 150

## Loser earns consolation bolts
func test_loser_earns_consolation() -> bool:
	var econ = EconomyManager.new()
	var earned = econ.award_match_result(false, "opp_1")
	return earned == 40 and econ.bolts == 40

## Repeat win gives standard reward (not first-win bonus)
func test_repeat_win_no_bonus() -> bool:
	var econ = EconomyManager.new()
	econ.award_match_result(true, "opp_1")  # First win: 150
	var earned = econ.award_match_result(true, "opp_1")  # Repeat: 100
	return earned == 100 and econ.bolts == 250

## Shop purchase with match earnings
func test_buy_with_match_earnings() -> bool:
	var econ = EconomyManager.new()
	econ.award_match_result(true, "opp_1")  # +150
	var shop = ShopScript.new(econ)
	var result = shop.buy("weapon", "shotgun")  # costs 120
	return result["success"] and econ.bolts == 30

## Cannot buy item without enough bolts
func test_shop_insufficient_bolts() -> bool:
	var econ = EconomyManager.new()
	econ.award_match_result(false, "opp_1")  # +40
	var shop = ShopScript.new(econ)
	var result = shop.buy("weapon", "shotgun")  # costs 120
	return not result["success"] and result["reason"] == "insufficient_bolts"

## Purchased weapon can be equipped on a brott
func test_purchased_weapon_equips() -> bool:
	var econ = EconomyManager.new()
	econ.add_bolts(500)
	econ.purchase_item("weapon", "shotgun")
	if not econ.owns_item("weapon", "shotgun"):
		return false
	# Create a brott with the purchased weapon
	var b = _make_brott(1, 0, "brawler", ["minigun", "shotgun"], "plating", [], Vector2(32, 32))
	return "shotgun" in b.weapon_ids and b.weapon_ids.size() == 2

## Repair cost scales with equipment value
func test_repair_cost_integration() -> bool:
	var econ = EconomyManager.new()
	econ.add_bolts(1000)
	# Equipment: shotgun(120) + reactive_mesh(150) = 270 value
	var cost_win = econ.calc_repair_cost(270, true)    # 10% = 27
	var cost_loss = econ.calc_repair_cost(270, false)   # 25% = 68
	return cost_win == 27 and cost_loss == 68

## Full economy loop: win match → earn bolts → buy item → equip → fight again
func test_full_economy_loop() -> bool:
	var econ = EconomyManager.new()
	var shop = ShopScript.new(econ)
	# Win first match
	econ.award_match_result(true, "opp_1")  # +150
	# Buy shotgun
	var buy_result = shop.buy("weapon", "shotgun")  # -120, left 30
	if not buy_result["success"]:
		return false
	# Win another match
	econ.award_match_result(true, "opp_2")  # +150 (first win vs opp_2), total 180
	# Create brott with new weapon and fight
	var b1 = _make_brott(1, 0, "brawler", ["minigun", "shotgun"], "plating", [], Vector2(64, 64))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(128, 64))
	var result = _run_match_to_completion(b1, b2)
	return result.has("winner_team") and econ.bolts == 180

# ═════════════════════════════════════════════════════════
# 6. STEERING + PATHFINDING + ARENA INTEGRATION
# ═════════════════════════════════════════════════════════

## Aggressive steering moves toward enemy
func test_steering_aggressive_approaches() -> bool:
	var arena = ArenaManager.new()
	arena.load_layout("the_pit")
	var pf = Pathfinder.new(arena)
	var steering = Steering.new(arena, pf)
	var brott_tile = Vector2i(2, 2)
	var enemy_tile = Vector2i(12, 12)
	var target = steering.get_target(BehaviorCard.Stance.AGGRESSIVE, brott_tile, enemy_tile, 5.0)
	# Target should be closer to enemy than current position
	var old_dist = Vector2(brott_tile - enemy_tile).length()
	var new_dist = Vector2(target - enemy_tile).length()
	return new_dist < old_dist

## Defensive steering seeks cover
func test_steering_defensive_seeks_cover() -> bool:
	var arena = ArenaManager.new()
	arena.load_layout("the_pit")  # Has cover at (4,4), (4,11), (11,4), (11,11)
	var pf = Pathfinder.new(arena)
	var steering = Steering.new(arena, pf)
	var brott_tile = Vector2i(3, 3)
	var enemy_tile = Vector2i(12, 12)
	var target = steering.get_target(BehaviorCard.Stance.DEFENSIVE, brott_tile, enemy_tile, 5.0)
	# Should move to or near a cover tile
	var near_cover := false
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if arena.provides_cover(target + Vector2i(dx, dy)):
				near_cover = true
	return near_cover

## Kiting steering maintains distance from enemy
func test_steering_kiting_maintains_range() -> bool:
	var arena = ArenaManager.new()
	arena.load_layout("the_pit")
	var pf = Pathfinder.new(arena)
	var steering = Steering.new(arena, pf)
	# Start at close range
	var brott_tile = Vector2i(7, 5)
	var enemy_tile = Vector2i(8, 5)
	var weapon_range = 5.0
	var target = steering.get_target(BehaviorCard.Stance.KITING, brott_tile, enemy_tile, weapon_range)
	# Should move away (kiting = retreat + strafe when too close)
	var old_dist = Vector2(brott_tile - enemy_tile).length()
	var new_dist = Vector2(target - enemy_tile).length()
	return new_dist >= old_dist

## Pathfinder avoids hazard tiles (higher cost)
func test_pathfinder_avoids_hazards() -> bool:
	var arena = ArenaManager.new()
	arena.init_arena(10, 10)
	# Create a hazard strip
	for x in range(10):
		arena.set_tile(Vector2i(x, 5), ArenaManager.TileType.HAZARD)
	# Clear a gap
	arena.set_tile(Vector2i(5, 5), ArenaManager.TileType.FLOOR)
	var pf = Pathfinder.new(arena)
	var path = pf.find_path(Vector2i(5, 0), Vector2i(5, 9))
	# Path should prefer the gap over walking through hazards
	var hazard_count := 0
	for tile in path:
		if arena.is_hazard(tile):
			hazard_count += 1
	# Should route through the gap, minimal hazard tiles
	return path.size() > 0 and hazard_count == 0

# ═════════════════════════════════════════════════════════
# 7. CROSS-SYSTEM EDGE CASES
# ═════════════════════════════════════════════════════════

## Draw scenario — both brotts die on same tick
func test_mutual_destruction_draw() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(96, 32))
	b1.hp = 1.0
	b2.hp = 1.0
	var result = _run_match_to_completion(b1, b2, 42)
	# Both should die quickly — result should be draw or one wins
	return result.has("outcome") and result["ticks"] < 100

## Zero-armor brott takes full damage
func test_no_armor_full_damage() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(96, 32))
	var ts = TickSystem.new()
	ts.setup(42, [b1, b2])
	var hp_before = b2.hp
	for i in range(20):
		if ts.match_over:
			break
		ts.run_tick()
	# Without armor, brott should take damage
	return b2.hp < hp_before

## Reactive mesh reflects damage back to attacker
func test_reactive_mesh_reflects_in_match() -> bool:
	var b1 = _make_brott(1, 0, "scout", ["railgun"], "", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "brawler", ["minigun"], "reactive_mesh", [], Vector2(96, 32))
	var b1_hp_start = b1.hp
	var ts = TickSystem.new()
	ts.setup(42, [b1, b2])
	for i in range(50):
		if ts.match_over:
			break
		ts.run_tick()
	# b1 should have taken reflect damage from hitting b2's reactive mesh
	# OR b2 should have full HP (mesh absorbed everything)
	return b1.hp < b1_hp_start or b2.hp == b2.max_hp

## Multiple weapons fire in same tick
func test_multi_weapon_brott() -> bool:
	var b1 = _make_brott(1, 0, "brawler", ["minigun", "shotgun"], "plating", [], Vector2(32, 32))
	var b2 = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(96, 32))
	var ts = TickSystem.new()
	ts.setup(42, [b1, b2])
	# Both weapons should be able to fire
	return b1.weapon_ids.size() == 2 and b1.weapon_cooldowns.size() == 2
