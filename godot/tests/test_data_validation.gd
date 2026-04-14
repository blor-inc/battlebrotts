# test_data_validation.gd — Verify all game data matches GDD v2
extends RefCounted

const ChassisData = preload("res://game/data/chassis_data.gd")
const WeaponData = preload("res://game/data/weapon_data.gd")
const ArmorData = preload("res://game/data/armor_data.gd")
const ModuleData = preload("res://game/data/module_data.gd")

func test_chassis_scout() -> bool:
	var c = ChassisData.get_chassis("scout")
	return c["hp"] == 80 and c["speed"] == 200 and c["weight_cap"] == 30 and c["weapon_slots"] == 1 and c["module_slots"] == 3

func test_chassis_brawler() -> bool:
	var c = ChassisData.get_chassis("brawler")
	return c["hp"] == 150 and c["speed"] == 120 and c["weight_cap"] == 55 and c["weapon_slots"] == 2 and c["module_slots"] == 2

func test_chassis_fortress() -> bool:
	var c = ChassisData.get_chassis("fortress")
	return c["hp"] == 250 and c["speed"] == 70 and c["weight_cap"] == 80 and c["weapon_slots"] == 3 and c["module_slots"] == 1

func test_chassis_count() -> bool:
	return ChassisData.list_ids().size() == 3

func test_weapon_minigun() -> bool:
	var w = WeaponData.get_weapon("minigun")
	return w["damage"] == 4 and w["range"] == 5 and w["fire_rate"] == 10.0 and w["spread"] == 15.0 and w["energy_cost"] == 1 and w["weight"] == 10

func test_weapon_railgun() -> bool:
	var w = WeaponData.get_weapon("railgun")
	return w["damage"] == 45 and w["range"] == 12 and w["fire_rate"] == 0.5 and w["spread"] == 0.0 and w["energy_cost"] == 20 and w["weight"] == 15

func test_weapon_shotgun() -> bool:
	var w = WeaponData.get_weapon("shotgun")
	return w["damage"] == 6 and w["pellets"] == 5 and w["range"] == 3 and w["fire_rate"] == 1.5 and w["spread"] == 30.0 and w["energy_cost"] == 8 and w["weight"] == 12

func test_weapon_missile_pod() -> bool:
	var w = WeaponData.get_weapon("missile_pod")
	return w["damage"] == 30 and w["range"] == 8 and w["fire_rate"] == 0.8 and w["spread"] == 5.0 and w["energy_cost"] == 12 and w["weight"] == 18 and w["splash_radius"] == 1

func test_weapon_plasma_cutter() -> bool:
	var w = WeaponData.get_weapon("plasma_cutter")
	return w["damage"] == 12 and w["range"] == 1.5 and w["fire_rate"] == 3.0 and w["spread"] == 0.0 and w["energy_cost"] == 4 and w["weight"] == 8

func test_weapon_arc_emitter() -> bool:
	var w = WeaponData.get_weapon("arc_emitter")
	return w["damage"] == 8 and w["range"] == 4 and w["fire_rate"] == 2.0 and w["spread"] == 10.0 and w["energy_cost"] == 6 and w["weight"] == 11 and w["chain_targets"] == 1

func test_weapon_flak_cannon() -> bool:
	var w = WeaponData.get_weapon("flak_cannon")
	return w["damage"] == 15 and w["range"] == 6 and w["fire_rate"] == 1.2 and w["spread"] == 20.0 and w["energy_cost"] == 7 and w["weight"] == 13

func test_weapon_count() -> bool:
	return WeaponData.list_ids().size() == 7

func test_armor_plating() -> bool:
	var a = ArmorData.get_armor("plating")
	return a["damage_reduction"] == 0.20 and a["weight"] == 15

func test_armor_reactive_mesh() -> bool:
	var a = ArmorData.get_armor("reactive_mesh")
	return a["damage_reduction"] == 0.10 and a["weight"] == 8 and a["reflect_damage"] == 5

func test_armor_ablative_shell() -> bool:
	var a = ArmorData.get_armor("ablative_shell")
	return a["damage_reduction"] == 0.40 and a["weight"] == 25 and a["reduced_threshold"] == 0.30 and a["reduced_damage_reduction"] == 0.10

func test_armor_count() -> bool:
	return ArmorData.list_ids().size() == 3

func test_armor_effective_reduction_plating() -> bool:
	return ArmorData.effective_reduction("plating", 1.0) == 0.20 and ArmorData.effective_reduction("plating", 0.1) == 0.20

func test_armor_effective_reduction_ablative_above() -> bool:
	return ArmorData.effective_reduction("ablative_shell", 0.5) == 0.40

func test_armor_effective_reduction_ablative_below() -> bool:
	return ArmorData.effective_reduction("ablative_shell", 0.2) == 0.10

func test_armor_effective_reduction_none() -> bool:
	return ArmorData.effective_reduction("", 1.0) == 0.0

func test_module_overclock() -> bool:
	var m = ModuleData.get_module("overclock")
	return m["weight"] == 5 and not m["passive"] and m["activated"] and m["boost_amount"] == 0.30

func test_module_repair_nanites() -> bool:
	var m = ModuleData.get_module("repair_nanites")
	return m["weight"] == 7 and m["passive"] and not m["activated"] and m["heal_per_tick"] == 0.15

func test_module_shield_projector() -> bool:
	var m = ModuleData.get_module("shield_projector")
	return m["weight"] == 10 and m["shield_hp"] == 40 and m["duration_sec"] == 5.0 and m["cooldown_sec"] == 20.0

func test_module_sensor_array() -> bool:
	var m = ModuleData.get_module("sensor_array")
	return m["weight"] == 4 and m["passive"] and m["sight_bonus_tiles"] == 3 and m["reveals_cover"]

func test_module_afterburner() -> bool:
	var m = ModuleData.get_module("afterburner")
	return m["weight"] == 6 and m["speed_multiplier"] == 1.80 and m["duration_sec"] == 2.0 and m["cooldown_sec"] == 12.0

func test_module_emp_charge() -> bool:
	var m = ModuleData.get_module("emp_charge")
	return m["weight"] == 9 and m["disable_duration_sec"] == 3.0 and m["range_tiles"] == 4 and m["cooldown_sec"] == 25.0

func test_module_count() -> bool:
	return ModuleData.list_ids().size() == 6

func test_minigun_fire_interval() -> bool:
	return WeaponData.fire_interval_ticks("minigun") == 2

func test_railgun_fire_interval() -> bool:
	return WeaponData.fire_interval_ticks("railgun") == 40

func test_shotgun_fire_interval() -> bool:
	return WeaponData.fire_interval_ticks("shotgun") == 14

func test_plasma_cutter_fire_interval() -> bool:
	return WeaponData.fire_interval_ticks("plasma_cutter") == 7
