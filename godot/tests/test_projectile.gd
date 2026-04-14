# test_projectile.gd — Tests for Projectile system (Sprint 3)
extends "res://tests/test_runner.gd"

func run_tests() -> void:
	test_hitscan_creation()
	test_missile_creation()
	test_hitscan_resolves_instantly()
	test_missile_travels()
	test_missile_arrives()
	test_missile_homing()
	test_projectile_max_ticks()
	test_projectile_speeds_defined()

# ── Helpers ──────────────────────────────────────────────
func _make_brott(id: int, team: int, pos: Vector2) -> Brott:
	return Brott.create(id, team, "striker", ["minigun"], "", [], pos)

# ── Tests ────────────────────────────────────────────────
func test_hitscan_creation() -> void:
	var a := _make_brott(1, 0, Vector2(0, 0))
	var b := _make_brott(2, 1, Vector2(100, 0))
	var p := Projectile.create("minigun", a, b, 10.0, false, 0.0, 0)
	assert_true(p.is_hitscan(), "Minigun should be hitscan")
	assert_eq(p.speed, 0.0, "Hitscan speed should be 0")
	assert_eq(p.damage, 10.0, "Damage should be 10")

func test_missile_creation() -> void:
	var a := _make_brott(1, 0, Vector2(0, 0))
	var b := _make_brott(2, 1, Vector2(200, 0))
	var p := Projectile.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	assert_false(p.is_hitscan(), "Missile should not be hitscan")
	assert_eq(p.speed, 6.0, "Missile speed should be 6 px/tick")
	assert_eq(p.splash_radius, 2.0, "Splash radius should be 2")

func test_hitscan_resolves_instantly() -> void:
	var a := _make_brott(1, 0, Vector2(0, 0))
	var b := _make_brott(2, 1, Vector2(100, 0))
	var p := Projectile.create("minigun", a, b, 10.0, false, 0.0, 0)
	var still_flying := p.update()
	assert_false(still_flying, "Hitscan should resolve in one update")
	assert_false(p.alive, "Hitscan should not be alive after update")

func test_missile_travels() -> void:
	var a := _make_brott(1, 0, Vector2(0, 0))
	var b := _make_brott(2, 1, Vector2(200, 0))
	var p := Projectile.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	# After one update, should have moved but not arrived
	var still_flying := p.update()
	assert_true(still_flying, "Missile should still be flying after 1 tick")
	assert_true(p.alive, "Missile should be alive")
	assert_true(p.position.x > 0.0, "Missile should have moved")
	assert_true(p.position.x < 200.0, "Missile should not have arrived yet")

func test_missile_arrives() -> void:
	var a := _make_brott(1, 0, Vector2(0, 0))
	var b := _make_brott(2, 1, Vector2(20, 0))  # Close target
	var p := Projectile.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	# At 6 px/tick, should reach 20px in ~4 ticks (within 8px threshold)
	var arrived := false
	for i in 10:
		if not p.update():
			arrived = true
			break
	assert_true(arrived, "Missile should have arrived at close target")
	assert_true(p.has_arrived(), "has_arrived() should be true")

func test_missile_homing() -> void:
	var a := _make_brott(1, 0, Vector2(0, 0))
	var b := _make_brott(2, 1, Vector2(100, 0))
	var p := Projectile.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	p.update()
	# Move target
	b.position = Vector2(100, 50)
	p.update()
	# Direction should have adjusted toward new target position
	assert_true(p.direction.y > 0.0, "Missile should home toward moved target")

func test_projectile_max_ticks() -> void:
	var a := _make_brott(1, 0, Vector2(0, 0))
	var b := _make_brott(2, 1, Vector2(100000, 0))  # Very far
	var p := Projectile.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	var count := 0
	while p.update():
		count += 1
	assert_true(count <= Projectile.MAX_TICKS, "Should expire within MAX_TICKS")

func test_projectile_speeds_defined() -> void:
	# All weapons should have a speed entry
	for wid in ["minigun", "railgun", "shotgun", "missile_pod", "arc_emitter"]:
		assert_true(Projectile.PROJECTILE_SPEEDS.has(wid),
			"Speed should be defined for %s" % wid)
