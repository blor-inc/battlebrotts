# test_game_controller.gd — Tests for GameController (vertical slice)
# BattleBrotts Sprint 4 · S4-001
extends Node

var tests_passed: int = 0
var tests_failed: int = 0
var test_name: String = ""


func run_all() -> Dictionary:
	tests_passed = 0
	tests_failed = 0

	test_initial_state()
	test_available_data()
	test_loadout_validation_no_weapon()
	test_loadout_validation_overweight()
	test_loadout_validation_too_many_weapons()
	test_loadout_validation_too_many_modules()
	test_loadout_validation_valid_default()
	test_weight_calculation()
	test_start_match_creates_brotts()
	test_step_simulation()
	test_run_full_simulation()
	test_match_result_structure()
	test_restart_resets_state()
	test_enemy_loadout_constants()
	test_screen_transitions()

	return {"passed": tests_passed, "failed": tests_failed, "total": tests_passed + tests_failed}


func assert_eq(a, b, msg: String = "") -> void:
	if a == b:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  FAIL [%s]: expected %s == %s %s" % [test_name, str(a), str(b), msg])


func assert_true(cond: bool, msg: String = "") -> void:
	if cond:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  FAIL [%s]: expected true %s" % [test_name, msg])


func assert_false(cond: bool, msg: String = "") -> void:
	assert_true(not cond, msg)


func test_initial_state() -> void:
	test_name = "initial_state"
	var gc := GameController.new()
	assert_eq(gc.current_screen, GameController.Screen.LOADOUT)
	assert_eq(gc.player_chassis, "brawler")
	assert_eq(gc.player_weapons, ["minigun"])
	assert_eq(gc.player_armor, "plating")
	assert_eq(gc.player_modules, [])
	assert_eq(gc.sim_complete, false)
	assert_eq(gc.sim_ticks.size(), 0)


func test_available_data() -> void:
	test_name = "available_data"
	var gc := GameController.new()
	assert_true(gc.get_available_chassis().size() >= 3, "at least 3 chassis")
	assert_true(gc.get_available_weapons().size() >= 7, "at least 7 weapons")
	assert_true(gc.get_available_armor().size() >= 3, "at least 3 armor")
	assert_true(gc.get_available_modules().size() >= 6, "at least 6 modules")


func test_loadout_validation_no_weapon() -> void:
	test_name = "validation_no_weapon"
	var gc := GameController.new()
	gc.player_weapons = []
	var v := gc.validate_loadout()
	assert_false(v["valid"], "should be invalid with no weapons")
	assert_true(v["errors"].size() > 0)


func test_loadout_validation_overweight() -> void:
	test_name = "validation_overweight"
	var gc := GameController.new()
	gc.player_chassis = "scout"  # weight cap 30
	gc.player_weapons = ["railgun"]  # weight 15
	gc.player_armor = "ablative_shell"  # weight 25
	# total = 40 > 30
	var v := gc.validate_loadout()
	assert_false(v["valid"], "should be invalid when overweight")


func test_loadout_validation_too_many_weapons() -> void:
	test_name = "validation_too_many_weapons"
	var gc := GameController.new()
	gc.player_chassis = "scout"  # 1 weapon slot
	gc.player_weapons = ["minigun", "shotgun"]
	gc.player_armor = ""
	var v := gc.validate_loadout()
	assert_false(v["valid"], "scout can only have 1 weapon")


func test_loadout_validation_too_many_modules() -> void:
	test_name = "validation_too_many_modules"
	var gc := GameController.new()
	gc.player_chassis = "fortress"  # 1 module slot
	gc.player_modules = ["overclock", "repair_nanites"]
	var v := gc.validate_loadout()
	assert_false(v["valid"], "fortress can only have 1 module")


func test_loadout_validation_valid_default() -> void:
	test_name = "validation_valid_default"
	var gc := GameController.new()
	# Default: brawler + minigun + plating
	var v := gc.validate_loadout()
	assert_true(v["valid"], "default loadout should be valid")
	assert_eq(v["errors"].size(), 0)


