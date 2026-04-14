# campaign_ui.gd — Top-level UI controller for the full campaign loop
# BattleBrotts Sprint 11 · S11-001
#
# Main Menu → Shop → Loadout → Opponent Select → Match → Result → loop
# Wires CampaignController to UI screens.
class_name CampaignUI
extends Node

const _CampaignController = preload("res://game/campaign/campaign_controller.gd")

enum Screen { MAIN_MENU, SHOP, LOADOUT, OPPONENT_SELECT, MATCH, RESULT }

var campaign: CampaignController = null

# Simulation playback
var sim_ticks: Array = []
var sim_complete: bool = false

signal screen_changed(screen: Screen)
signal match_tick(tick_data: Dictionary)
signal match_finished(result: Dictionary)

# Scene references (set in _ready from scene tree)
var main_menu: Control = null
var shop_screen_ui: Control = null
var loadout_screen: Control = null
var opponent_screen: Control = null
var match_screen: Control = null
var result_screen: Control = null
var arena_view = null
var match_hud = null

var current_screen: Screen = Screen.MAIN_MENU


func _ready() -> void:
	campaign = _CampaignController.new()

	# Get screen references
	if has_node("CanvasLayer/MainMenu"):
		main_menu = $CanvasLayer/MainMenu
		shop_screen_ui = $CanvasLayer/ShopScreen
		loadout_screen = $CanvasLayer/LoadoutScreen
		opponent_screen = $CanvasLayer/OpponentSelect
		match_screen = $CanvasLayer/MatchScreen
		result_screen = $CanvasLayer/ResultScreen
		arena_view = $CanvasLayer/MatchScreen/ArenaView
		match_hud = $CanvasLayer/MatchScreen/HUD

		# Setup sub-screens with reference to us
		if shop_screen_ui.has_method("setup"):
			shop_screen_ui.setup(self)
		if opponent_screen.has_method("setup"):
			opponent_screen.setup(self)
		if result_screen:
			result_screen.campaign_ui = self

		# Connect loadout back button
		var back_btn = loadout_screen.get_node_or_null("BackButton")
		if back_btn:
			back_btn.pressed.connect(on_loadout_back)

		_show_screen(Screen.MAIN_MENU)


func _show_screen(screen: Screen) -> void:
	current_screen = screen
	if main_menu:
		main_menu.visible = (screen == Screen.MAIN_MENU)
	if shop_screen_ui:
		shop_screen_ui.visible = (screen == Screen.SHOP)
	if loadout_screen:
		loadout_screen.visible = (screen == Screen.LOADOUT)
	if opponent_screen:
		opponent_screen.visible = (screen == Screen.OPPONENT_SELECT)
	if match_screen:
		match_screen.visible = (screen == Screen.MATCH)
	if result_screen:
		result_screen.visible = (screen == Screen.RESULT)
	screen_changed.emit(screen)


# ── Main Menu ────────────────────────────────────────────
func on_new_game() -> void:
	campaign.new_game()
	_populate_shop()
	_show_screen(Screen.SHOP)


# ── Shop ─────────────────────────────────────────────────
func _populate_shop() -> void:
	if shop_screen_ui:
		shop_screen_ui.refresh(campaign)


func on_shop_continue() -> void:
	_populate_loadout()
	_show_screen(Screen.LOADOUT)


func on_shop_buy(item_type: String, item_id: String) -> Dictionary:
	var result := campaign.buy_item(item_type, item_id)
	if shop_screen_ui:
		shop_screen_ui.refresh(campaign)
	return result


# ── Loadout ──────────────────────────────────────────────
func _populate_loadout() -> void:
	if loadout_screen:
		loadout_screen.setup_campaign(self, campaign)


func on_loadout_fight() -> void:
	# Save loadout to campaign
	campaign.set_loadout(
		campaign.game_controller.player_chassis,
		campaign.game_controller.player_weapons,
		campaign.game_controller.player_armor,
		campaign.game_controller.player_modules,
	)
	_populate_opponent_select()
	_show_screen(Screen.OPPONENT_SELECT)


func on_loadout_back() -> void:
	_populate_shop()
	_show_screen(Screen.SHOP)


# ── Opponent Select ──────────────────────────────────────
func _populate_opponent_select() -> void:
	if opponent_screen:
		opponent_screen.refresh(campaign)


func on_opponent_selected(index: int) -> void:
	# Run the match
	var result := campaign.start_match(index)
	_show_result(result)


func on_opponent_back() -> void:
	_populate_loadout()
	_show_screen(Screen.LOADOUT)


# ── Match / Result ───────────────────────────────────────
func _show_result(match_result: Dictionary) -> void:
	if result_screen:
		var campaign_result := campaign.get_last_result()
		result_screen.show_campaign_result(campaign_result)
	_show_screen(Screen.RESULT)


func on_result_continue() -> void:
	if campaign.league.is_league_beaten(campaign.league.current_league):
		# League complete — could advance, for now go back to shop
		_populate_shop()
		_show_screen(Screen.SHOP)
	else:
		_populate_shop()
		_show_screen(Screen.SHOP)


func on_result_rematch() -> void:
	var result := campaign.start_match(campaign.selected_opponent_index)
	_show_result(result)


# ── Helpers ──────────────────────────────────────────────
func get_campaign() -> CampaignController:
	return campaign
