# result_screen.gd — Match result display
# BattleBrotts Sprint 4 · S4-001
#
# Shows win/loss/draw, match stats, and rematch/loadout buttons.
extends Control

var game: GameController = null
var campaign_ui = null  # CampaignUI reference

@onready var outcome_label: Label = %OutcomeLabel
@onready var stats_label: Label = %StatsLabel
@onready var details_label: Label = %DetailsLabel
@onready var rematch_button: Button = %RematchButton
@onready var loadout_button: Button = %LoadoutButton


func setup(controller: GameController) -> void:
	game = controller


func show_result(result: Dictionary) -> void:
	# Determine outcome text
	var outcome: String = result.get("outcome", "unknown")
	match outcome:
		"team_a_wins":
			outcome_label.text = "🏆 VICTORY!"
			outcome_label.modulate = Color.GREEN
		"team_b_wins":
			outcome_label.text = "💀 DEFEAT"
			outcome_label.modulate = Color.RED
		"draw", "timeout_draw":
			outcome_label.text = "🤝 DRAW"
			outcome_label.modulate = Color.YELLOW
		"timeout_team_a_advantage":
			outcome_label.text = "⏱️ TIME'S UP — YOU WIN!"
			outcome_label.modulate = Color.GREEN
		"timeout_team_b_advantage":
			outcome_label.text = "⏱️ TIME'S UP — YOU LOSE"
			outcome_label.modulate = Color.RED
		_:
			outcome_label.text = outcome.to_upper()
			outcome_label.modulate = Color.WHITE

	# Stats
	var duration: float = result.get("duration_sec", 0.0)
	var ticks: int = result.get("ticks", 0)
	stats_label.text = "Duration: %d:%02d (%d ticks) · Seed: %d" % [
		int(duration) / 60, int(duration) % 60, ticks, result.get("seed", 0)
	]

	# Team details
	var team_stats: Dictionary = result.get("team_stats", {})
	var details := ""
	if team_stats.has(0):
		var t: Dictionary = team_stats[0]
		details += "Your Brott: %.0f HP remaining, %d alive\n" % [
			t["hp_remaining"], t["brotts_alive"]
		]
	if team_stats.has(1):
		var t: Dictionary = team_stats[1]
		details += "Enemy Brott: %.0f HP remaining, %d alive" % [
			t["hp_remaining"], t["brotts_alive"]
		]
	details_label.text = details


func show_campaign_result(result: Dictionary) -> void:
	"""Show result from CampaignController.get_last_result()."""
	var match_result: Dictionary = result.get("match_result", {})
	var won: bool = result.get("won", false)
	var bolts_earned: int = result.get("bolts_earned", 0)
	var repair_cost: int = result.get("repair_cost", 0)
	var net_bolts: int = result.get("net_bolts", 0)
	var opp_name: String = result.get("opponent_name", "Unknown")

	# Outcome
	if won:
		outcome_label.text = "🏆 VICTORY vs %s!" % opp_name
		outcome_label.modulate = Color.GREEN
	else:
		outcome_label.text = "💀 DEFEAT vs %s" % opp_name
		outcome_label.modulate = Color.RED

	# Stats with economy info
	var duration: float = match_result.get("duration_sec", 0.0)
	var ticks: int = match_result.get("ticks", 0)
	stats_label.text = "Duration: %d:%02d (%d ticks)" % [
		int(duration) / 60, int(duration) % 60, ticks
	]

	details_label.text = "Earned: %d 🔩 · Repairs: %d 🔩 · Net: %s%d 🔩" % [
		bolts_earned, repair_cost,
		"+" if net_bolts >= 0 else "", net_bolts
	]

	# Relabel buttons for campaign mode
	if rematch_button:
		rematch_button.text = "🔄 Rematch"
	if loadout_button:
		loadout_button.text = "➡️ Continue"


func _on_rematch_pressed() -> void:
	if campaign_ui:
		campaign_ui.on_result_rematch()
	elif game:
		game.start_match()


func _on_loadout_pressed() -> void:
	if campaign_ui:
		campaign_ui.on_result_continue()
	elif game:
		game.restart()
