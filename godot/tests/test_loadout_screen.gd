# test_loadout_screen.gd — Tests for LoadoutScreen logic paths
# BattleBrotts Sprint 5 · S5-002
#
# Tests weight/slot validation, chassis selection constraints,
# and equipment limit enforcement that LoadoutScreen relies on.
extends RefCounted

const ChassisData = preload("res://game/data/chassis_data.gd")
const WeaponData = preload("res://game/data/weapon_data.gd")
const ArmorData = preload("res://game/data/armor_data.gd")
const ModuleData = preload("res://game/data/module_data.gd")

# ── Helper: creates a GameController with custom loadout ──

func _make_gc(chassis: String = "brawler", weapons: Array = ["minigun"],
		armor: String = "plating", modules: Array = []) -> GameController:
	var gc := GameController.new()
	gc.player_chassis = chassis
	gc.player_weapons = weapons
	gc.player_armor = armor
	gc.player_modules = modules
	return gc

# ── Weight budget tests ──

func test_weight_empty_loadout() -> bool:
	var gc := _make_gc("scout", ["plasma_cutter"], "", [])
	return gc.get_weight_used() == 8.0  # plasma_cutter = 8

func test_weight_full_loadout() -> bool:
	var gc := _make_gc("brawler", ["minigun", "shotgun"], "plating", ["overclock"])
	# minigun(10) + shotgun(12) + plating(15) + overclock(5) = 42
	return gc.get_weight_used() == 42.0

func test_weight_no_armor() -> bool:
	var gc := _make_gc("brawler", ["minigun"], "", [])
	return gc.get_weight_used() == 10.0  # minigun only

func test_weight_cap_scout() -> bool:
	var gc := _make_gc("scout")
	return gc.get_weight_cap() == 30.0

func test_weight_cap_brawler() -> bool:
	var gc := _make_gc("brawler")
	return gc.get_weight_cap() == 55.0

func test_weight_cap_fortress() -> bool:
	var gc := _make_gc("fortress")
	return gc.get_weight_cap() == 80.0

func test_overweight_rejected() -> bool:
	# Scout cap 30, railgun(15) + ablative_shell(25) = 40 > 30
	var gc := _make_gc("scout", ["railgun"], "ablative_shell", [])
	var v := gc.validate_loadout()
	return not v["valid"] and v["errors"].size() > 0

func test_exactly_at_cap_valid() -> bool:
	# Brawler cap 55: minigun(10) + shotgun(12) + plating(15) + overclock(5) + shield_projector(13) = 55
	var gc := _make_gc("brawler", ["minigun", "shotgun"], "plating", ["overclock", "shield_projector"])
	return gc.get_weight_used() == 55.0 and gc.validate_loadout()["valid"]

# ── Slot validation tests ──

func test_scout_one_weapon_slot() -> bool:
	var gc := _make_gc("scout", ["minigun", "shotgun"], "", [])
	var v := gc.validate_loadout()
	return not v["valid"]  # scout has 1 weapon slot

func test_scout_one_weapon_valid() -> bool:
	var gc := _make_gc("scout", ["minigun"], "", [])
	var v := gc.validate_loadout()
	return v["valid"]

func test_brawler_two_weapon_slots() -> bool:
	var gc := _make_gc("brawler", ["minigun", "shotgun"], "", [])
	var v := gc.validate_loadout()
	return v["valid"]

func test_brawler_three_weapons_rejected() -> bool:
	var gc := _make_gc("brawler", ["minigun", "shotgun", "plasma_cutter"], "", [])
	var v := gc.validate_loadout()
	return not v["valid"]

func test_fortress_one_module_slot() -> bool:
	var gc := _make_gc("fortress", ["minigun"], "", ["overclock", "repair_nanites"])
	var v := gc.validate_loadout()
	return not v["valid"]  # fortress has 1 module slot

func test_fortress_one_module_valid() -> bool:
	var gc := _make_gc("fortress", ["minigun"], "", ["overclock"])
	var v := gc.validate_loadout()
	return v["valid"]

# ── No weapon validation ──

func test_no_weapon_rejected() -> bool:
	var gc := _make_gc("brawler", [], "plating", [])
	var v := gc.validate_loadout()
	return not v["valid"]

func test_no_weapon_error_message() -> bool:
	var gc := _make_gc("brawler", [], "", [])
	var v := gc.validate_loadout()
	for e in v["errors"]:
		if "weapon" in e.to_lower():
			return true
	return false

# ── Multiple validation errors ──

func test_multiple_errors_reported() -> bool:
	# No weapons AND overweight
	var gc := _make_gc("scout", [], "ablative_shell", ["overclock", "repair_nanites"])
	var v := gc.validate_loadout()
	return not v["valid"] and v["errors"].size() >= 2

# ── Chassis selection truncates equipment ──

func test_chassis_switch_truncates_weapons() -> bool:
	# Simulate what loadout_screen._on_chassis_selected does
	var gc := _make_gc("brawler", ["minigun", "shotgun"], "", [])
	# Switch to scout (1 weapon slot) — the screen truncates
	gc.player_chassis = "scout"
	var chassis := gc.get_chassis_info("scout")
	while gc.player_weapons.size() > chassis["weapon_slots"]:
		gc.player_weapons.pop_back()
	return gc.player_weapons.size() == 1 and gc.player_weapons[0] == "minigun"

func test_chassis_switch_truncates_modules() -> bool:
	var gc := _make_gc("brawler", ["minigun"], "", ["overclock", "repair_nanites"])
	# Switch to fortress (1 module slot)
	gc.player_chassis = "fortress"
	var chassis := gc.get_chassis_info("fortress")
	while gc.player_modules.size() > chassis["module_slots"]:
		gc.player_modules.pop_back()
	return gc.player_modules.size() == 1 and gc.player_modules[0] == "overclock"

func test_chassis_switch_no_truncation_needed() -> bool:
	var gc := _make_gc("scout", ["minigun"], "", [])
	# Switch to brawler (2 weapon slots) — no truncation needed
	gc.player_chassis = "brawler"
	var chassis := gc.get_chassis_info("brawler")
	while gc.player_weapons.size() > chassis["weapon_slots"]:
		gc.player_weapons.pop_back()
	return gc.player_weapons.size() == 1

# ── Chassis data integrity (loadout screen populates from these) ──

func test_all_chassis_have_required_fields() -> bool:
	for id in ChassisData.list_ids():
		var c := ChassisData.get_chassis(id)
		if not c.has("name") or not c.has("hp") or not c.has("speed"):
			return false
		if not c.has("weight_cap") or not c.has("weapon_slots") or not c.has("module_slots"):
			return false
	return true

func test_all_weapons_have_required_fields() -> bool:
	for id in WeaponData.list_ids():
		var w := WeaponData.get_weapon(id)
		if not w.has("name") or not w.has("damage") or not w.has("range"):
			return false
		if not w.has("weight") or not w.has("energy_cost"):
			return false
	return true

func test_all_armor_have_required_fields() -> bool:
	for id in ArmorData.list_ids():
		var a := ArmorData.get_armor(id)
		if not a.has("name") or not a.has("damage_reduction") or not a.has("weight"):
			return false
	return true

func test_all_modules_have_required_fields() -> bool:
	for id in ModuleData.list_ids():
		var m := ModuleData.get_module(id)
		if not m.has("name") or not m.has("passive") or not m.has("weight"):
			return false
	return true

# ── Enemy info display data ──

func test_enemy_chassis_exists() -> bool:
	var c := ChassisData.get_chassis(GameController.ENEMY_CHASSIS)
	return c.has("name") and c["name"] != ""
