# shop.gd — Shop system for purchasing items
# BattleBrotts Sprint 5 · S5-003
#
# Buy chassis, weapons, armor, modules at GDD v2 prices.
# Wraps EconomyManager purchase logic with catalog browsing.
class_name Shop

const _EconomyManager = preload("res://game/economy/economy_manager.gd")

# ── Signals ──────────────────────────────────────────────
signal purchase_completed(item_type: String, item_id: String, cost: int)
signal purchase_failed(item_type: String, item_id: String, reason: String)

# ── State ────────────────────────────────────────────────
var economy = null

# ─────────────────────────────────────────────────────────
# Init
# ─────────────────────────────────────────────────────────
func _init(economy_manager = null) -> void:
	if economy_manager:
		economy = economy_manager
	else:
		economy = _EconomyManager.new()


func set_economy(economy_manager) -> void:
	economy = economy_manager

# ─────────────────────────────────────────────────────────
# Catalog
# ─────────────────────────────────────────────────────────
func get_catalog(item_type: String) -> Array:
	"""Returns array of { id, name, cost, owned, data } for all items of type."""
	var items := []
	var all_ids: Array = economy.get_all_items(item_type)
	for id in all_ids:
		var entry := {
			"id": id,
			"cost": economy.get_item_cost(item_type, id),
			"owned": economy.owns_item(item_type, id),
		}
		# Attach item data
		match item_type:
			"chassis":
				entry["data"] = ChassisData.get_chassis(id)
			"weapon":
				entry["data"] = WeaponData.get_weapon(id)
			"armor":
				entry["data"] = ArmorData.get_armor(id)
			"module":
				entry["data"] = ModuleData.get_module(id)
		entry["name"] = entry["data"].get("name", id)
		items.append(entry)
	return items


func get_purchasable(item_type: String) -> Array:
	"""Returns catalog filtered to items not yet owned."""
	var catalog := get_catalog(item_type)
	return catalog.filter(func(e): return not e["owned"])

# ─────────────────────────────────────────────────────────
# Purchase
# ─────────────────────────────────────────────────────────
func buy(item_type: String, item_id: String) -> Dictionary:
	"""Buy an item. Returns { success, reason, cost }."""
	var cost: int = economy.get_item_cost(item_type, item_id)
	var result: Dictionary = economy.purchase_item(item_type, item_id)
	if result["success"]:
		purchase_completed.emit(item_type, item_id, maxi(cost, 0))
	else:
		purchase_failed.emit(item_type, item_id, result["reason"])
	result["cost"] = maxi(cost, 0)
	return result

# ─────────────────────────────────────────────────────────
# Queries
# ─────────────────────────────────────────────────────────
func can_buy(item_type: String, item_id: String) -> bool:
	if economy.owns_item(item_type, item_id):
		return false
	var cost: int = economy.get_item_cost(item_type, item_id)
	if cost < 0:
		return false
	if cost == 0:
		return true
	return economy.can_afford(cost)


func get_player_bolts() -> int:
	return economy.bolts
