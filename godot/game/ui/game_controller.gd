# game_controller.gd — Main game flow controller
# BattleBrotts Sprint 4 · S4-001
#
# Manages scene transitions: Loadout → Match → Result
# This is the main scene script, autoloaded or attached to root.
class_name GameController
extends Node

enum Screen { LOADOUT, MATCH, RESULT }

var current_screen: Screen = Screen.LOADOUT

# Player loadout
var player_chassis: String = "brawler"
var player_weapons: Array = ["minigun"]
var player_armor: String = "plating"
var player_modules: Array = []

# Enemy loadout (pre-built)
const ENEMY_CHASSIS: String = "brawler"
const ENEMY_WEAPONS: Array = ["shotgun", "missile_pod"]
const ENEMY_ARMOR: String = "reactive_mesh"
const ENEMY_MODULES: Array = ["repair_nanites"]

# Match state
var match_manager: MatchManager = null
var arena: ArenaManager = null
var player_brott: Brott = null
var enemy_brott: Brott = null
var match_result: Dictionary = {}

# Simulation playback
var sim_ticks: Array = []  # Array of frame snapshots for playback
var sim_complete: bool = false

signal screen_changed(screen: Screen)
signal match_tick(tick_data: Dictionary)
signal match_finished(result: Dictionary)

# Scene references (set in _ready from scene tree)
var loadout_screen: Control = null
var match_screen: Control = null
var result_screen: Control = null
var arena_view = null
var match_hud = null


func _ready() -> void:
	match_manager = MatchManager.new()
	match_manager.match_ended.connect(_on_match_ended)

	# Get screen references (only if in scene tree with UI)
	if has_node("CanvasLayer/LoadoutScreen"):
		loadout_screen = $CanvasLayer/LoadoutScreen
		match_screen = $CanvasLayer/MatchScreen
		result_screen = $CanvasLayer/ResultScreen
		arena_view = $CanvasLayer/MatchScreen/ArenaView
		match_hud = $CanvasLayer/MatchScreen/HUD

		# Setup screens
		loadout_screen.setup(self)
		result_screen.setup(self)

		# Connect screen changes
		screen_changed.connect(_on_screen_changed)
		_show_screen(Screen.LOADOUT)


func _on_screen_changed(screen: Screen) -> void:
	_show_screen(screen)


func _show_screen(screen: Screen) -> void:
	loadout_screen.visible = (screen == Screen.LOADOUT)
	match_screen.visible = (screen == Screen.MATCH)
	result_screen.visible = (screen == Screen.RESULT)

	if screen == Screen.MATCH:
		arena_view.setup(arena, player_brott, enemy_brott)
		match_hud.setup(self)
	elif screen == Screen.RESULT:
		result_screen.show_result(match_result)


func start_match() -> void:
	# Setup arena
	arena = ArenaManager.new()
	arena.load_layout("the_pit")

	# Create player brott
	player_brott = Brott.create(
		0, 0, player_chassis,
		player_weapons, player_armor, player_modules,
		Vector2(2 * 32, 8 * 32)  # Left side of arena
	)

	# Create enemy brott
	enemy_brott = Brott.create(
		1, 1, ENEMY_CHASSIS,
		ENEMY_WEAPONS, ENEMY_ARMOR, ENEMY_MODULES,
		Vector2(13 * 32, 8 * 32)  # Right side of arena
	)

	# Setup and run match
	match_manager.setup_match([player_brott], [enemy_brott])

	current_screen = Screen.MATCH
	screen_changed.emit(Screen.MATCH)

	# Run simulation tick by tick with snapshots
	sim_ticks.clear()
	sim_complete = false
	match_manager.start_match()


func step_simulation() -> bool:
	"""Run one tick and capture snapshot. Returns false when match is over."""
	if not match_manager.is_running():
		return false

	var continues := match_manager.step()

	# Capture snapshot for this tick
	var snapshot := {
		"tick": match_manager.get_tick(),
		"elapsed": match_manager.get_elapsed_seconds(),
		"player": {
			"hp": player_brott.hp,
			"max_hp": player_brott.max_hp,
			"hp_ratio": player_brott.hp_ratio(),
			"energy": player_brott.energy,
			"alive": player_brott.alive,
			"position": player_brott.position,
			"shield_hp": player_brott.shield_hp,
		},
		"enemy": {
			"hp": enemy_brott.hp,
			"max_hp": enemy_brott.max_hp,
			"hp_ratio": enemy_brott.hp_ratio(),
			"energy": enemy_brott.energy,
			"alive": enemy_brott.alive,
			"position": enemy_brott.position,
			"shield_hp": enemy_brott.shield_hp,
		},
	}
	sim_ticks.append(snapshot)
	match_tick.emit(snapshot)

	if not continues:
		sim_complete = true
		return false

	return true


func run_full_simulation() -> Dictionary:
	"""Run entire match instantly, capturing all snapshots."""
	while step_simulation():
		pass
	return match_result


func _on_match_ended(result: Dictionary) -> void:
	match_result = result
	current_screen = Screen.RESULT
	screen_changed.emit(Screen.RESULT)
	match_finished.emit(result)


func restart() -> void:
	"""Return to loadout screen."""
	match_manager.reset()
	sim_ticks.clear()
	sim_complete = false
	player_brott = null
	enemy_brott = null
	match_result = {}
	current_screen = Screen.LOADOUT
	screen_changed.emit(Screen.LOADOUT)


# ── Loadout helpers ──────────────────────────────────────

func get_available_chassis() -> Array:
	return ChassisData.list_ids()

func get_available_weapons() -> Array:
	return WeaponData.list_ids()

func get_available_armor() -> Array:
	return ArmorData.list_ids()

func get_available_modules() -> Array:
	return ModuleData.list_ids()

func get_chassis_info(id: String) -> Dictionary:
	return ChassisData.get_chassis(id)

func get_weapon_info(id: String) -> Dictionary:
	return WeaponData.get_weapon(id)

func get_armor_info(id: String) -> Dictionary:
	return ArmorData.get_armor(id)

func get_module_info(id: String) -> Dictionary:
	return ModuleData.get_module(id)

func get_weight_used() -> float:
	var total := 0.0
	for wid in player_weapons:
		total += WeaponData.get_weapon(wid)["weight"]
	if player_armor != "":
		total += ArmorData.get_armor(player_armor)["weight"]
	for mid in player_modules:
		total += ModuleData.get_module(mid)["weight"]
	return total

func get_weight_cap() -> float:
	return ChassisData.get_chassis(player_chassis)["weight_cap"]

func validate_loadout() -> Dictionary:
	"""Returns { valid: bool, errors: Array[String] }"""
	var errors := []
	var chassis := ChassisData.get_chassis(player_chassis)

	if player_weapons.size() == 0:
		errors.append("Must equip at least one weapon")
	if player_weapons.size() > chassis["weapon_slots"]:
		errors.append("Too many weapons (%d/%d)" % [player_weapons.size(), chassis["weapon_slots"]])
	if player_modules.size() > chassis["module_slots"]:
		errors.append("Too many modules (%d/%d)" % [player_modules.size(), chassis["module_slots"]])
	if get_weight_used() > get_weight_cap():
		errors.append("Overweight (%.0f/%.0f)" % [get_weight_used(), get_weight_cap()])

	return {"valid": errors.size() == 0, "errors": errors}
