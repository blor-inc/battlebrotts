# test_league.gd — Tests for LeagueManager
# BattleBrotts Sprint 5 · S5-003
extends RefCounted

const LeagueManager = preload("res://game/progression/league_manager.gd")

func _make_league() -> LeagueManager:
	return LeagueManager.new()

# ── Initial State ────────────────────────────────────────

func test_starts_at_scrapyard() -> bool:
	var lm := _make_league()
	return lm.current_league == "scrapyard"

func test_scrapyard_unlocked() -> bool:
	var lm := _make_league()
	return lm.is_league_unlocked("scrapyard")

func test_bronze_locked_initially() -> bool:
	var lm := _make_league()
	return not lm.is_league_unlocked("bronze")

# ── Scrapyard Opponents ─────────────────────────────────

func test_scrapyard_has_3_opponents() -> bool:
	var lm := _make_league()
	return lm.get_opponents("scrapyard").size() == 3

func test_opponent_1_scout_minigun() -> bool:
	var lm := _make_league()
	var opp := lm.get_opponent("scrapyard", 0)
	return opp["chassis"] == "scout" and opp["weapons"] == ["minigun"] \
		and opp["stance"] == "aggressive" and opp["behavior_cards"].size() == 0

func test_opponent_2_scout_plasma_plating() -> bool:
	var lm := _make_league()
	var opp := lm.get_opponent("scrapyard", 1)
	return opp["chassis"] == "scout" and opp["weapons"] == ["plasma_cutter"] \
		and opp["armor"] == "plating" and opp["stance"] == "aggressive"

func test_opponent_3_brawler_minigun_shotgun() -> bool:
	var lm := _make_league()
	var opp := lm.get_opponent("scrapyard", 2)
	return opp["chassis"] == "brawler" and opp["weapons"] == ["minigun", "shotgun"] \
		and opp["stance"] == "aggressive"

# ── Match Recording ──────────────────────────────────────

func test_record_win() -> bool:
	var lm := _make_league()
	var result := lm.record_match("scrapyard", 0, true)
	return result["recorded"] and result["first_win"]

func test_record_loss() -> bool:
	var lm := _make_league()
	var result := lm.record_match("scrapyard", 0, false)
	return result["recorded"] and not result["first_win"]

func test_repeat_win_not_first() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	var result := lm.record_match("scrapyard", 0, true)
	return result["recorded"] and not result["first_win"]

func test_has_beaten_opponent() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	return lm.has_beaten_opponent("scrapyard", 0) \
		and not lm.has_beaten_opponent("scrapyard", 1)

# ── League Progression ───────────────────────────────────

func test_scrapyard_not_beaten_with_2_wins() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	lm.record_match("scrapyard", 1, true)
	return not lm.is_league_beaten("scrapyard")

func test_scrapyard_beaten_with_3_wins() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	lm.record_match("scrapyard", 1, true)
	var result := lm.record_match("scrapyard", 2, true)
	return lm.is_league_beaten("scrapyard") and result["league_beaten"]

func test_bronze_unlocks_after_scrapyard() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	lm.record_match("scrapyard", 1, true)
	var result := lm.record_match("scrapyard", 2, true)
	return result["advanced_to"] == "bronze" and lm.is_league_unlocked("bronze")

func test_bronze_not_unlocked_with_losses() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	lm.record_match("scrapyard", 1, false)
	lm.record_match("scrapyard", 2, true)
	return not lm.is_league_unlocked("bronze")

# ── Progress Queries ─────────────────────────────────────

func test_league_progress() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	lm.record_match("scrapyard", 2, true)
	var prog := lm.get_league_progress("scrapyard")
	return prog["wins"] == 2 and prog["total"] == 3 and prog["required"] == 3 \
		and not prog["beaten"]

func test_next_opponent_index() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	return lm.get_next_opponent_index("scrapyard") == 1

func test_next_opponent_all_beaten() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	lm.record_match("scrapyard", 1, true)
	lm.record_match("scrapyard", 2, true)
	return lm.get_next_opponent_index("scrapyard") == -1

func test_win_loss_record() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	lm.record_match("scrapyard", 0, false)
	lm.record_match("scrapyard", 1, true)
	var record := lm.get_win_loss_record()
	return record["wins"] == 2 and record["losses"] == 1

# ── Save/Load ────────────────────────────────────────────

func test_save_load_roundtrip() -> bool:
	var lm := _make_league()
	lm.record_match("scrapyard", 0, true)
	lm.record_match("scrapyard", 1, true)
	lm.record_match("scrapyard", 2, true)
	var data := lm.to_dict()

	var lm2 := LeagueManager.new()
	lm2.from_dict(data)
	return lm2.is_league_unlocked("bronze") and lm2.is_league_beaten("scrapyard") \
		and lm2.match_history.size() == 3