func test_weight_calculation() -> void:
	test_name = "weight_calculation"
	var gc := GameController.new()
	gc.player_chassis = "brawler"
	gc.player_weapons = ["minigun"]  # 10
	gc.player_armor = "plating"  # 15
	gc.player_modules = ["overclock"]  # 5
	assert_eq(gc.get_weight_used(), 30.0, "10 + 15 + 5 = 30")
	assert_eq(gc.get_weight_cap(), 55.0, "brawler cap = 55")


func test_start_match_creates_brotts() -> void:
	test_name = "start_match_creates_brotts"
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	assert_true(gc.player_brott != null, "player brott created")
	assert_true(gc.enemy_brott != null, "enemy brott created")
	assert_eq(gc.player_brott.team, 0)
	assert_eq(gc.enemy_brott.team, 1)
	assert_eq(gc.player_brott.chassis_id, "brawler")
	assert_eq(gc.enemy_brott.chassis_id, "brawler")


func test_step_simulation() -> void:
	test_name = "step_simulation"
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	var result := gc.step_simulation()
	assert_true(result, "first tick should continue")
	assert_eq(gc.sim_ticks.size(), 1)
	assert_true(gc.sim_ticks[0].has("tick"))
	assert_true(gc.sim_ticks[0].has("player"))
	assert_true(gc.sim_ticks[0].has("enemy"))


func test_run_full_simulation() -> void:
	test_name = "run_full_simulation"
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	var result := gc.run_full_simulation()
	assert_true(gc.sim_complete, "sim should be complete")
	assert_true(gc.sim_ticks.size() > 0, "should have tick snapshots")
	assert_true(result.has("outcome"), "result should have outcome")
	assert_true(result.has("winner_team"), "result should have winner_team")


func test_match_result_structure() -> void:
	test_name = "match_result_structure"
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	var r := gc.match_result
	assert_true(r.has("outcome"))
	assert_true(r.has("winner_team"))
	assert_true(r.has("ticks"))
	assert_true(r.has("duration_sec"))
	assert_true(r.has("team_stats"))
	assert_true(r.has("seed"))
	assert_true(r["ticks"] > 0, "match should last at least 1 tick")
	assert_true(r["duration_sec"] > 0.0)
	# Outcome should be one of the valid outcomes
	var valid_outcomes := ["team_a_wins", "team_b_wins", "draw",
		"timeout_draw", "timeout_team_a_advantage", "timeout_team_b_advantage"]
	assert_true(valid_outcomes.has(r["outcome"]), "valid outcome: " + r["outcome"])


func test_restart_resets_state() -> void:
	test_name = "restart_resets_state"
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	gc.restart()
	assert_eq(gc.current_screen, GameController.Screen.LOADOUT)
	assert_eq(gc.sim_ticks.size(), 0)
	assert_eq(gc.sim_complete, false)
	assert_true(gc.player_brott == null)
	assert_true(gc.enemy_brott == null)
	assert_eq(gc.match_result, {})


func test_enemy_loadout_constants() -> void:
	test_name = "enemy_loadout_constants"
	assert_eq(GameController.ENEMY_CHASSIS, "brawler")
	assert_eq(GameController.ENEMY_WEAPONS, ["shotgun", "missile_pod"])
	assert_eq(GameController.ENEMY_ARMOR, "reactive_mesh")
	assert_eq(GameController.ENEMY_MODULES, ["repair_nanites"])


func test_screen_transitions() -> void:
	test_name = "screen_transitions"
	var gc := GameController.new()
	gc._ready()
	assert_eq(gc.current_screen, GameController.Screen.LOADOUT)
	gc.start_match()
	assert_eq(gc.current_screen, GameController.Screen.MATCH)
	gc.run_full_simulation()
	assert_eq(gc.current_screen, GameController.Screen.RESULT)
	gc.restart()
	assert_eq(gc.current_screen, GameController.Screen.LOADOUT)
