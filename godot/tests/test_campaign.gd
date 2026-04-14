# test_campaign.gd — Integration tests for the full campaign loop
# BattleBrotts Sprint 6 · S6-001
extends RefCounted

func _cc():
	return load("res://game/campaign/campaign_controller.gd")

func _make():
	var c = _cc().new()
	c.new_game()
	return c

# ── New Game ─────────────────────────────────────────────

func test_new_game_starts_at_shop() -> bool:
	var c = _make()
	return c.current_phase == _cc().Phase.SHOP

func test_new_game_scrapyard_league() -> bool:
	var c = _make()
	return c.league.current_league == "scrapyard"

func test_starting_bolts_200() -> bool:
	var c = _make()
	return c.get_bolts() == 200

func test_starter_chassis() -> bool:
	var c = _make()
	return "scout" in c.get_owned_items("chassis")

func test_starter_weapons() -> bool:
	var c = _make()
	var w = c.get_owned_items("weapon")
	return "minigun" in w and "plasma_cutter" in w

func test_starter_armor() -> bool:
	var c = _make()
	return "plating" in c.get_owned_items("armor")

func test_default_loadout() -> bool:
	var c = _make()
	var lo = c.get_loadout()
	return lo["chassis"] == "scout" and lo["weapons"] == ["minigun"] and lo["armor"] == "plating"

# ── Shop ─────────────────────────────────────────────────

func test_buy_shotgun() -> bool:
	var c = _make()
	var r = c.buy_item("weapon", "shotgun")
	return r["success"] and c.get_bolts() == 80 and "shotgun" in c.get_owned_items("weapon")

func test_cannot_afford_railgun() -> bool:
	var c = _make()
	var r = c.buy_item("weapon", "railgun")
	return not r["success"] and r["reason"] == "insufficient_bolts"

func test_cannot_rebuy_minigun() -> bool:
	var c = _make()
	var r = c.buy_item("weapon", "minigun")
	return not r["success"] and r["reason"] == "already_owned"

# ── Loadout ──────────────────────────────────────────────

func test_set_and_get_loadout() -> bool:
	var c = _make()
	c.set_loadout("scout", ["minigun", "plasma_cutter"], "plating", [])
	var lo = c.get_loadout()
	return lo["weapons"].size() == 2 and lo["chassis"] == "scout"

func test_validate_no_weapons() -> bool:
	var c = _make()
	c.set_loadout("scout", [], "plating", [])
	return not c.validate_loadout()["valid"]

# ── Opponents ────────────────────────────────────────────

func test_first_opponent_junkbot() -> bool:
	var c = _make()
	return c.get_opponent_info(0)["name"] == "Junkbot"

func test_league_progress_initial() -> bool:
	var c = _make()
	var p = c.get_league_progress()
	return p["wins"] == 0 and p["total"] == 3 and not p["beaten"]

func test_opponent_not_beaten_initially() -> bool:
	var c = _make()
	return not c.has_beaten_opponent(0)

# ── Rewards ──────────────────────────────────────────────

func test_win_reward_at_least_100() -> bool:
	var c = _make()
	var earned = c.economy.award_match_result(true, "scrapyard_0")
	return earned >= 100

func test_loss_reward_40() -> bool:
	var c = _make()
	return c.economy.award_match_result(false, "scrapyard_0") == 40

func test_first_win_bonus() -> bool:
	var c = _make()
	var first = c.economy.award_match_result(true, "test_opp")
	var second = c.economy.award_match_result(true, "test_opp")
	return first == 150 and second == 100

# ── League Completion ────────────────────────────────────

func test_league_beaten_after_3_wins() -> bool:
	var c = _make()
	c.league.record_match("scrapyard", 0, true)
	c.league.record_match("scrapyard", 1, true)
	c.league.record_match("scrapyard", 2, true)
	return c.league.is_league_beaten("scrapyard")

func test_bronze_unlocked_after_scrapyard() -> bool:
	var c = _make()
	c.league.record_match("scrapyard", 0, true)
	c.league.record_match("scrapyard", 1, true)
	c.league.record_match("scrapyard", 2, true)
	return c.league.is_league_unlocked("bronze")

func test_partial_progress() -> bool:
	var c = _make()
	c.league.record_match("scrapyard", 0, true)
	c.league.record_match("scrapyard", 1, false)
	c.league.record_match("scrapyard", 1, true)
	var p = c.get_league_progress()
	return p["wins"] == 2 and not p["beaten"]

# ── Save/Load ────────────────────────────────────────────

func test_save_load_roundtrip() -> bool:
	var c = _make()
	c.buy_item("weapon", "shotgun")
	c.league.record_match("scrapyard", 0, true)
	var saved = c.to_dict()

	var c2 = _cc().new()
	c2.from_dict(saved)
	return (c2.get_bolts() == c.get_bolts()
		and "shotgun" in c2.get_owned_items("weapon")
		and c2.league.has_beaten_opponent("scrapyard", 0))

# ── UI Screens ───────────────────────────────────────────

func test_shop_screen_data() -> bool:
	var c = _make()
	var ss = load("res://game/ui/shop_screen.gd").new()
	ss.setup(c)
	var data = ss.get_display_data()
	return data["bolts"] == 200 and data["items"].size() > 0 and data["category"] == "weapon"

func test_opponent_select_data() -> bool:
	var c = _make()
	var os = load("res://game/ui/opponent_select.gd").new()
	os.setup(c)
	var data = os.get_display_data()
	return data["league_name"] == "Scrapyard" and data["opponents"].size() == 3

func test_repair_costs_scale() -> bool:
	var c = _make()
	var cheap = c.economy.calc_repair_cost(
		c.economy.calc_equipment_value(["minigun"], "plating", []), true)
	var expensive = c.economy.calc_repair_cost(
		c.economy.calc_equipment_value(["minigun"], "plating", ["overclock", "sensor_array"]), true)
	return expensive > cheap
