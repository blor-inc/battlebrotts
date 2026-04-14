# opponent_select.gd — Opponent selection screen
# BattleBrotts Sprint 6 · S6-001
#
# Shows available opponents in the current league with defeated status.
# Player picks who to fight next.
class_name OpponentSelect

# ── Signals ──────────────────────────────────────────────
signal opponent_selected(index: int)
signal back_pressed()

# ── State ────────────────────────────────────────────────
var campaign = null  # CampaignController

# ─────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────
func setup(campaign_controller) -> void:
	campaign = campaign_controller


func get_display_data() -> Dictionary:
	"""Returns data for rendering opponent list."""
	var progress: Dictionary = campaign.get_league_progress()
	var opponents := []

	for opp in progress["opponents"]:
		var info: Dictionary = campaign.get_opponent_info(opp["index"])
		opponents.append({
			"index": opp["index"],
			"name": opp["name"],
			"beaten": opp["beaten"],
			"chassis": info.get("chassis", ""),
			"weapons": info.get("weapons", []),
			"armor": info.get("armor", ""),
		})

	return {
		"league_name": campaign.league.get_current_league().get("name", "Unknown"),
		"wins": progress["wins"],
		"required": progress["required"],
		"opponents": opponents,
	}


func select_opponent(index: int) -> void:
	opponent_selected.emit(index)
