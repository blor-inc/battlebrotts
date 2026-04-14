# test_runner.gd — Headless test runner for BattleBrotts
# Run: godot --headless --path godot/ --script res://tests/test_runner.gd
extends SceneTree

# Preload all game scripts to register class_names
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

var _pass_count: int = 0
var _fail_count: int = 0
var _errors: Array = []

func _init() -> void:
	_run_all_tests()
	_print_summary()
	if _fail_count > 0:
		quit(1)
	else:
		quit(0)

func _run_all_tests() -> void:
	print("\n═══════════════════════════════════════")
	print("  BattleBrotts Test Suite")
	print("═══════════════════════════════════════\n")

	_run_suite("DamageCalculator", preload("res://tests/test_damage_calculator.gd"))
	_run_suite("Brott", preload("res://tests/test_brott.gd"))
	_run_suite("DataValidation", preload("res://tests/test_data_validation.gd"))
	_run_suite("Arena", preload("res://tests/test_arena.gd"))
	_run_suite("Pathfinder", preload("res://tests/test_pathfinder.gd"))
	_run_suite("BrottBrain", preload("res://tests/test_brottbrain.gd"))
	_run_suite("Steering", preload("res://tests/test_steering.gd"))
	_run_suite("TickSystem", preload("res://tests/test_tick_system.gd"))
	_run_suite("MatchManager", preload("res://tests/test_match_manager.gd"))
	_run_suite("Projectile", preload("res://tests/test_projectile.gd"))
	_run_suite("GameController", preload("res://tests/test_game_controller.gd"))

func _run_suite(suite_name: String, script: GDScript) -> void:
	print("── %s ──" % suite_name)
	var instance = script.new()
	if instance == null:
		print("  ⚠️  Failed to instantiate suite")
		_fail_count += 1
		_errors.append("%s: failed to instantiate" % suite_name)
		return
	var methods: Array = instance.get_method_list()
	for m in methods:
		var method_name: String = m["name"]
		if not method_name.begins_with("test_"):
			continue
		var result: bool = true
		var error_msg: String = ""
		var ret = instance.call(method_name)
		if ret is bool:
			result = ret
		elif ret is String:
			result = false
			error_msg = ret
		if result:
			_pass_count += 1
			print("  ✅ %s" % method_name)
		else:
			_fail_count += 1
			var msg := "  ❌ %s" % method_name
			if error_msg != "":
				msg += " — %s" % error_msg
			print(msg)
			_errors.append("%s::%s %s" % [suite_name, method_name, error_msg])
	print("")

func _print_summary() -> void:
	print("═══════════════════════════════════════")
	print("  Results: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count > 0:
		print("\n  Failures:")
		for e in _errors:
			print("    • %s" % e)
	print("═══════════════════════════════════════\n")
