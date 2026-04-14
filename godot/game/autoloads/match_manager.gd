# match_manager.gd — Match lifecycle controller (autoload singleton)
# BattleBrotts Sprint 3 · S3-002
#
# Manages match start/end, win/loss/draw, 120s timeout.
# Wraps TickSystem and provides high-level match control.
class_name MatchManager

const _TickSystem = preload("res://game/combat/tick_system.gd")

# ── Signals ──────────────────────────────────────────────
signal match_started(seed_value: int)
signal match_ended(result: Dictionary)
signal tick_completed(tick_number: int)

# ── Match states ─────────────────────────────────────────
enum State { IDLE, RUNNING, PAUSED, ENDED }

# ── Config ───────────────────────────────────────────────
const MATCH_DURATION_SECONDS: float = 120.0
const TICKS_PER_SECOND: int = 20
const MAX_MATCH_TICKS: int = int(MATCH_DURATION_SECONDS * TICKS_PER_SECOND)

# ── State ────────────────────────────────────────────────
var state: State = State.IDLE
var tick_system = null
var match_seed: int = 0
var match_result: Dictionary = {}
# { "winner_team": int, "outcome": String, "ticks": int, "duration_sec": float,
#   "team_stats": { team_id: { "hp_remaining": float, "brotts_alive": int } } }

var _brotts_team_a: Array = []
var _brotts_team_b: Array = []

# ─────────────────────────────────────────────────────────
# Init
# ─────────────────────────────────────────────────────────
func _init() -> void:
	tick_system = _TickSystem.new()

# ─────────────────────────────────────────────────────────
# Setup and start a match
# ─────────────────────────────────────────────────────────
func setup_match(team_a: Array, team_b: Array, seed_value: int = -1) -> void:
	assert(state == State.IDLE or state == State.ENDED,
		"Cannot setup match in state %s" % State.keys()[state])
	assert(team_a.size() > 0, "Team A must have at least one brott")
	assert(team_b.size() > 0, "Team B must have at least one brott")

	_brotts_team_a = team_a
	_brotts_team_b = team_b

	if seed_value < 0:
		seed_value = randi()
	match_seed = seed_value

	var all_brotts := team_a + team_b
	tick_system.setup(match_seed, all_brotts)

	state = State.IDLE
	match_result = {}

func start_match() -> void:
	assert(state == State.IDLE, "Cannot start match in state %s" % State.keys()[state])
	assert(tick_system.brotts.size() > 0, "No brotts configured — call setup_match first")

	state = State.RUNNING
	match_started.emit(match_seed)

func pause_match() -> void:
	if state == State.RUNNING:
		state = State.PAUSED

func resume_match() -> void:
	if state == State.PAUSED:
		state = State.RUNNING

# ─────────────────────────────────────────────────────────
# Run one tick (for frame-by-frame playback)
# ─────────────────────────────────────────────────────────
func step() -> bool:
	if state != State.RUNNING:
		return false

	var continues: bool = tick_system.run_tick()
	tick_completed.emit(tick_system.tick)

	if not continues:
		_finalize_match()
		return false

	return true

# ─────────────────────────────────────────────────────────
# Run the entire match to completion (instant sim)
# ─────────────────────────────────────────────────────────
func run_to_completion() -> Dictionary:
	if state == State.IDLE:
		start_match()

	while state == State.RUNNING:
		step()

	return match_result

# ─────────────────────────────────────────────────────────
# Finalize match — build result dict
# ─────────────────────────────────────────────────────────
func _finalize_match() -> void:
	state = State.ENDED

	var ticks: int = tick_system.tick
	var winner: int = tick_system.winner_team
	var outcome := "draw"
	if winner == 0:
		outcome = "team_a_wins"
	elif winner == 1:
		outcome = "team_b_wins"

	# Was it a timeout?
	if ticks >= MAX_MATCH_TICKS and winner >= 0:
		outcome = "timeout_" + outcome.replace("_wins", "_advantage")
	elif ticks >= MAX_MATCH_TICKS and winner < 0:
		outcome = "timeout_draw"

	# Gather team stats
	var team_stats := {}
	for b: Brott in tick_system.brotts:
		if not team_stats.has(b.team):
			team_stats[b.team] = {"hp_remaining": 0.0, "brotts_alive": 0, "total_brotts": 0}
		team_stats[b.team]["total_brotts"] += 1
		team_stats[b.team]["hp_remaining"] += maxf(b.hp, 0.0)
		if b.alive:
			team_stats[b.team]["brotts_alive"] += 1

	match_result = {
		"winner_team": winner,
		"outcome": outcome,
		"ticks": ticks,
		"duration_sec": float(ticks) / float(TICKS_PER_SECOND),
		"team_stats": team_stats,
		"seed": match_seed,
	}

	match_ended.emit(match_result)

# ─────────────────────────────────────────────────────────
# Query helpers
# ─────────────────────────────────────────────────────────
func is_running() -> bool:
	return state == State.RUNNING

func is_ended() -> bool:
	return state == State.ENDED

func get_tick() -> int:
	if tick_system:
		return tick_system.tick
	return 0

func get_elapsed_seconds() -> float:
	return float(get_tick()) / float(TICKS_PER_SECOND)

func get_result() -> Dictionary:
	return match_result

func reset() -> void:
	state = State.IDLE
	match_result = {}
	_brotts_team_a = []
	_brotts_team_b = []
	tick_system = _TickSystem.new()
