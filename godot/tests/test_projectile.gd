# test_projectile.gd — Tests for Projectile system (Sprint 3)
extends RefCounted

const BrottScript = preload("res://game/entities/brott.gd")
const ProjectileScript = preload("res://game/combat/projectile.gd")

func _make_brott(id: int, team: int, pos: Vector2):
	return BrottScript.create(id, team, "scout", ["minigun"], "", [], pos)

func test_hitscan_creation() -> bool:
	var a = _make_brott(1, 0, Vector2(0, 0))
	var b = _make_brott(2, 1, Vector2(100, 0))
	var p = ProjectileScript.create("minigun", a, b, 10.0, false, 0.0, 0)
	return p.is_hitscan() and p.speed == 0.0 and p.damage == 10.0

func test_missile_creation() -> bool:
	var a = _make_brott(1, 0, Vector2(0, 0))
	var b = _make_brott(2, 1, Vector2(200, 0))
	var p = ProjectileScript.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	return not p.is_hitscan() and p.speed == 6.0 and p.splash_radius == 2.0

func test_hitscan_resolves_instantly() -> bool:
	var a = _make_brott(1, 0, Vector2(0, 0))
	var b = _make_brott(2, 1, Vector2(100, 0))
	var p = ProjectileScript.create("minigun", a, b, 10.0, false, 0.0, 0)
	var still_flying: bool = p.update()
	return not still_flying and not p.alive

func test_missile_travels() -> bool:
	var a = _make_brott(1, 0, Vector2(0, 0))
	var b = _make_brott(2, 1, Vector2(200, 0))
	var p = ProjectileScript.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	var still_flying: bool = p.update()
	return still_flying and p.alive and p.position.x > 0.0 and p.position.x < 200.0

func test_missile_arrives() -> bool:
	var a = _make_brott(1, 0, Vector2(0, 0))
	var b = _make_brott(2, 1, Vector2(20, 0))
	var p = ProjectileScript.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	var arrived := false
	for i in 10:
		if not p.update():
			arrived = true
			break
	return arrived and p.has_arrived()

func test_missile_homing() -> bool:
	var a = _make_brott(1, 0, Vector2(0, 0))
	var b = _make_brott(2, 1, Vector2(100, 0))
	var p = ProjectileScript.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	p.update()
	b.position = Vector2(100, 50)
	p.update()
	return p.direction.y > 0.0

func test_projectile_max_ticks() -> bool:
	var a = _make_brott(1, 0, Vector2(0, 0))
	var b = _make_brott(2, 1, Vector2(100000, 0))
	var p = ProjectileScript.create("missile_pod", a, b, 25.0, false, 2.0, 0)
	var count := 0
	while p.update():
		count += 1
	return count <= ProjectileScript.MAX_TICKS

func test_projectile_speeds_defined() -> bool:
	for wid in ["minigun", "railgun", "shotgun", "missile_pod", "arc_emitter"]:
		if not ProjectileScript.PROJECTILE_SPEEDS.has(wid):
			return false
	return true
