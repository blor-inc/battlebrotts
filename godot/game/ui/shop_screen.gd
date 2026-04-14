# shop_screen.gd — Shop UI for browsing and buying items
# BattleBrotts Sprint 6 · S6-001
#
# Displays item catalogs by type, shows prices, owned status, and Bolts balance.
# Wires to CampaignController for purchases.
class_name ShopScreen

# ── Signals ──────────────────────────────────────────────
signal item_purchased(item_type: String, item_id: String)
signal continue_pressed()

# ── State ────────────────────────────────────────────────
var campaign = null  # CampaignController
var selected_category: String = "weapon"

const CATEGORIES := ["chassis", "weapon", "armor", "module"]

# ─────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────
func setup(campaign_controller) -> void:
	campaign = campaign_controller


func get_display_data() -> Dictionary:
	"""Returns all data needed to render the shop screen."""
	var catalog: Array = campaign.get_shop_catalog(selected_category)
	var bolts: int = campaign.get_bolts()
	var owned: Array = campaign.get_owned_items(selected_category)

	return {
		"bolts": bolts,
		"category": selected_category,
		"categories": CATEGORIES,
		"items": catalog,
		"owned_count": owned.size(),
	}


func select_category(category: String) -> void:
	if category in CATEGORIES:
		selected_category = category


func try_buy(item_id: String) -> Dictionary:
	"""Attempt to buy an item. Returns purchase result."""
	var result: Dictionary = campaign.buy_item(selected_category, item_id)
	if result["success"]:
		item_purchased.emit(selected_category, item_id)
	return result


func done_shopping() -> void:
	"""Player is done shopping, move to next phase."""
	continue_pressed.emit()
