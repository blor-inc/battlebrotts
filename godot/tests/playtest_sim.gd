# playtest_sim.gd — Headless combat simulation for balance testing
# BattleBrotts Sprint 6 · Track D
#
# Runs 1000+ matches with various loadout combinations.
# Outputs JSON results for analysis.
extends SceneTree

# Preload all game scripts
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
var _g19 = preload("res://game/campaign/campaign_controller.gd")
var _g20 = preload("res://game/ui/shop_screen.gd")
var _g21 = preload("res://game/ui/opponent_select.gd")

const CHASSIS_IDS := ["scout", "brawler", "fortress"]
const WEAPON_IDS := ["minigun", "plasma_cutter", "shotgun", "arc_emitter", "flak_cannon", "railgun", "missile_pod"]
const ARMOR_IDS := ["", "plating", "reactive_mesh", "ablative_shell"]

var results: Array = []
var rng := RandomNumberGenerator.new()

const MatchManagerScript = preload("res://game/autoloads/match_manager.gd")
const ArenaManagerScript = preload("res://game/arena/arena_manager.gd")
const BrottScript = preload("res://game/entities/brott.gd")
const CampaignScript = preload("res://game/campaign/campaign_controller.gd")

func _init() -> void:
	rng.randomize()
	print('{"event": "start", "message": "Starting playtest simulation..."}')

	# ── Test 1: Chassis balance (each chassis vs each chassis, 100 matches each) ──
	print('{"event": "phase", "phase": "chassis_balance"}')
	var chassis_wins := {}
	for c in CHASSIS_IDS:
		chassis_wins[c] = 0
	var chassis_total := 0

	for c1 in CHASSIS_IDS:
		for c2 in CHASSIS_IDS:
			for i in range(50):
				var result := _run_match(
					c1, ["minigun"], "plating", [],
					c2, ["minigun"], "plating", [],
					rng.randi()
				)
				if result["winner_team"] == 0:
					chassis_wins[c1] += 1
				elif result["winner_team"] == 1:
					chassis_wins[c2] += 1
				chassis_total += 1

	# ── Test 2: Weapon balance (each weapon 1v1, 50 matches each) ──
	print('{"event": "phase", "phase": "weapon_balance"}')
	var weapon_wins := {}
	for w in WEAPON_IDS:
		weapon_wins[w] = 0
	var weapon_total := 0

	for w1 in WEAPON_IDS:
		for w2 in WEAPON_IDS:
			for i in range(20):
				var result := _run_match(
					"brawler", [w1], "plating", [],
					"brawler", [w2], "plating", [],
					rng.randi()
				)
				if result["winner_team"] == 0:
					weapon_wins[w1] += 1
				elif result["winner_team"] == 1:
					weapon_wins[w2] += 1
				weapon_total += 1

	# ── Test 3: Scrapyard campaign simulation (100 runs) ──
	print('{"event": "phase", "phase": "economy_flow"}')
	var economy_data := []
	for i in range(100):
		var run_data := _simulate_campaign_run()
		economy_data.append(run_data)

	# ── Test 4: TTK analysis ──
	print('{"event": "phase", "phase": "ttk_analysis"}')
	var ttk_data := []
	for w in WEAPON_IDS:
		var ttk_sum := 0.0
		var ttk_count := 0
		for i in range(30):
			var result := _run_match(
				"brawler", [w], "", [],
				"brawler", [w], "", [],
				rng.randi()
			)
			if result.has("duration_sec"):
				ttk_sum += result["duration_sec"]
				ttk_count += 1
		if ttk_count > 0:
			ttk_data.append({"weapon": w, "avg_ttk": ttk_sum / ttk_count, "samples": ttk_count})

	# ── Output results ──
	var output := {
		"chassis_balance": {
			"wins": chassis_wins,
			"total_matches": chassis_total,
		},
		"weapon_balance": {
			"wins": weapon_wins,
			"total_matches": weapon_total,
		},
		"economy_flow": economy_data,
		"ttk_analysis": ttk_data,
		"total_simulations": chassis_total + weapon_total + 100 + 30 * WEAPON_IDS.size(),
	}

	# Print as JSON lines
	print('PLAYTEST_RESULTS_START')
	print(JSON.stringify(output))
	print('PLAYTEST_RESULTS_END')

	quit(0)


func _run_match(
	c1: String, w1: Array, a1: String, m1: Array,
	c2: String, w2: Array, a2: String, m2: Array,
	seed_val: int
) -> Dictionary:
	var mm = MatchManagerScript.new()
	var arena = ArenaManagerScript.new()
	arena.load_layout("the_pit")

	var brott_a = BrottScript.create(0, 0, c1, w1, a1, m1, Vector2(2 * 32, 8 * 32))
	var brott_b = BrottScript.create(1, 1, c2, w2, a2, m2, Vector2(13 * 32, 8 * 32))

	mm.setup_match([brott_a], [brott_b], seed_val)
	mm.start_match()

	while mm.is_running():
		mm.step()

	return mm.match_result


func _simulate_campaign_run() -> Dictionary:
	var campaign = CampaignScript.new()
	campaign.new_game()

	var matches_played := 0
	var bolts_history := [campaign.get_bolts()]
	var items_bought := 0

	# Play through scrapyard
	for opp_idx in range(3):
		# Try to buy something if we can afford it
		var purchasable = campaign.shop.get_purchasable("weapon")
		for item in purchasable:
			if campaign.economy.can_afford(item["cost"]) and item["cost"] > 0:
				campaign.buy_item("weapon", item["id"])
				items_bought += 1
				break

		# Fight until we beat this opponent (max 10 attempts)
		var attempts := 0
		while not campaign.has_beaten_opponent(opp_idx) and attempts < 10:
			campaign.start_match(opp_idx)
			campaign._process_match_rewards()
			matches_played += 1
			attempts += 1
			bolts_history.append(campaign.get_bolts())

	return {
		"matches_played": matches_played,
		"items_bought": items_bought,
		"final_bolts": campaign.get_bolts(),
		"league_beaten": campaign.league.is_league_beaten("scrapyard"),
		"bolts_history": bolts_history,
	}
