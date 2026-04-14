# test_campaign_ui.gd — Tests for the campaign UI flow
# BattleBrotts Sprint 11 · S11-001
extends RefCounted

var _CampaignUI = load("res://game/ui/campaign_ui.gd")
var _CampaignController = load("res://game/campaign/campaign_controller.gd")


func _make_campaign() -> CampaignController:
	var c = _CampaignController.new()
	c.new_game()
	return c


func test_campaign_ui_screen_enum() -> bool:
	# Verify all expected screens exist
	return _CampaignUI.Screen.MAIN_MENU == 0 \
		and _CampaignUI.Screen.SHOP == 1 \
		and _CampaignUI.Screen.LOADOUT == 2 \
		and _CampaignUI.Screen.OPPONENT_SELECT == 3 \
		and _CampaignUI.Screen.MATCH == 4 \
		and _CampaignUI.Screen.RESULT == 5


func test_campaign_new_game_initializes() -> bool:
	var c = _make_campaign()
	return c.economy.bolts == 200 and c.league.current_league == "scrapyard"


func test_campaign_shop_buy_updates_economy() -> bool:
	var c = _make_campaign()
	var result = c.buy_item("weapon", "shotgun")
	return result["success"] and c.economy.bolts == 80  # 200 - 120


func test_campaign_shop_catalog_has_items() -> bool:
	var c = _make_campaign()
	var catalog = c.get_shop_catalog("weapon")
	return catalog.size() == 7  # All weapons in the game


func test_campaign_loadout_set_and_get() -> bool:
	var c = _make_campaign()
	c.set_loadout("scout", ["minigun"], "plating", [])
	var lo = c.get_loadout()
	return lo["chassis"] == "scout" and lo["weapons"][0] == "minigun"


func test_campaign_opponent_info() -> bool:
	var c = _make_campaign()
	var info = c.get_opponent_info(0)
	return info["name"] == "Junkbot" and info["chassis"] == "scout"


func test_campaign_league_progress_initial() -> bool:
	var c = _make_campaign()
	var progress = c.get_league_progress()
	return progress["wins"] == 0 and progress["required"] == 3 and progress["opponents"].size() == 3


func test_campaign_full_match_flow() -> bool:
	var c = _make_campaign()
	c.set_loadout("brawler", ["minigun", "shotgun"], "plating", [])
	var result = c.start_match(0)
	if result.has("error"):
		return false
	var last = c.get_last_result()
	return last.has("won") and last.has("bolts_earned") and last.has("repair_cost")


func test_campaign_match_awards_bolts() -> bool:
	var c = _make_campaign()
	var starting_bolts = c.get_bolts()
	c.set_loadout("brawler", ["minigun", "shotgun"], "plating", [])
	c.start_match(0)
	# Bolts should change (earned - repair)
	return c.get_bolts() != starting_bolts


func test_campaign_win_tracks_progress() -> bool:
	var c = _make_campaign()
	c.set_loadout("fortress", ["minigun", "shotgun", "railgun"], "ablative_shell", [])
	# Give enough bolts to buy everything
	c.economy.add_bolts(10000)
	for wid in ["shotgun", "railgun"]:
		c.economy.purchase_item("weapon", wid)
	c.economy.purchase_item("chassis", "fortress")
	c.economy.purchase_item("armor", "ablative_shell")

	c.start_match(0)
	var last = c.get_last_result()
	if last["won"]:
		return c.league.has_beaten_opponent("scrapyard", 0)
	# Even if lost, test that progress was tracked
	return c.league.match_history.size() == 1


func test_campaign_result_has_opponent_name() -> bool:
	var c = _make_campaign()
	c.start_match(0)
	var last = c.get_last_result()
	return last["opponent_name"] == "Junkbot"


func test_campaign_rematch_runs_new_match() -> bool:
	var c = _make_campaign()
	c.start_match(0)
	var first_result = c.get_last_result()
	c.start_match(0)
	var second_result = c.get_last_result()
	# Both results should exist (may differ due to RNG)
	return first_result.has("won") and second_result.has("won")
