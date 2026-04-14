# opponent_select_ui.gd — Opponent selection UI Control
# BattleBrotts Sprint 11 · S11-001
#
# Shows available opponents in current league with beaten status.
extends Control

var campaign_ui = null  # CampaignUI reference
var campaign = null     # CampaignController

@onready var title_label: Label = %OpponentTitle
@onready var progress_label: Label = %ProgressLabel
@onready var opponent_list: ItemList = %OpponentList
@onready var fight_button: Button = %OpponentFightButton
@onready var back_button: Button = %OpponentBackButton


func setup(p_campaign_ui) -> void:
	campaign_ui = p_campaign_ui


func refresh(p_campaign) -> void:
	campaign = p_campaign
	_populate()


func _populate() -> void:
	if not opponent_list or not campaign:
		return

	var progress: Dictionary = campaign.get_league_progress()
	if title_label:
		var league_name: String = campaign.league.get_current_league().get("name", "Unknown")
		title_label.text = "⚔️ %s League" % league_name
	if progress_label:
		progress_label.text = "Wins: %d / %d required" % [progress["wins"], progress["required"]]

	opponent_list.clear()
	for opp in progress["opponents"]:
		var beaten: bool = opp["beaten"]
		var prefix := "✅ " if beaten else "⚔️ "
		var info: Dictionary = campaign.get_opponent_info(opp["index"])
		var chassis_str: String = info.get("chassis", "?").capitalize()
		var weapons_str: String = ", ".join(info.get("weapons", []))
		opponent_list.add_item("%s%s — %s [%s]" % [prefix, opp["name"], chassis_str, weapons_str])
		opponent_list.set_item_metadata(opponent_list.item_count - 1, opp["index"])


func _on_opponent_selected(_index: int) -> void:
	if fight_button:
		fight_button.disabled = false


func _on_fight_pressed() -> void:
	var selected := opponent_list.get_selected_items()
	if selected.is_empty():
		return
	var opp_index: int = opponent_list.get_item_metadata(selected[0])
	campaign_ui.on_opponent_selected(opp_index)


func _on_back_pressed() -> void:
	campaign_ui.on_opponent_back()
