# test_tick_system.gd — Tests for TickSystem combat simulation
extends RefCounted

const Brott = preload("res://game/entities/brott.gd")
const TickSystem = preload("res://game/combat/tick_system.gd")
const ChassisData = preload("res://game/data/chassis_data.gd")
const WeaponData = preload("res://game/data/weapon_data.gd")
const ArmorData = preload("res://game/data/armor_data.gd")
const ModuleData = preload("res://game/data/module_data.gd")
const DamageCalculator = preload("res://game/combat/damage_calculator.gd")

func _make_match(seed_val: int = 42) -> Array:
	# Brawler: 55kg cap. minigun(10) + plating(15) + repair_nanites(7) = 32kg
	var b1 = Brott.create(1, 0, "brawler", ["minigun"], "plating", ["repair_nanites"], Vector2(32, 32))
	var b2 = Brott.create(2, 1, "brawler", ["minigun"], "plating", ["repair_nanites"], Vector2(128, 32))
	var ts = TickSystem.new()
	ts.setup(seed_val, [b1, b2])
	return [ts, b1, b2]

func test_tick_increments() -> bool:
	var m = _make_match()
	var ts = m[0]
	ts.run_tick()
	return ts.tick == 1

func test_energy_regen_per_tick() -> bool:
	var m = _make_match()
	var ts = m[0]
	var b1 = m[1]
	b1.energy = 50.0
	# Position far apart so weapons don't fire (minigun range=5 tiles=160px)
	m[2].position = Vector2(32 + 20 * 32, 32)
	ts.run_tick()
	# Energy: 50 + 0.25 regen - 0 weapon cost = 50.25
	return b1.energy >= 50.25 and b1.energy <= 50.26

func test_repair_nanites_healing() -> bool:
	var m = _make_match()
	var ts = m[0]
	var b1 = m[1]
	b1.hp = 50.0
	# Position far apart so no combat damage
	m[2].position = Vector2(32 + 20 * 32, 32)
	ts.run_tick()
	# Repair nanites: +0.15 HP/tick
	return b1.hp >= 50.15 and b1.hp <= 50.16

func test_weapon_fires_in_range() -> bool:
	var m = _make_match()
	var ts = m[0]
	var b1 = m[1]
	var b2 = m[2]
	b2.position = Vector2(32 + 4 * 32, 32)
	ts.run_tick()
	return b1.weapon_cooldowns[0] > 0 or b2.hp < 150.0

func test_weapon_doesnt_fire_out_of_range() -> bool:
	var m = _make_match()
	var ts = m[0]
	var b1 = m[1]
	var b2 = m[2]
	b2.position = Vector2(32 + 20 * 32, 32)
	ts.run_tick()
	return b2.hp == 150.0

func test_weapon_doesnt_fire_no_energy() -> bool:
	var m = _make_match()
	var ts = m[0]
	var b1 = m[1]
	var b2 = m[2]
	b1.energy = 0.0
	b2.position = Vector2(32 + 3 * 32, 32)
	ts.run_tick()
	return b2.hp == 150.0

func test_match_ends_one_team_dead() -> bool:
	var m = _make_match()
	var ts = m[0]
	var b2 = m[2]
	b2.hp = 0.0
	b2.alive = false
	ts.run_tick()
	return ts.match_over and ts.winner_team == 0

func test_match_timeout_at_120s() -> bool:
	var ts = TickSystem.new()
	var b1 = Brott.create(1, 0, "brawler", ["minigun"], "", [], Vector2(0, 0))
	var b2 = Brott.create(2, 1, "brawler", ["minigun"], "", [], Vector2(5000, 5000))
	ts.setup(42, [b1, b2])
	ts.tick = 120 * 20 - 1
	ts.run_tick()
	return ts.match_over

func test_timeout_higher_hp_wins() -> bool:
	var ts = TickSystem.new()
	var b1 = Brott.create(1, 0, "brawler", ["minigun"], "", [], Vector2(0, 0))
	var b2 = Brott.create(2, 1, "brawler", ["minigun"], "", [], Vector2(5000, 5000))
	b1.hp = 100.0
	b2.hp = 50.0
	ts.setup(42, [b1, b2])
	ts.tick = 120 * 20 - 1
	ts.run_tick()
	return ts.winner_team == 0

func test_draw_mutual_destruction() -> bool:
	var ts = TickSystem.new()
	var b1 = Brott.create(1, 0, "scout", ["minigun"], "", [], Vector2(0, 0))
	var b2 = Brott.create(2, 1, "scout", ["minigun"], "", [], Vector2(100, 0))
	b1.alive = false
	b1.hp = 0.0
	b2.alive = false
	b2.hp = 0.0
	ts.setup(42, [b1, b2])
	ts.run_tick()
	return ts.match_over and ts.winner_team == -1

func test_determinism_same_seed() -> bool:
	var run = func(seed_val: int) -> Array:
		var b1 = Brott.create(1, 0, "scout", ["minigun"], "plating", [], Vector2(32, 32))
		var b2 = Brott.create(2, 1, "scout", ["minigun"], "plating", [], Vector2(128, 32))
		var ts = TickSystem.new()
		ts.setup(seed_val, [b1, b2])
		for i in range(100):
			if not ts.run_tick():
				break
		return [b1.hp, b2.hp, ts.tick, ts.winner_team]
	var r1 = run.call(12345)
	var r2 = run.call(12345)
	return r1[0] == r2[0] and r1[1] == r2[1] and r1[2] == r2[2] and r1[3] == r2[3]

func test_reactive_mesh_reflect() -> bool:
	var b1 = Brott.create(1, 0, "scout", ["railgun"], "", [], Vector2(32, 32))
	var b2 = Brott.create(2, 1, "brawler", ["minigun"], "reactive_mesh", [], Vector2(64, 32))
	var ts = TickSystem.new()
	ts.setup(42, [b1, b2])
	var b1_hp_before = b1.hp
	for i in range(50):
		ts.run_tick()
	return b1.hp < b1_hp_before or b2.hp == 150.0

func test_constants() -> bool:
	var ts = TickSystem.new()
	return ts.TICKS_PER_SECOND == 20 and ts.TICK_DELTA == 0.05 and ts.MAX_MATCH_TICKS == 2400
