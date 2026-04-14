# projectile.gd — Projectile entity with travel time
# BattleBrotts Sprint 3 · S3-002
#
# Projectiles travel at a set speed and hit on arrival.
# Instant-hit weapons (hitscan) use speed = 0 (resolved same tick).
# Missiles/etc use real travel with splash on impact.
class_name Projectile

# ── Config ───────────────────────────────────────────────
var weapon_id: String = ""
var attacker: Brott = null
var target: Brott = null        # targeted brott (for homing / tracking)
var team: int = -1

# ── Movement ─────────────────────────────────────────────
var position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var speed: float = 0.0          # px per tick (0 = hitscan/instant)
var direction: Vector2 = Vector2.ZERO

# ── Damage payload ───────────────────────────────────────
var damage: float = 0.0
var is_crit: bool = false
var splash_radius: float = 0.0  # tiles
var chain_targets: int = 0

# ── State ────────────────────────────────────────────────
var alive: bool = true
var ticks_alive: int = 0
const MAX_TICKS: int = 60       # 3 seconds max flight time

# ── Projectile speeds by weapon type (px/tick) ──────────
# Hitscan (minigun, railgun, shotgun, arc_emitter) = 0 (instant)
# Missile = 6 px/tick (120 px/s)
const PROJECTILE_SPEEDS := {
	"minigun": 0.0,
	"railgun": 0.0,
	"shotgun": 0.0,
	"missile_pod": 6.0,
	"arc_emitter": 0.0,
}

# ─────────────────────────────────────────────────────────
# Factory
# ─────────────────────────────────────────────────────────
static func create(wid: String, from: Brott, to: Brott,
		dmg: float, crit: bool, splash: float, chain: int):
	var script := preload("res://game/combat/projectile.gd")
	var p = script.new()
	p.weapon_id = wid
	p.attacker = from
	p.target = to
	p.team = from.team
	p.position = from.position
	p.target_position = to.position
	p.damage = dmg
	p.is_crit = crit
	p.splash_radius = splash
	p.chain_targets = chain

	p.speed = PROJECTILE_SPEEDS.get(wid, 0.0)

	if p.speed > 0.0:
		var diff := to.position - from.position
		if diff.length() > 0:
			p.direction = diff.normalized()
	return p

func is_hitscan() -> bool:
	return speed <= 0.0

# ─────────────────────────────────────────────────────────
# Update — move toward target, return true if still flying
# ─────────────────────────────────────────────────────────
func update() -> bool:
	if not alive:
		return false

	ticks_alive += 1
	if ticks_alive > MAX_TICKS:
		alive = false
		return false

	if is_hitscan():
		# Hitscan resolves instantly — should not be in projectile pool
		alive = false
		return false

	# Move toward target's current position (light homing)
	if target != null and not target.is_dead():
		target_position = target.position
		var diff := target_position - position
		if diff.length() > 0:
			direction = diff.normalized()

	position += direction * speed

	# Check arrival (within 8px of target)
	var dist := position.distance_to(target_position)
	if dist <= 8.0:
		alive = false
		return false

	return true

# ─────────────────────────────────────────────────────────
# Check if projectile has reached its target
# ─────────────────────────────────────────────────────────
func has_arrived() -> bool:
	return not alive and ticks_alive > 0
