# test_brott.gd — Tests for Brott entity
extends RefCounted

const Brott = preload("res://game/entities/brott.gd")
const ChassisData = preload("res://game/data/chassis_data.gd")
const WeaponData = preload("res://game/data/weapon_data.gd")
const ArmorData = preload("res://game/data/armor_data.gd")
const ModuleData = preload("res://game/data/module_data.gd")

func _make_scout():
	# Scout: 30kg cap. minigun(10) + repair_nanites(7) = 17kg
	return Brott.create(1, 0, "scout", ["minigun"], "", ["repair_nanites"], Vector2(100, 100))

func _make_scout_armored():
	# Scout: 30kg cap. plasma_cutter(8) + plating(15) = 23kg
	return Brott.create(3, 0, "scout", ["plasma_cutter"], "plating", [], Vector2(100, 100))

func _make_brawler():
	return Brott.create(2, 1, "brawler", ["minigun", "shotgun"], "plating", ["overclock"], Vector2(200, 200))

func test_factory_creates_valid_brott() -> bool:
	var b = _make_scout()
	return b.id == 1 and b.team == 0 and b.chassis_id == "scout" and b.alive

func test_scout_stats() -> bool:
	var b = _make_scout()
	return b.max_hp == 80.0 and b.hp == 80.0 and b.speed == 200.0 and b.weight_cap == 30.0

func test_brawler_stats() -> bool:
	var b = _make_brawler()
	return b.max_hp == 150.0 and b.speed == 120.0 and b.weight_cap == 55.0

func test_hp_ratio_full() -> bool:
	var b = _make_scout()
	return b.hp_ratio() == 1.0

func test_hp_ratio_half() -> bool:
	var b = _make_scout()
	b.hp = 40.0
	return b.hp_ratio() == 0.5

func test_apply_damage() -> bool:
	var b = _make_scout()
	b.apply_damage(30.0)
	return b.hp == 50.0 and b.alive

func test_apply_damage_kills() -> bool:
	var b = _make_scout()
	b.apply_damage(80.0)
	return b.hp == 0.0 and not b.alive

func test_apply_damage_overkill() -> bool:
	var b = _make_scout()
	b.apply_damage(200.0)
	return b.hp == 0.0 and not b.alive

func test_damage_on_dead_brott() -> bool:
	var b = _make_scout()
	b.alive = false
	b.apply_damage(10.0)
	return b.hp == 80.0

func test_shield_absorbs_damage() -> bool:
	var b = _make_scout()
	b.shield_hp = 20.0
	b.apply_damage(15.0)
	return b.shield_hp == 5.0 and b.hp == 80.0

func test_shield_partial_absorb() -> bool:
	var b = _make_scout()
	b.shield_hp = 10.0
	b.apply_damage(25.0)
	return b.shield_hp == 0.0 and b.hp == 65.0

func test_energy_starts_full() -> bool:
	var b = _make_scout()
	return b.energy == 100.0

func test_spend_energy_success() -> bool:
	var b = _make_scout()
	var ok = b.spend_energy(20.0)
	return ok and b.energy == 80.0

func test_spend_energy_insufficient() -> bool:
	var b = _make_scout()
	b.energy = 5.0
	var ok = b.spend_energy(20.0)
	return not ok and b.energy == 5.0

func test_regen_energy() -> bool:
	var b = _make_scout()
	b.energy = 50.0
	b.regen_energy()
	return b.energy == 50.25

func test_regen_energy_capped() -> bool:
	var b = _make_scout()
	b.energy = 99.9
	b.regen_energy()
	return b.energy == 100.0

func test_apply_heal() -> bool:
	var b = _make_scout()
	b.hp = 50.0
	b.apply_heal(10.0)
	return b.hp == 60.0

func test_apply_heal_capped() -> bool:
	var b = _make_scout()
	b.hp = 75.0
	b.apply_heal(20.0)
	return b.hp == 80.0

func test_distance_to_brott() -> bool:
	var b1 = _make_scout()
	var b2 = Brott.create(3, 1, "scout", ["minigun"], "", ["repair_nanites"], Vector2(132, 100))
	return b1.distance_to_brott(b2) == 1.0

func test_weapon_cooldowns_init() -> bool:
	var b = _make_brawler()
	return b.weapon_cooldowns.size() == 2 and b.weapon_cooldowns[0] == 0 and b.weapon_cooldowns[1] == 0

func test_module_states_init() -> bool:
	var b = _make_scout()
	return b.module_states.has("repair_nanites")

func test_is_dead() -> bool:
	var b = _make_scout()
	return not b.is_dead()
