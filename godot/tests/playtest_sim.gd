# playtest_sim.gd — Headless combat simulation for balance testing
# BattleBrotts Sprint 7 · Optic (Playtest Lead)
#
# Runs 1500+ matches with varied loadouts across arenas.
# Outputs JSON results for analysis.
extends SceneTree

# Preload all game scripts for class_name registration
var _g01 = preload("res://game/data/armor_data.gd")
var _g02 = preload("res://game/data/chassis_data.gd")
var _g03 = preload("res://game/data/weapon_data.gd")
var _g04 = preload("res://game/data/module_data.gd")
var _g05 = preload("res://game/entities/brott.gd")
var _g06 = preload("res://game/combat/damage_calculator.gd")
var _g07 = preload("res://game/combat/tick_system.gd")
var _g08 = preload("res://game/arena/arena_manager.gd")
var _g09 = preload("res://game/arena/pathfinder.gd")
var _g10 = preload("res://game/ai/behavior_card.gd")
var _g11 = preload("res://game/ai/brottbrain.gd")
var _g12 = preload("res://game/ai/steering.gd")
var _g13 = preload("res://game/autoloads/match_manager.gd")
var _g14 = preload("res://game/combat/projectile.gd")
var _g15 = preload("res://game/ui/game_controller.gd")
var _g16 = preload("res://game/economy/economy_manager.gd")
var _g17 = preload("res://game/economy/shop.gd")
var _g18 = preload("res://game/progression/league_manager.gd")

const MatchManagerScript = preload("res://game/autoloads/match_manager.gd")
const ArenaManagerScript = preload("res://game/arena/arena_manager.gd")
const BrottScript = preload("res://game/entities/brott.gd")
const EconScript = preload("res://game/economy/economy_manager.gd")

const CHASSIS := ["scout", "brawler", "fortress"]
const WEAPONS := ["minigun", "plasma_cutter", "shotgun", "arc_emitter", "flak_cannon", "railgun", "missile_pod"]
const ARMORS := ["", "plating", "reactive_mesh", "ablative_shell"]
const ARENAS := ["the_pit", "junkyard"]

var rng := RandomNumberGenerator.new()
var all_results: Array = []

func _init() -> void:
	rng.randomize()

	# ── Phase 1: Chassis balance (mirror matchups, 100 per pair) ──
	for c1_idx in range(CHASSIS.size()):
		for c2_idx in range(c1_idx, CHASSIS.size()):
			for i in range(100):
				var r = _run(CHASSIS[c1_idx], ["minigun"], "plating", [],
							 CHASSIS[c2_idx], ["minigun"], "plating", [],
							 "the_pit", rng.randi())
				all_results.append(r)

	# ── Phase 2: Weapon balance (all pairs on brawler, 30 per pair) ──
	for w1_idx in range(WEAPONS.size()):
		for w2_idx in range(w1_idx, WEAPONS.size()):
			for i in range(30):
				var r = _run("brawler", [WEAPONS[w1_idx]], "plating", [],
							 "brawler", [WEAPONS[w2_idx]], "plating", [],
							 "the_pit", rng.randi())
				all_results.append(r)

	# ── Phase 3: Arena comparison (same matchups on both arenas) ──
	var arena_matchups := [
		["scout", ["minigun"], "plating", [], "brawler", ["minigun"], "plating", []],
		["brawler", ["shotgun"], "reactive_mesh", [], "fortress", ["railgun"], "ablative_shell", []],
		["scout", ["railgun"], "", [], "scout", ["minigun"], "plating", ["repair_nanites"]],
	]
	for matchup in arena_matchups:
		for arena_name in ARENAS:
			for i in range(50):
				var r = _run(matchup[0], matchup[1], matchup[2], matchup[3],
							 matchup[4], matchup[5], matchup[6], matchup[7],
							 arena_name, rng.randi())
				all_results.append(r)

	# ── Phase 4: Diverse random matchups (stress test) ──
	for i in range(200):
		var c1 = CHASSIS[rng.randi() % CHASSIS.size()]
		var c2 = CHASSIS[rng.randi() % CHASSIS.size()]
		var w1 = [WEAPONS[rng.randi() % WEAPONS.size()]]
		var w2 = [WEAPONS[rng.randi() % WEAPONS.size()]]
		var a1 = ARMORS[rng.randi() % ARMORS.size()]
		var a2 = ARMORS[rng.randi() % ARMORS.size()]
		var arena_name = ARENAS[rng.randi() % ARENAS.size()]
		var r = _run(c1, w1, a1, [], c2, w2, a2, [], arena_name, rng.randi())
		all_results.append(r)

	# ── Output ──
	print("PLAYTEST_RESULTS_START")
	print(JSON.stringify(all_results))
	print("PLAYTEST_RESULTS_END")
	quit(0)


func _run(c1: String, w1: Array, a1: String, m1: Array,
		  c2: String, w2: Array, a2: String, m2: Array,
		  arena_name: String, seed_val: int) -> Dictionary:
	var mm = MatchManagerScript.new()
	var b1 = BrottScript.create(0, 0, c1, w1, a1, m1, Vector2(2 * 32, 8 * 32))
	var b2 = BrottScript.create(1, 1, c2, w2, a2, m2, Vector2(13 * 32, 8 * 32))
	mm.setup_match([b1], [b2], seed_val)
	mm.start_match()
	while mm.is_running():
		mm.step()
	var res = mm.match_result
	res["team_a"] = {"chassis": c1, "weapons": w1, "armor": a1, "modules": m1}
	res["team_b"] = {"chassis": c2, "weapons": w2, "armor": a2, "modules": m2}
	res["arena"] = arena_name
	res["hp_a"] = b1.hp
	res["hp_b"] = b2.hp
	return res
