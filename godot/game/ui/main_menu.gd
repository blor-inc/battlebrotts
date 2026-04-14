# main_menu.gd — Main menu screen
# BattleBrotts Sprint 11 · S11-001
#
# Simple title screen with New Game and Continue buttons.
class_name MainMenuScreen
extends Control

signal new_game_pressed()
signal continue_pressed()

var has_save: bool = false

@onready var title_label: Label = %MenuTitle
@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton


func setup(save_exists: bool) -> void:
	has_save = save_exists
	if continue_button:
		continue_button.visible = has_save


func _on_new_game_pressed() -> void:
	new_game_pressed.emit()
	var campaign_ui = _get_campaign_ui()
	if campaign_ui:
		campaign_ui.on_new_game()


func _on_continue_pressed() -> void:
	continue_pressed.emit()


func _get_campaign_ui():
	# Walk up to find CampaignUI
	var node = get_parent()
	while node:
		if node.has_method("on_new_game"):
			return node
		node = node.get_parent()
	return null
