# economy_manager.gd — Bolts currency tracking, earn/spend/repair
# BattleBrotts Sprint 5 · S5-003
#
# Single currency: Bolts (🔩). Tracks balance, purchases, repair costs.
# All item prices from GDD v2 §7.
class_name EconomyManager

# ── Signals ──────────────────────────────────────────────
signal bolts_changed(new_amount: int)
signal item_purchased(item_type: String, item_id: String)
signal repair_paid(cost: int)

# ── Constants ────────────────────────────────────────────
const BOLTS_WIN: int = 100
const BOLTS_LOSS: int = 40
const BOLTS_FIRST_WIN: int = 150

const REPAIR_RATE_WIN: float = 0.10
const REPAIR_RATE_LOSS: float = 0.25

const STARTER_ITEMS := {
	"chassis": ["scout"],
	"weapon": ["minigun", "plasma_cutter"],
	"armor": ["plating"],
	"module": [],
}

const ITEM_COSTS := {
	"chassis": {
		"scout": 0,
		"brawler": 200,
		"fortress": 400,
	},
	"weapon": {
		"minigun": 0,
		"plasma_cutter": 0,
		"shotgun": 120,
		"arc_emitter": 150,
		"flak_cannon": 200,
		"railgun": 300,
		"missile_pod": 350,
	},
	"armor": {
		"plating": 0,
		"reactive_mesh": 150,
		"ablative_shell": 300,
	},
	"module": {
		"overclock": 100,
		"repair_nanites": 120,
		"sensor_array": 150,
		"afterburner": 180,
		"shield_projector": 200,
		"emp_charge": 250,
	},
}

# ── State ────────────────────────────────────────────────
var bolts: int = 0
var owned_items: Dictionary = {}  # { "chassis": ["scout"], "weapon": [...], ... }
var first_wins: Dictionary = {}   # { "opponent_id": true } — tracks first-time victories

# ─────────────────────────────────────────────────────────
# Init
# ─────────────────────────────────────────────────────────
func _init() -> void:
	reset()


func reset() -> void:
	bolts = 0
	first_wins = {}
	owned_items = {
		"chassis": STARTER_ITEMS["chassis"].duplicate(),
		"weapon": STARTER_ITEMS["weapon"].duplicate(),
		"armor": STARTER_ITEMS["armor"].duplicate(),
		"module": STARTER_ITEMS["module"].duplicate(),
	}

# ─────────────────────────────────────────────────────────
# Currency
# ─────────────────────────────────────────────────────────
func add_bolts(amount: int) -> void:
	bolts += amount
	bolts_changed.emit(bolts)


func spend_bolts(amount: int) -> bool:
	if amount > bolts:
		return false
	bolts -= amount
	bolts_changed.emit(bolts)
	return true


func can_afford(amount: int) -> bool:
	return bolts >= amount

# ─────────────────────────────────────────────────────────
# Match rewards
# ─────────────────────────────────────────────────────────
func award_match_result(won: bool, opponent_id: String) -> int:
	"""Awards bolts for match result. Returns total bolts earned."""
	var earned: int = 0
	if won:
		earned = BOLTS_WIN
		if not first_wins.has(opponent_id):
			first_wins[opponent_id] = true
			earned = BOLTS_FIRST_WIN
	else:
		earned = BOLTS_LOSS
	add_bolts(earned)
	return earned

# ─────────────────────────────────────────────────────────
# Repair
# ─────────────────────────────────────────────────────────
func calc_repair_cost(equipment_value: int, won: bool) -> int:
	var rate := REPAIR_RATE_WIN if won else REPAIR_RATE_LOSS
	return int(ceil(float(equipment_value) * rate))


func calc_equipment_value(weapons: Array, armor_id: String, modules: Array) -> int:
	"""Sum of purchase prices for all equipped items (excluding chassis)."""
	var total: int = 0
	for wid in weapons:
		if ITEM_COSTS["weapon"].has(wid):
			total += ITEM_COSTS["weapon"][wid]
	if armor_id != "" and ITEM_COSTS["armor"].has(armor_id):
		total += ITEM_COSTS["armor"][armor_id]
	for mid in modules:
		if ITEM_COSTS["module"].has(mid):
			total += ITEM_COSTS["module"][mid]
	return total


func pay_repair(weapons: Array, armor_id: String, modules: Array, won: bool) -> Dictionary:
	"""Pay repair cost. Returns { cost: int, paid: bool }."""
	var value := calc_equipment_value(weapons, armor_id, modules)
	var cost := calc_repair_cost(value, won)
	if cost == 0:
		repair_paid.emit(0)
		return {"cost": 0, "paid": true}
	var paid := spend_bolts(cost)
	if paid:
		repair_paid.emit(cost)
	return {"cost": cost, "paid": paid}

# ─────────────────────────────────────────────────────────
# Shop / Ownership
# ─────────────────────────────────────────────────────────
func owns_item(item_type: String, item_id: String) -> bool:
	if not owned_items.has(item_type):
		return false
	return item_id in owned_items[item_type]


func get_item_cost(item_type: String, item_id: String) -> int:
	if not ITEM_COSTS.has(item_type):
		return -1
	if not ITEM_COSTS[item_type].has(item_id):
		return -1
	return ITEM_COSTS[item_type][item_id]


func purchase_item(item_type: String, item_id: String) -> Dictionary:
	"""Attempt to buy an item. Returns { success: bool, reason: String }."""
	if owns_item(item_type, item_id):
		return {"success": false, "reason": "already_owned"}

	var cost := get_item_cost(item_type, item_id)
	if cost < 0:
		return {"success": false, "reason": "invalid_item"}
	if cost == 0:
		# Free item — just add it
		owned_items[item_type].append(item_id)
		item_purchased.emit(item_type, item_id)
		return {"success": true, "reason": "free"}
	if not can_afford(cost):
		return {"success": false, "reason": "insufficient_bolts"}

	spend_bolts(cost)
	owned_items[item_type].append(item_id)
	item_purchased.emit(item_type, item_id)
	return {"success": true, "reason": "purchased"}


func get_owned_items(item_type: String) -> Array:
	if not owned_items.has(item_type):
		return []
	return owned_items[item_type].duplicate()


func get_all_items(item_type: String) -> Array:
	"""Returns all item IDs of a given type."""
	if not ITEM_COSTS.has(item_type):
		return []
	return ITEM_COSTS[item_type].keys()

# ─────────────────────────────────────────────────────────
# Save / Load
# ─────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"bolts": bolts,
		"owned_items": owned_items.duplicate(true),
		"first_wins": first_wins.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	bolts = data.get("bolts", 0)
	owned_items = data.get("owned_items", {}).duplicate(true)
	first_wins = data.get("first_wins", {}).duplicate(true)
	# Ensure all types exist
	for t in ["chassis", "weapon", "armor", "module"]:
		if not owned_items.has(t):
			owned_items[t] = STARTER_ITEMS[t].duplicate()
