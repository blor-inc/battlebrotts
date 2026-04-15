# chassis_data.gd — Chassis definitions from GDD v2 §3.1
# BattleBrotts Core Combat · S1-003
class_name ChassisData

const CHASSIS := {
	"scout": {
		"name": "Scout",
		"hp": 100,
		"speed": 220,
		"weight_cap": 30,
		"weapon_slots": 1,
		"module_slots": 3,
	},
	"brawler": {
		"name": "Brawler",
		"hp": 150,
		"speed": 120,
		"weight_cap": 55,
		"weapon_slots": 2,
		"module_slots": 2,
	},
	"fortress": {
		"name": "Fortress",
		"hp": 210,
		"speed": 60,
		"weight_cap": 80,
		"weapon_slots": 3,
		"module_slots": 1,
	},
}

static func get_chassis(id: String) -> Dictionary:
	assert(CHASSIS.has(id), "Unknown chassis: %s" % id)
	return CHASSIS[id]

static func list_ids() -> Array:
	return CHASSIS.keys()
