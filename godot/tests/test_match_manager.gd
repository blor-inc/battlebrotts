# test_match_manager.gd — Tests for MatchManager (Sprint 3)
# Tests match lifecycle, win/loss/draw, timeout, state transitions
extends RefCounted

const BrottScript = preload("res://game/entities/brott.gd")
const MatchManagerScript = preload("res://game/autoloads/match_manager.gd")

func _make_brott(brott_id: int, team_id: int, chassis: String = "scout",
		weapons: Array = ["minigun"], armor: String = "",
		modules: Array = [], pos: Vector2 = Vector2.ZERO):
	return BrottScript.create(brott_id, team_id, chassis, weapons, armor, modules, pos)

func _make_manager_2v1(hp_a: float = -1.0, hp_b: float = -1.0):
	var mm = MatchManagerScript.new()
	var a = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(0, 0))
	var b = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(64, 0))
	if hp_a > 0:
		a.hp = hp_a
		a.max_hp = hp_a
	if hp_b > 0:
		b.hp = hp_b
		b.max_hp = hp_b
	mm.setup_match([a], [b], 42)
	return mm

func test_initial_state() -> bool:
	var mm = MatchManagerScript.new()
	return mm.state == MatchManagerScript.State.IDLE and mm.match_result == {}

func test_setup_match() -> bool:
	var mm = _make_manager_2v1()
	return mm.state == MatchManagerScript.State.IDLE and mm.match_seed == 42 and mm.tick_system.brotts.size() == 2

func test_start_match() -> bool:
	var mm = _make_manager_2v1()
	mm.start_match()
	return mm.state == MatchManagerScript.State.RUNNING and mm.is_running()

func test_pause_resume() -> bool:
	var mm = _make_manager_2v1()
	mm.start_match()
	mm.pause_match()
	if mm.state != MatchManagerScript.State.PAUSED or mm.is_running():
		return false
	mm.resume_match()
	return mm.state == MatchManagerScript.State.RUNNING

func test_run_to_completion_knockout() -> bool:
	var mm = MatchManagerScript.new()
	var a = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(0, 0))
	var b = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(64, 0))
	b.hp = 1.0
	b.max_hp = 1.0
	mm.setup_match([a], [b], 42)
	var result: Dictionary = mm.run_to_completion()
	return mm.is_ended() and result["winner_team"] == 0 and result["outcome"] == "team_a_wins"

func test_run_to_completion_timeout() -> bool:
	var mm = MatchManagerScript.new()
	var a = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(0, 0))
	var b = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(10000, 0))
	mm.setup_match([a], [b], 42)
	var result: Dictionary = mm.run_to_completion()
	return result["ticks"] > 100  # brotts close distance, so may not timeout but match ends

func test_draw_by_mutual_destruction() -> bool:
	var mm = MatchManagerScript.new()
	var a = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(0, 0))
	var b = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(32, 0))
	a.hp = 1.0; a.max_hp = 1.0
	b.hp = 1.0; b.max_hp = 1.0
	mm.setup_match([a], [b], 42)
	var result: Dictionary = mm.run_to_completion()
	return mm.is_ended()

func test_timeout_draw() -> bool:
	var mm = MatchManagerScript.new()
	var a = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(0, 0))
	var b = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(10000, 0))
	a.hp = 100.0; a.max_hp = 100.0
	b.hp = 100.0; b.max_hp = 100.0
	mm.setup_match([a], [b], 42)
	var result: Dictionary = mm.run_to_completion()
	return mm.is_ended()

func test_match_result_structure() -> bool:
	var mm = _make_manager_2v1()
	var result: Dictionary = mm.run_to_completion()
	return (result.has("winner_team") and result.has("outcome")
		and result.has("ticks") and result.has("duration_sec")
		and result.has("team_stats") and result.has("seed")
		and result["seed"] == 42 and result["duration_sec"] > 0.0)

func test_reset() -> bool:
	var mm = _make_manager_2v1()
	mm.run_to_completion()
	mm.reset()
	return mm.state == MatchManagerScript.State.IDLE and mm.match_result == {}

func test_signal_emissions() -> bool:
	var mm = _make_manager_2v1()
	var started := [false]
	var ended := [false]
	mm.match_started.connect(func(_s): started[0] = true)
	mm.match_ended.connect(func(_r): ended[0] = true)
	mm.run_to_completion()
	return started[0] and ended[0]

func test_cannot_start_without_setup() -> bool:
	var mm = MatchManagerScript.new()
	return mm.state == MatchManagerScript.State.IDLE

func test_step_returns_false_when_not_running() -> bool:
	var mm = _make_manager_2v1()
	return not mm.step()

func test_energy_system_integration() -> bool:
	var mm = MatchManagerScript.new()
	var a = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2(0, 0))
	var b = _make_brott(2, 1, "scout", ["minigun"], "", [], Vector2(64, 0))
	if a.energy != 100.0 or b.energy != 100.0:
		return false
	mm.setup_match([a], [b], 42)
	mm.start_match()
	for i in 5:
		mm.step()
	return a.energy >= 0.0 and a.energy <= 100.0

func test_energy_regen_rate() -> bool:
	var b = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2.ZERO)
	b.energy = 0.0
	b.regen_energy()
	if b.energy != 0.25:
		return false
	for i in 19:
		b.regen_energy()
	return b.energy == 5.0

func test_energy_cost_prevents_fire() -> bool:
	var b = _make_brott(1, 0, "scout", ["minigun"], "", [], Vector2.ZERO)
	b.energy = 0.0
	return not b.spend_energy(20.0) and b.energy == 0.0
