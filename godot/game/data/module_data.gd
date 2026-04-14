# module_data.gd — Module definitions from GDD v2 §3.4
# BattleBrotts Core Combat · S1-003
class_name ModuleData

const MODULES := {
	"overclock": {
		"name": "Overclock",
		"weight": 5,
		"passive": false,
		"activated": true,
		"effect": "fire_rate_boost",
		"boost_amount": 0.30,         # +30% fire rate
		"boost_duration_sec": 4.0,
		"penalty_amount": -0.20,      # -20% fire rate during cooldown
		"penalty_duration_sec": 3.0,
		"cooldown_sec": 7.0,          # 4s active + 3s penalty = 7s total cycle
	},
	"repair_nanites": {
		"name": "Repair Nanites",
		"weight": 7,
		"passive": true,
		"activated": false,
		"effect": "heal_per_tick",
		"heal_per_tick": 0.15,        # 3 HP/sec ÷ 20 ticks = 0.15 HP/tick
	},
	"shield_projector": {
		"name": "Shield Projector",
		"weight": 10,
		"passive": false,
		"activated": true,
		"effect": "absorb_shield",
		"shield_hp": 40,
		"duration_sec": 5.0,
		"cooldown_sec": 20.0,
	},
	"sensor_array": {
		"name": "Sensor Array",
		"weight": 4,
		"passive": true,
		"activated": false,
		"effect": "sight_range_boost",
		"sight_bonus_tiles": 3,
		"reveals_cover": true,
	},
	"afterburner": {
		"name": "Afterburner",
		"weight": 6,
		"passive": false,
		"activated": true,
		"effect": "speed_boost",
		"speed_multiplier": 1.80,     # +80% move speed
		"duration_sec": 2.0,
		"cooldown_sec": 12.0,
	},
	"emp_charge": {
		"name": "EMP Charge",
		"weight": 9,
		"passive": false,
		"activated": true,
		"effect": "disable_modules",
		"disable_duration_sec": 3.0,
		"range_tiles": 4,
		"cooldown_sec": 25.0,
	},
}

static func get_module(id: String) -> Dictionary:
	assert(MODULES.has(id), "Unknown module: %s" % id)
	return MODULES[id]

static func list_ids() -> Array:
	return MODULES.keys()
