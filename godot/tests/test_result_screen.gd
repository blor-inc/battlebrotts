# test_result_screen.gd — Tests for ResultScreen logic paths
# BattleBrotts Sprint 5 · S5-002
#
# Tests outcome display mapping, stats formatting, team details,
# and rematch/loadout action flows.
extends RefCounted

# ── Outcome display mapping ──

func _outcome_text(outcome: String) -> String:
	match outcome:
		"team_a_wins":
			return "🏆 VICTORY!"
		"team_b_wins":
			return "💀 DEFEAT"
		"draw", "timeout_draw":
			return "🤝 DRAW"
		"timeout_team_a_advantage":
			return "⏱️ TIME'S UP — YOU WIN!"
		"timeout_team_b_advantage":
			return "⏱️ TIME'S UP — YOU LOSE"
		_:
			return outcome.to_upper()

func test_outcome_victory() -> bool:
	return _outcome_text("team_a_wins") == "🏆 VICTORY!"

func test_outcome_defeat() -> bool:
	return _outcome_text("team_b_wins") == "💀 DEFEAT"

func test_outcome_draw() -> bool:
	return _outcome_text("draw") == "🤝 DRAW"

func test_outcome_timeout_draw() -> bool:
	return _outcome_text("timeout_draw") == "🤝 DRAW"

func test_outcome_timeout_win() -> bool:
	return _outcome_text("timeout_team_a_advantage") == "⏱️ TIME'S UP — YOU WIN!"

func test_outcome_timeout_lose() -> bool:
	return _outcome_text("timeout_team_b_advantage") == "⏱️ TIME'S UP — YOU LOSE"

func test_outcome_unknown_uppercased() -> bool:
	return _outcome_text("something_weird") == "SOMETHING_WEIRD"

# ── Stats formatting ──

func _format_stats(result: Dictionary) -> String:
	var duration: float = result.get("duration_sec", 0.0)
	var ticks: int = result.get("ticks", 0)
	return "Duration: %d:%02d (%d ticks) · Seed: %d" % [
		int(duration) / 60, int(duration) % 60, ticks, result.get("seed", 0)
	]

func test_stats_format_short_match() -> bool:
	var r := {"duration_sec": 15.0, "ticks": 300, "seed": 42}
	return _format_stats(r) == "Duration: 0:15 (300 ticks) · Seed: 42"

func test_stats_format_full_match() -> bool:
	var r := {"duration_sec": 120.0, "ticks": 2400, "seed": 12345}
	return _format_stats(r) == "Duration: 2:00 (2400 ticks) · Seed: 12345"

func test_stats_format_zero() -> bool:
	var r := {}
	return _format_stats(r) == "Duration: 0:00 (0 ticks) · Seed: 0"

func test_stats_format_partial_time() -> bool:
	var r := {"duration_sec": 73.5, "ticks": 1470, "seed": 999}
	return _format_stats(r) == "Duration: 1:13 (1470 ticks) · Seed: 999"

# ── Team details display ──

func _format_details(team_stats: Dictionary) -> String:
	var details := ""
	if team_stats.has(0):
		var t = team_stats[0]
		details += "Your Brott: %.0f HP remaining, %d alive\n" % [
			t["hp_remaining"], t["brotts_alive"]
		]
	if team_stats.has(1):
		var t = team_stats[1]
		details += "Enemy Brott: %.0f HP remaining, %d alive" % [
			t["hp_remaining"], t["brotts_alive"]
		]
	return details

func test_details_both_teams() -> bool:
	var ts := {
		0: {"hp_remaining": 75.0, "brotts_alive": 1},
		1: {"hp_remaining": 0.0, "brotts_alive": 0},
	}
	var d := _format_details(ts)
	return "Your Brott: 75 HP remaining, 1 alive" in d and "Enemy Brott: 0 HP remaining, 0 alive" in d

func test_details_player_dead() -> bool:
	var ts := {
		0: {"hp_remaining": 0.0, "brotts_alive": 0},
		1: {"hp_remaining": 120.0, "brotts_alive": 1},
	}
	var d := _format_details(ts)
	return "Your Brott: 0 HP remaining, 0 alive" in d and "Enemy Brott: 120 HP remaining, 1 alive" in d

func test_details_empty_stats() -> bool:
	return _format_details({}) == ""

# ── Full match result integration ──

func test_real_match_result_has_outcome() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	var r := gc.match_result
	return r.has("outcome") and r["outcome"] != ""

func test_real_match_result_valid_outcome() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	var valid := ["team_a_wins", "team_b_wins", "draw",
		"timeout_draw", "timeout_team_a_advantage", "timeout_team_b_advantage"]
	return valid.has(gc.match_result["outcome"])

func test_real_match_has_team_stats() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	var ts = gc.match_result.get("team_stats", {})
	return ts.has(0) and ts.has(1)

func test_real_match_hp_remaining_non_negative() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	var ts = gc.match_result["team_stats"]
	return ts[0]["hp_remaining"] >= 0.0 and ts[1]["hp_remaining"] >= 0.0

func test_real_match_has_seed() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	return gc.match_result.has("seed")

# ── Rematch flow (start_match re-runs with same loadout) ──

func test_rematch_preserves_loadout() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.player_weapons = ["shotgun", "minigun"]
	gc.player_armor = "reactive_mesh"
	gc.start_match()
	gc.run_full_simulation()
	var w_before := gc.player_weapons.duplicate()
	var a_before := gc.player_armor
	gc.start_match()  # rematch
	return gc.player_weapons == w_before and gc.player_armor == a_before

func test_rematch_resets_brotts() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	gc.start_match()  # rematch
	return gc.player_brott.alive and gc.enemy_brott.alive

# ── Loadout button flow (restart goes to loadout) ──

func test_loadout_button_returns_to_loadout() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	gc.restart()
	return gc.current_screen == GameController.Screen.LOADOUT

func test_loadout_button_clears_match_data() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	gc.restart()
	return gc.match_result == {} and gc.sim_ticks.size() == 0 and gc.player_brott == null
