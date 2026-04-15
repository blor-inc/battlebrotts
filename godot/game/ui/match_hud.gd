# match_hud.gd — Match HUD overlay during combat
# BattleBrotts Sprint 4 · S4-001
#
# Displays health bars, energy bars, stance indicators, tick counter.
# Updates each tick from GameController snapshots.
extends Control

var game: GameController = null

# UI references
@onready var player_name_label: Label = %PlayerName
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var player_energy_bar: ProgressBar = %PlayerEnergyBar
@onready var player_energy_label: Label = %PlayerEnergyLabel
@onready var player_shield_bar: ProgressBar = %PlayerShieldBar

@onready var enemy_name_label: Label = %EnemyName
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var enemy_energy_bar: ProgressBar = %EnemyEnergyBar
@onready var enemy_energy_label: Label = %EnemyEnergyLabel
@onready var enemy_shield_bar: ProgressBar = %EnemyShieldBar

@onready var tick_label: Label = %TickLabel
@onready var timer_label: Label = %TimerLabel
@onready var status_label: Label = %StatusLabel
@onready var speed_button: Button = %SpeedButton

# Playback speed (ticks per frame)
var playback_speed: int = 1
const SPEED_OPTIONS := [1, 2, 5]
var speed_index: int = 0

# Auto-play timer
var tick_timer: float = 0.0
const TICK_INTERVAL: float = 0.05  # 50ms per tick at 1x


func setup(controller: GameController) -> void:
	game = controller
	game.match_tick.connect(_on_tick)
	game.match_finished.connect(_on_match_finished)

	# Init bars
	player_hp_bar.max_value = game.player_brott.max_hp
	player_energy_bar.max_value = Brott.MAX_ENERGY
	player_shield_bar.max_value = 40  # Shield Projector max
	player_name_label.text = "🤖 YOUR BROTT (%s)" % ChassisData.get_chassis(game.player_chassis)["name"]

	enemy_hp_bar.max_value = game.enemy_brott.max_hp
	enemy_energy_bar.max_value = Brott.MAX_ENERGY
	enemy_shield_bar.max_value = 40
	enemy_name_label.text = "💀 ENEMY (%s)" % ChassisData.get_chassis(GameController.ENEMY_CHASSIS)["name"]


func _process(delta: float) -> void:
	if not game or not game.match_manager or not game.match_manager.is_running():
		return

	tick_timer += delta
	var interval := TICK_INTERVAL / float(playback_speed)
	while tick_timer >= interval:
		tick_timer -= interval
		if not game.step_simulation():
			break


func _on_tick(data: Dictionary) -> void:
	# Player
	player_hp_bar.value = data["player"]["hp"]
	player_hp_label.text = "%.0f / %.0f" % [data["player"]["hp"], data["player"]["max_hp"]]
	player_energy_bar.value = data["player"]["energy"]
	player_energy_label.text = "%.0f" % data["player"]["energy"]
	player_shield_bar.value = data["player"]["shield_hp"]

	# Enemy
	enemy_hp_bar.value = data["enemy"]["hp"]
	enemy_hp_label.text = "%.0f / %.0f" % [data["enemy"]["hp"], data["enemy"]["max_hp"]]
	enemy_energy_bar.value = data["enemy"]["energy"]
	enemy_energy_label.text = "%.0f" % data["enemy"]["energy"]
	enemy_shield_bar.value = data["enemy"]["shield_hp"]

	# Tick/timer
	tick_label.text = "Tick: %d / %d" % [data["tick"], MatchManager.MAX_MATCH_TICKS]
	var elapsed: float = data["elapsed"]
	timer_label.text = "%d:%02d / 2:00" % [int(elapsed) / 60, int(elapsed) % 60]

	# Status
	if not data["player"]["alive"]:
		status_label.text = "YOUR BROTT IS DOWN!"
		status_label.modulate = Color.RED
	elif not data["enemy"]["alive"]:
		status_label.text = "ENEMY IS DOWN!"
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "FIGHTING..."
		status_label.modulate = Color.WHITE


func _on_match_finished(_result: Dictionary) -> void:
	status_label.text = "MATCH OVER"
	status_label.modulate = Color.YELLOW


func _on_speed_pressed() -> void:
	speed_index = (speed_index + 1) % SPEED_OPTIONS.size()
	playback_speed = SPEED_OPTIONS[speed_index]
	speed_button.text = "%dx" % playback_speed
