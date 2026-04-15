# weapon_data.gd — Weapon definitions from GDD v2 §3.2
# BattleBrotts Core Combat · S1-003
class_name WeaponData

const WEAPONS := {
	"minigun": {
		"name": "Minigun",
		"damage": 3,
		"pellets": 1,
		"range": 5,
		"fire_rate": 10.0,
		"spread": 15.0,
		"energy_cost": 2,
		"weight": 10,
		"splash_radius": 0,
		"chain_targets": 0,
	},
	"railgun": {
		"name": "Railgun",
		"damage": 45,
		"pellets": 1,
		"range": 12,
		"fire_rate": 0.6,
		"spread": 0.0,
		"energy_cost": 16,
		"weight": 15,
		"splash_radius": 0,
		"chain_targets": 0,
	},
	"shotgun": {
		"name": "Shotgun",
		"damage": 6,
		"pellets": 5,
		"range": 3,
		"fire_rate": 1.5,
		"spread": 30.0,
		"energy_cost": 8,
		"weight": 12,
		"splash_radius": 0,
		"chain_targets": 0,
	},
	"missile_pod": {
		"name": "Missile Pod",
		"damage": 30,
		"pellets": 1,
		"range": 8,
		"fire_rate": 0.8,
		"spread": 5.0,
		"energy_cost": 12,
		"weight": 18,
		"splash_radius": 1,
		"chain_targets": 0,
	},
	"plasma_cutter": {
		"name": "Plasma Cutter",
		"damage": 12,
		"pellets": 1,
		"range": 1.5,
		"fire_rate": 3.0,
		"spread": 0.0,
		"energy_cost": 4,
		"weight": 8,
		"splash_radius": 0,
		"chain_targets": 0,
	},
	"arc_emitter": {
		"name": "Arc Emitter",
		"damage": 8,
		"pellets": 1,
		"range": 4,
		"fire_rate": 2.0,
		"spread": 10.0,
		"energy_cost": 6,
		"weight": 11,
		"splash_radius": 0,
		"chain_targets": 1,
		"chain_range": 2,
	},
	"flak_cannon": {
		"name": "Flak Cannon",
		"damage": 15,
		"pellets": 1,
		"range": 6,
		"fire_rate": 1.2,
		"spread": 20.0,
		"energy_cost": 7,
		"weight": 13,
		"splash_radius": 0,
		"chain_targets": 0,
	},
}

static func fire_interval_ticks(weapon_id: String) -> int:
	var w := get_weapon(weapon_id)
	return int(ceil(20.0 / w["fire_rate"]))

static func get_weapon(id: String) -> Dictionary:
	assert(WEAPONS.has(id), "Unknown weapon: %s" % id)
	return WEAPONS[id]

static func list_ids() -> Array:
	return WEAPONS.keys()
