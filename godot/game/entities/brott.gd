# brott.gd — Brott entity: runtime state for one combatant
# BattleBrotts Core Combat · S1-003
class_name Brott

# ── Identity ─────────────────────────────────────────────
var id: int = 0
var team: int = 0            # 0 = player, 1 = enemy

# ── Chassis stats (copied from ChassisData at spawn) ────
var chassis_id: String = ""
var max_hp: float = 0.0
var speed: float = 0.0       # px/s
var weight_cap: float = 0.0

# ── Runtime state ────────────────────────────────────────
var hp: float = 0.0
var energy: float = 100.0
var alive: bool = true

# ── Position / movement ──────────────────────────────────
var position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO  # next movement goal

# ── Equipment ────────────────────────────────────────────
var weapon_ids: Array = []   # e.g. ["minigun", "shotgun"]
var armor_id: String = ""    # "" means no armor
var module_ids: Array = []   # e.g. ["repair_nanites", "overclock"]

# ── Weapon cooldown tracking (ticks remaining until next shot) ─
var weapon_cooldowns: Array = []  # parallel to weapon_ids, int ticks

# ── Module runtime state ─────────────────────────────────
# Keyed by module_id → Dictionary with runtime fields
# e.g. { "cooldown_ticks": 0, "active_ticks": 0, "shield_hp": 0 ... }
var module_states: Dictionary = {}

# ── Shield (from Shield Projector) ───────────────────────
var shield_hp: float = 0.0

# ── Targeting ────────────────────────────────────────────
var target: Brott = null     # current combat target

# ── Constants ────────────────────────────────────────────
const MAX_ENERGY: float = 100.0
const ENERGY_REGEN_PER_TICK: float = 0.25  # 5/sec ÷ 20 ticks

# ─────────────────────────────────────────────────────────
# Factory: create a Brott from a chassis id and loadout
# ─────────────────────────────────────────────────────────
static func create(brott_id: int, team_id: int, chassis: String,
		weapons: Array, armor: String, modules: Array,
		start_pos: Vector2) -> Brott:
	var b := Brott.new()
	b.id = brott_id
	b.team = team_id

	var c := ChassisData.get_chassis(chassis)
	b.chassis_id = chassis
	b.max_hp = float(c["hp"])
	b.hp = b.max_hp
	b.speed = float(c["speed"])
	b.weight_cap = float(c["weight_cap"])

	b.weapon_ids = weapons.duplicate()
	b.armor_id = armor
	b.module_ids = modules.duplicate()

	# Validate weight
	var total_weight := 0.0
	for wid in weapons:
		total_weight += WeaponData.get_weapon(wid)["weight"]
	if armor != "":
		total_weight += ArmorData.get_armor(armor)["weight"]
	for mid in modules:
		total_weight += ModuleData.get_module(mid)["weight"]
	assert(total_weight <= b.weight_cap,
		"Loadout weight %.1f exceeds cap %.1f" % [total_weight, b.weight_cap])

	# Init weapon cooldowns (ready to fire immediately)
	b.weapon_cooldowns = []
	for i in weapons.size():
		b.weapon_cooldowns.append(0)

	# Init module states
	for mid in modules:
		b.module_states[mid] = {
			"cooldown_ticks": 0,
			"active_ticks": 0,
			"shield_hp": 0.0,
		}

	b.position = start_pos
	b.target_position = start_pos
	b.energy = MAX_ENERGY

	return b

# ─────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────
func hp_ratio() -> float:
	if max_hp <= 0.0:
		return 0.0
	return hp / max_hp

func is_dead() -> bool:
	return not alive

func apply_damage(amount: float) -> void:
	if not alive:
		return
	# Shield absorbs first
	if shield_hp > 0.0:
		var absorbed := minf(shield_hp, amount)
		shield_hp -= absorbed
		amount -= absorbed
	hp = maxf(hp - amount, 0.0)
	if hp <= 0.0:
		alive = false

func apply_heal(amount: float) -> void:
	if not alive:
		return
	hp = minf(hp + amount, max_hp)

func spend_energy(amount: float) -> bool:
	if energy >= amount:
		energy -= amount
		return true
	return false

func regen_energy() -> void:
	energy = minf(energy + ENERGY_REGEN_PER_TICK, MAX_ENERGY)

## Distance in tiles (32 px per tile)
func distance_to_brott(other: Brott) -> float:
	return position.distance_to(other.position) / 32.0
