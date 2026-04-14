# armor_data.gd — Armor definitions from GDD v2 §3.3
# BattleBrotts Core Combat · S1-003
class_name ArmorData

# Only one armor equipped at a time. No slot cost, counts against weight.

const ARMOR := {
	"plating": {
		"name": "Plating",
		"damage_reduction": 0.20,
		"weight": 15,
		"special": "none",
	},
	"reactive_mesh": {
		"name": "Reactive Mesh",
		"damage_reduction": 0.10,
		"weight": 8,
		"special": "reflect",    # 5 flat damage back to attacker, ignores attacker armor
		"reflect_damage": 5,
	},
	"ablative_shell": {
		"name": "Ablative Shell",
		"damage_reduction": 0.40,
		"weight": 25,
		"special": "ablative",   # reduction drops to 10% below 30% HP
		"reduced_threshold": 0.30,
		"reduced_damage_reduction": 0.10,
	},
}

## Returns effective damage reduction for this armor given the wearer's HP ratio.
static func effective_reduction(armor_id: String, hp_ratio: float) -> float:
	if armor_id == "" or armor_id == "none":
		return 0.0
	var a := get_armor(armor_id)
	if a["special"] == "ablative" and hp_ratio < a["reduced_threshold"]:
		return a["reduced_damage_reduction"]
	return a["damage_reduction"]

static func get_armor(id: String) -> Dictionary:
	assert(ARMOR.has(id), "Unknown armor: %s" % id)
	return ARMOR[id]

static func list_ids() -> Array:
	return ARMOR.keys()
