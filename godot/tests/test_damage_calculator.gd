# test_damage_calculator.gd — Tests for DamageCalculator
extends RefCounted

const DamageCalculator = preload("res://game/combat/damage_calculator.gd")
const ArmorData = preload("res://game/data/armor_data.gd")
const WeaponData = preload("res://game/data/weapon_data.gd")
const ChassisData = preload("res://game/data/chassis_data.gd")

func _make_rng(seed_val: int = 42) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_val
	return r

func test_no_armor_damage() -> bool:
	var rng := _make_rng(100)
	var result = DamageCalculator.calc_hit(10.0, "", 1.0, rng)
	return result["damage"] == 10.0 or result["damage"] == 15.0

func test_plating_reduction() -> bool:
	var rng := _make_rng(200)
	var result = DamageCalculator.calc_hit(10.0, "plating", 1.0, rng)
	return result["damage"] == 8.0 or result["damage"] == 12.0

func test_reactive_mesh_reduction_and_reflect() -> bool:
	var rng := _make_rng(300)
	var result = DamageCalculator.calc_hit(10.0, "reactive_mesh", 1.0, rng)
	if result["reflect_damage"] != 5.0:
		return false
	return result["damage"] == 9.0 or result["damage"] == 13.5

func test_ablative_shell_above_threshold() -> bool:
	var rng := _make_rng(400)
	var result = DamageCalculator.calc_hit(10.0, "ablative_shell", 0.5, rng)
	return result["damage"] == 6.0 or result["damage"] == 9.0

func test_ablative_shell_below_threshold() -> bool:
	var rng := _make_rng(500)
	var result = DamageCalculator.calc_hit(10.0, "ablative_shell", 0.2, rng)
	return result["damage"] == 9.0 or result["damage"] == 13.5

func test_minimum_damage() -> bool:
	var rng := _make_rng(600)
	var result = DamageCalculator.calc_hit(0.5, "ablative_shell", 0.5, rng)
	return result["damage"] >= 1.0

func test_splash_half_damage() -> bool:
	var rng := _make_rng(700)
	var result = DamageCalculator.calc_splash(30.0, "", 1.0, rng)
	return result["damage"] == 15.0 or result["damage"] == 22.5

func test_pellet_weapon_shot() -> bool:
	var rng := _make_rng(800)
	var results = DamageCalculator.calc_weapon_shot("shotgun", "", 1.0, rng)
	if results.size() != 5:
		return false
	for r in results:
		if r["damage"] != 6.0 and r["damage"] != 9.0:
			return false
	return true

func test_single_projectile_weapon_shot() -> bool:
	var rng := _make_rng(900)
	var results = DamageCalculator.calc_weapon_shot("railgun", "", 1.0, rng)
	if results.size() != 1:
		return false
	return results[0]["damage"] == 45.0 or results[0]["damage"] == 67.5

func test_no_reflect_without_reactive_mesh() -> bool:
	var rng := _make_rng(1000)
	var result = DamageCalculator.calc_hit(10.0, "plating", 1.0, rng)
	return result["reflect_damage"] == 0.0

func test_crit_fields_present() -> bool:
	var rng := _make_rng(1100)
	var result = DamageCalculator.calc_hit(10.0, "", 1.0, rng)
	return result.has("damage") and result.has("is_crit") and result.has("reflect_damage")

func test_deterministic_with_same_seed() -> bool:
	var r1 := _make_rng(42)
	var r2 := _make_rng(42)
	var res1 = DamageCalculator.calc_hit(10.0, "plating", 1.0, r1)
	var res2 = DamageCalculator.calc_hit(10.0, "plating", 1.0, r2)
	return res1["damage"] == res2["damage"] and res1["is_crit"] == res2["is_crit"]

func test_dodge_chance_scout() -> bool:
	# With enough rolls, Scout's 15% dodge should produce some dodged hits
	var rng := _make_rng(42)
	var dodged_count := 0
	for i in 100:
		var results = DamageCalculator.calc_weapon_shot("minigun", "", 1.0, rng, "scout")
		for r in results:
			if r.get("dodged", false):
				dodged_count += 1
	return dodged_count > 0 and dodged_count < 100

func test_no_dodge_without_chassis() -> bool:
	# Without chassis id, no dodge should occur
	var rng := _make_rng(42)
	var results = DamageCalculator.calc_weapon_shot("minigun", "", 1.0, rng)
	for r in results:
		if r.has("dodged") and r["dodged"]:
			return false
	return true

func test_no_dodge_fortress() -> bool:
	# Fortress has no dodge_chance, so no dodges
	var rng := _make_rng(42)
	var dodged_count := 0
	for i in 100:
		var results = DamageCalculator.calc_weapon_shot("minigun", "", 1.0, rng, "fortress")
		for r in results:
			if r.get("dodged", false):
				dodged_count += 1
	return dodged_count == 0
