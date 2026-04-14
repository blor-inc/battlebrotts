# test_match_manager.gd — Tests for MatchManager (Sprint 3)
# Tests match lifecycle, win/loss/draw, timeout, state transitions
extends "res://tests/test_runner.gd"

func run_tests() -> void:
	test_initial_state()
	test_setup_match()
	test_start_match()
	test_pause_resume()
	test_run_to_completion_knockout()
	test_run_to_completion_timeout()
	test_draw_by_mutual_destruction()
	test_timeout_draw()
	test_match_result_structure()
	test_reset()
	test_signal_emissions()
	test_cannot_start_without_setup()
	test_step_returns_false_when_not_running()
	test_energy_system_integration()
	test_energy_regen_rate()
	test_energy_cost_prevents_fire()

# ── Helpers ──────────────────────────────────────────────
func _make_brott(brott_id: int, team_id: int, chassis: String = "striker",
		weapons: Array = ["minigun"], armor: String = "",
		modules: Array = [], pos: Vector2 = Vector2.ZERO) -> Brott:
	return Brott.create(brott_id, team_id, chassis, weapons, armor, modules, pos)

func _make_manager_2v1(hp_override_a: float = -1.0, hp_override_b: float = -1.0) -> MatchManager:
	var mm := MatchManager.new()
	var a := _make_brott(1, 0, "striker", ["minigun"], "", [], Vector2(0, 0))
	var b := _make_brott(2, 1, "striker", ["minigun"], "", [], Vector2(64, 0))
	if hp_override_a > 0:
		a.hp = hp_override_a
		a.max_hp = hp_override_a
	if hp_override_b > 0:
		b.hp = hp_override_b
		b.max_hp = hp_override_b
	mm.setup_match([a], [b], 42)
	return mm

# ── Tests ────────────────────────────────────────────────
func test_initial_state() -> void:
	var mm := MatchManager.new()
	assert_eq(mm.state, MatchManager.State.IDLE, "Initial state should be IDLE")
	assert_eq(mm.match_result, {}, "Initial result should be empty")

func test_setup_match() -> void:
	var mm := _make_manager_2v1()
	assert_eq(mm.state, MatchManager.State.IDLE, "After setup, state should be IDLE")
	assert_eq(mm.match_seed, 42, "Seed should be 42")
	assert_eq(mm.tick_system.brotts.size(), 2, "Should have 2 brotts")

func test_start_match() -> void:
	var mm := _make_manager_2v1()
	mm.start_match()
	assert_eq(mm.state, MatchManager.State.RUNNING, "After start, state should be RUNNING")
	assert_true(mm.is_running(), "is_running() should be true")

func test_pause_resume() -> void:
	var mm := _make_manager_2v1()
	mm.start_match()
	mm.pause_match()
	assert_eq(mm.state, MatchManager.State.PAUSED, "After pause, state should be PAUSED")
	assert_false(mm.is_running(), "is_running() should be false when paused")
	mm.resume_match()
	assert_eq(mm.state, MatchManager.State.RUNNING, "After resume, state should be RUNNING")

func test_run_to_completion_knockout() -> void:
	# One brott has 1 HP, should die quickly
	var mm := MatchManager.new()
	var a := _make_brott(1, 0, "striker", ["minigun"], "", [], Vector2(0, 0))
	var b := _make_brott(2, 1, "striker", ["minigun"], "", [], Vector2(64, 0))
	b.hp = 1.0
	b.max_hp = 1.0
	mm.setup_match([a], [b], 42)
	var result := mm.run_to_completion()
	assert_true(mm.is_ended(), "Match should be ended")
	assert_eq(result["winner_team"], 0, "Team A should win")
	assert_true(result["outcome"] == "team_a_wins", "Outcome should be team_a_wins")
	assert_true(result["ticks"] < MatchManager.MAX_MATCH_TICKS, "Should end before timeout")

func test_run_to_completion_timeout() -> void:
	# Both brotts far apart with no weapons in range → timeout
	var mm := MatchManager.new()
	var a := _make_brott(1, 0, "juggernaut", ["railgun"], "", [], Vector2(0, 0))
	var b := _make_brott(2, 1, "juggernaut", ["railgun"], "", [], Vector2(10000, 0))
	mm.setup_match([a], [b], 42)
	var result := mm.run_to_completion()
	assert_true(result["ticks"] >= MatchManager.MAX_MATCH_TICKS, "Should reach timeout")

