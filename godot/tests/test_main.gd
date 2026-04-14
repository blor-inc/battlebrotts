# test_main.gd — Scene-based test runner (class_name works in scene mode)
extends Node

var _pass_count: int = 0
var _fail_count: int = 0
var _errors: Array = []

func _ready() -> void:
	_run_all_tests()
	_print_summary()
	get_tree().quit(1 if _fail_count > 0 else 0)

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
