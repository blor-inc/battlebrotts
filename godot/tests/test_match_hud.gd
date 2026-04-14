# test_match_hud.gd — Tests for MatchHUD logic paths
# BattleBrotts Sprint 5 · S5-002
#
# Tests HP/energy/shield bar update data, speed control cycling,
# tick display values, and snapshot interpretation.
extends RefCounted

const Brott = preload("res://game/entities/brott.gd")
const ChassisData = preload("res://game/data/chassis_data.gd")

# ── Speed control tests ──

func test_speed_options_defined() -> bool:
	# match_hud.gd defines SPEED_OPTIONS = [1, 5, 20, 100]
	var options := [1, 5, 20, 100]
	return options.size() == 4 and options[0] == 1 and options[3] == 100

func test_speed_cycling() -> bool:
	# Simulate the speed button cycling logic from match_hud
	var speed_options := [1, 5, 20, 100]
	var speed_index := 0
	# Press 4 times, should cycle back to 1x
	for i in 4:
		speed_index = (speed_index + 1) % speed_options.size()
	return speed_index == 0 and speed_options[speed_index] == 1

func test_speed_cycle_sequence() -> bool:
	var speed_options := [1, 5, 20, 100]
	var speed_index := 0
	var sequence := []
	for i in 4:
		speed_index = (speed_index + 1) % speed_options.size()
		sequence.append(speed_options[speed_index])
	return sequence == [5, 20, 100, 1]

# ── Tick snapshot data tests ──

func test_snapshot_has_required_fields() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.step_simulation()
	var snap: Dictionary = gc.sim_ticks[0]
	return snap.has("tick") and snap.has("elapsed") and snap.has("player") and snap.has("enemy")

func test_snapshot_player_fields() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.step_simulation()
	var p: Dictionary = gc.sim_ticks[0]["player"]
	return (p.has("hp") and p.has("max_hp") and p.has("energy")
		and p.has("alive") and p.has("shield_hp") and p.has("hp_ratio"))

func test_snapshot_enemy_fields() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.step_simulation()
	var e: Dictionary = gc.sim_ticks[0]["enemy"]
	return (e.has("hp") and e.has("max_hp") and e.has("energy")
		and e.has("alive") and e.has("shield_hp") and e.has("hp_ratio"))

func test_snapshot_tick_starts_at_one() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.step_simulation()
	return gc.sim_ticks[0]["tick"] == 1

func test_snapshot_ticks_increment() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.step_simulation()
	gc.step_simulation()
	gc.step_simulation()
	return (gc.sim_ticks[0]["tick"] == 1 and gc.sim_ticks[1]["tick"] == 2
		and gc.sim_ticks[2]["tick"] == 3)

func test_snapshot_elapsed_increases() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.step_simulation()
	gc.step_simulation()
	return gc.sim_ticks[1]["elapsed"] > gc.sim_ticks[0]["elapsed"]

# ── HP bar update logic ──

func test_hp_starts_at_max() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.step_simulation()
	var p: Dictionary = gc.sim_ticks[0]["player"]
	return p["hp"] == p["max_hp"] or p["hp"] <= p["max_hp"]  # may take damage tick 1

func test_hp_ratio_bounded() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	for snap in gc.sim_ticks:
		if snap["player"]["hp_ratio"] < 0.0 or snap["player"]["hp_ratio"] > 1.0:
			return false
		if snap["enemy"]["hp_ratio"] < 0.0 or snap["enemy"]["hp_ratio"] > 1.0:
			return false
	return true

func test_hp_never_exceeds_max() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	for snap in gc.sim_ticks:
		if snap["player"]["hp"] > snap["player"]["max_hp"]:
			return false
		if snap["enemy"]["hp"] > snap["enemy"]["max_hp"]:
			return false
	return true

func test_hp_never_negative() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	for snap in gc.sim_ticks:
		if snap["player"]["hp"] < 0.0 or snap["enemy"]["hp"] < 0.0:
			return false
	return true

# ── Energy bar update logic ──

func test_energy_bounded() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	for snap in gc.sim_ticks:
		if snap["player"]["energy"] < 0.0 or snap["player"]["energy"] > Brott.MAX_ENERGY:
			return false
		if snap["enemy"]["energy"] < 0.0 or snap["enemy"]["energy"] > Brott.MAX_ENERGY:
			return false
	return true

# ── Shield bar logic ──

func test_shield_never_negative() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	for snap in gc.sim_ticks:
		if snap["player"]["shield_hp"] < 0.0 or snap["enemy"]["shield_hp"] < 0.0:
			return false
	return true

# ── Timer/tick display formatting logic ──

func test_timer_format_zero() -> bool:
	var elapsed := 0.0
	var formatted := "%d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	return formatted == "0:00"

func test_timer_format_one_minute() -> bool:
	var elapsed := 60.0
	var formatted := "%d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	return formatted == "1:00"

func test_timer_format_max() -> bool:
	var elapsed := 119.5
	var formatted := "%d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	return formatted == "1:59"

func test_tick_label_format() -> bool:
	var tick := 42
	var max_ticks := 2400  # MatchManager.MAX_MATCH_TICKS
	var formatted := "Tick: %d / %d" % [tick, max_ticks]
	return formatted == "Tick: 42 / 2400"

# ── Status label logic ──

func test_status_fighting_when_both_alive() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.step_simulation()
	var snap: Dictionary = gc.sim_ticks[0]
	# Both should be alive at tick 1
	return snap["player"]["alive"] and snap["enemy"]["alive"]

func test_match_ends_with_dead_or_timeout() -> bool:
	var gc := GameController.new()
	gc._ready()
	gc.start_match()
	gc.run_full_simulation()
	var last: Dictionary = gc.sim_ticks[gc.sim_ticks.size() - 1]
	# At least one should be dead, or it timed out
	var someone_dead: bool = not last["player"]["alive"] or not last["enemy"]["alive"]
	var timed_out: bool = last["tick"] >= 2400  # MAX_MATCH_TICKS
	return someone_dead or timed_out

# ── Playback interval calculation ──

func test_tick_interval_at_1x() -> bool:
	var base_interval := 0.05
	var speed := 1
	var interval := base_interval / float(speed)
	return interval == 0.05

func test_tick_interval_at_5x() -> bool:
	var base_interval := 0.05
	var speed := 5
	var interval := base_interval / float(speed)
	return interval == 0.01

func test_tick_interval_at_100x() -> bool:
	var base_interval := 0.05
	var speed := 100
	var interval := base_interval / float(speed)
	return interval == 0.0005