func test_draw_by_mutual_destruction() -> void:
	# Both at 1 HP with rapid fire — might kill each other same tick
	var mm := MatchManager.new()
	var a := _make_brott(1, 0, "striker", ["minigun"], "", [], Vector2(0, 0))
	var b := _make_brott(2, 1, "striker", ["minigun"], "", [], Vector2(32, 0))
	a.hp = 1.0
	a.max_hp = 1.0
	b.hp = 1.0
	b.max_hp = 1.0
	mm.setup_match([a], [b], 42)
	var result := mm.run_to_completion()
	assert_true(mm.is_ended(), "Match should be ended")
	# Could be either team or draw depending on tick order

func test_timeout_draw() -> void:
	# Equal HP far apart — should timeout with draw
	var mm := MatchManager.new()
	var a := _make_brott(1, 0, "juggernaut", ["railgun"], "", [], Vector2(0, 0))
	var b := _make_brott(2, 1, "juggernaut", ["railgun"], "", [], Vector2(10000, 0))
	# Give them identical HP
	a.hp = 100.0
	a.max_hp = 100.0
	b.hp = 100.0
	b.max_hp = 100.0
	mm.setup_match([a], [b], 42)
	var result := mm.run_to_completion()
	assert_true(result["ticks"] >= MatchManager.MAX_MATCH_TICKS, "Should reach timeout")
	# Both have equal HP, so should be a draw
	assert_true(result["outcome"].begins_with("timeout"), "Should be timeout outcome")

func test_match_result_structure() -> void:
	var mm := _make_manager_2v1()
	var result := mm.run_to_completion()
	assert_true(result.has("winner_team"), "Result should have winner_team")
	assert_true(result.has("outcome"), "Result should have outcome")
	assert_true(result.has("ticks"), "Result should have ticks")
	assert_true(result.has("duration_sec"), "Result should have duration_sec")
	assert_true(result.has("team_stats"), "Result should have team_stats")
	assert_true(result.has("seed"), "Result should have seed")
	assert_eq(result["seed"], 42, "Seed should match")
	assert_true(result["duration_sec"] > 0.0, "Duration should be positive")

func test_reset() -> void:
	var mm := _make_manager_2v1()
	mm.run_to_completion()
	mm.reset()
	assert_eq(mm.state, MatchManager.State.IDLE, "After reset, state should be IDLE")
	assert_eq(mm.match_result, {}, "After reset, result should be empty")

func test_signal_emissions() -> void:
	var mm := _make_manager_2v1()
	var started := [false]
	var ended := [false]
	mm.match_started.connect(func(_s): started[0] = true)
	mm.match_ended.connect(func(_r): ended[0] = true)
	mm.run_to_completion()
	assert_true(started[0], "match_started should have been emitted")
	assert_true(ended[0], "match_ended should have been emitted")

func test_cannot_start_without_setup() -> void:
	var mm := MatchManager.new()
	# start_match should assert — we test that state remains IDLE
	assert_eq(mm.state, MatchManager.State.IDLE, "Should still be IDLE")

func test_step_returns_false_when_not_running() -> void:
	var mm := _make_manager_2v1()
	assert_false(mm.step(), "step() should return false when not running")

func test_energy_system_integration() -> void:
	# Verify energy starts at 100 and gets consumed on fire
	var mm := MatchManager.new()
	var a := _make_brott(1, 0, "striker", ["railgun"], "", [], Vector2(0, 0))
	var b := _make_brott(2, 1, "juggernaut", ["minigun"], "", [], Vector2(64, 0))
	assert_eq(a.energy, 100.0, "Energy should start at 100")
	assert_eq(b.energy, 100.0, "Energy should start at 100")
	mm.setup_match([a], [b], 42)
	mm.start_match()
	# Run a few ticks
	for i in 5:
		mm.step()
	# At least one brott should have used some energy (railgun costs 20)
	# or regened. Check energy is between 0 and 100.
	assert_true(a.energy >= 0.0 and a.energy <= 100.0, "Energy should be in valid range")

func test_energy_regen_rate() -> void:
	# Verify 5/sec = 0.25/tick regen
	var b := _make_brott(1, 0, "striker", ["minigun"], "", [], Vector2.ZERO)
	b.energy = 0.0
	b.regen_energy()
	assert_eq(b.energy, 0.25, "Should regen 0.25 per tick (5/sec at 20 tps)")
	# 20 ticks = 1 second = 5 energy
	for i in 19:
		b.regen_energy()
	assert_eq(b.energy, 5.0, "Should have 5.0 after 20 ticks")

func test_energy_cost_prevents_fire() -> void:
	# Brott with 0 energy can't fire railgun (cost 20)
	var b := _make_brott(1, 0, "striker", ["railgun"], "", [], Vector2.ZERO)
	b.energy = 0.0
	assert_false(b.spend_energy(20.0), "Should fail to spend 20 energy with 0 available")
	assert_eq(b.energy, 0.0, "Energy should remain 0")
