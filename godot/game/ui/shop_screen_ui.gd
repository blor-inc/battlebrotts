# shop_screen_ui.gd — Shop UI Control for the campaign flow
# BattleBrotts Sprint 11 · S11-001
#
# Displays item catalogs, prices, owned status, bolts balance.
# Uses ItemList nodes for each category.
extends Control

var campaign_ui = null  # CampaignUI reference
var campaign = null     # CampaignController
var selected_category: String = "weapon"

const CATEGORIES := ["chassis", "weapon", "armor", "module"]

@onready var title_label: Label = %ShopTitle
@onready var bolts_label: Label = %BoltsLabel
@onready var category_list: ItemList = %CategoryList
@onready var item_list: ItemList = %ShopItemList
@onready var buy_button: Button = %BuyButton
@onready var continue_button: Button = %ShopContinueButton
@onready var info_label: Label = %ShopInfoLabel


func setup(p_campaign_ui) -> void:
	campaign_ui = p_campaign_ui


func refresh(p_campaign) -> void:
	campaign = p_campaign
	_populate_categories()
	_populate_items()
	_update_bolts()


func _populate_categories() -> void:
	if not category_list:
		return
	category_list.clear()
	for cat in CATEGORIES:
		category_list.add_item(cat.capitalize())
	# Select current
	var idx := CATEGORIES.find(selected_category)
	if idx >= 0:
		category_list.select(idx)


func _populate_items() -> void:
	if not item_list or not campaign:
		return
	item_list.clear()
	var catalog: Array = campaign.get_shop_catalog(selected_category)
	for entry in catalog:
		var owned: bool = entry["owned"]
		var cost: int = entry["cost"]
		var name_str: String = entry["name"]
		var prefix := "✅ " if owned else ""
		var cost_str := "FREE" if cost == 0 else "%d 🔩" % cost
		if owned:
			cost_str = "OWNED"
		item_list.add_item("%s%s — %s" % [prefix, name_str, cost_str])
		item_list.set_item_metadata(item_list.item_count - 1, entry["id"])
		if owned:
			item_list.set_item_disabled(item_list.item_count - 1, true)


func _update_bolts() -> void:
	if bolts_label and campaign:
		bolts_label.text = "🔩 %d Bolts" % campaign.get_bolts()


func _on_category_selected(index: int) -> void:
	selected_category = CATEGORIES[index]
	_populate_items()


func _on_item_selected(_index: int) -> void:
	if buy_button:
		buy_button.disabled = false


func _on_buy_pressed() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var item_id: String = item_list.get_item_metadata(selected[0])
	var result: Dictionary = campaign_ui.on_shop_buy(selected_category, item_id)
	if result.get("success", false):
		if info_label:
			info_label.text = "Purchased!"
	else:
		if info_label:
			info_label.text = "Cannot buy: %s" % result.get("reason", "unknown")
	_populate_items()
	_update_bolts()


func _on_continue_pressed() -> void:
	campaign_ui.on_shop_continue()
