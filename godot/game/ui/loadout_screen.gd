# loadout_screen.gd — Loadout selection UI
# BattleBrotts Sprint 4 · S4-001
#
# Player picks chassis, weapons, armor, and modules.
# Shows weight budget, slot limits, and validates before starting.
extends Control

var game: GameController = null

# UI references (set via _ready or scene tree)
@onready var chassis_list: ItemList = %ChassisList
@onready var weapon_list: ItemList = %WeaponList
@onready var armor_list: ItemList = %ArmorList
@onready var module_list: ItemList = %ModuleList
@onready var weight_label: Label = %WeightLabel
@onready var slots_label: Label = %SlotsLabel
@onready var stats_label: Label = %StatsLabel
@onready var error_label: Label = %ErrorLabel
@onready var fight_button: Button = %FightButton
@onready var enemy_info: Label = %EnemyInfo


func setup(controller: GameController) -> void:
	game = controller
	_populate_lists()
	_update_display()


func _populate_lists() -> void:
	# Chassis
	chassis_list.clear()
	for id in game.get_available_chassis():
		var c := game.get_chassis_info(id)
		chassis_list.add_item("%s — HP:%d SPD:%d CAP:%d W:%d M:%d" % [
			c["name"], c["hp"], c["speed"], c["weight_cap"],
			c["weapon_slots"], c["module_slots"]
		])
		chassis_list.set_item_metadata(chassis_list.item_count - 1, id)

	# Weapons
	weapon_list.clear()
	weapon_list.select_mode = ItemList.SELECT_MULTI
	for id in game.get_available_weapons():
		var w := game.get_weapon_info(id)
		weapon_list.add_item("%s — DMG:%d RNG:%d WT:%d E:%d" % [
			w["name"], w["damage"], w["range"], w["weight"], w["energy_cost"]
		])
		weapon_list.set_item_metadata(weapon_list.item_count - 1, id)

	# Armor
	armor_list.clear()
	armor_list.add_item("None")
	armor_list.set_item_metadata(0, "")
	for id in game.get_available_armor():
		var a := game.get_armor_info(id)
		armor_list.add_item("%s — DR:%.0f%% WT:%d" % [
			a["name"], a["damage_reduction"] * 100, a["weight"]
		])
		armor_list.set_item_metadata(armor_list.item_count - 1, id)

	# Modules
	module_list.clear()
	module_list.select_mode = ItemList.SELECT_MULTI
	for id in game.get_available_modules():
		var m := game.get_module_info(id)
		var type_str := "Passive" if m["passive"] else "Active"
		module_list.add_item("%s — %s WT:%d" % [m["name"], type_str, m["weight"]])
		module_list.set_item_metadata(module_list.item_count - 1, id)

	# Show enemy loadout
	var ec := ChassisData.get_chassis(GameController.ENEMY_CHASSIS)
	enemy_info.text = "Enemy: %s Brawler w/ Shotgun + Missile Pod, Reactive Mesh, Repair Nanites" % ec["name"]

	# Select defaults
	chassis_list.select(1)  # Brawler
	_on_chassis_selected(1)


func _on_chassis_selected(index: int) -> void:
	game.player_chassis = chassis_list.get_item_metadata(index)
	# Clear weapons/modules if they exceed new slot limits
	var chassis := game.get_chassis_info(game.player_chassis)
	while game.player_weapons.size() > chassis["weapon_slots"]:
		game.player_weapons.pop_back()
	while game.player_modules.size() > chassis["module_slots"]:
		game.player_modules.pop_back()
	_update_display()


func _on_weapon_selected(_index: int) -> void:
	game.player_weapons.clear()
	for i in weapon_list.get_selected_items():
		game.player_weapons.append(weapon_list.get_item_metadata(i))
	_update_display()


func _on_armor_selected(index: int) -> void:
	game.player_armor = armor_list.get_item_metadata(index)
	_update_display()


func _on_module_selected(_index: int) -> void:
	game.player_modules.clear()
	for i in module_list.get_selected_items():
		game.player_modules.append(module_list.get_item_metadata(i))
	_update_display()


func _update_display() -> void:
	if not game:
		return

	var chassis := game.get_chassis_info(game.player_chassis)
	var weight := game.get_weight_used()
	var cap := game.get_weight_cap()

	weight_label.text = "Weight: %.0f / %.0f" % [weight, cap]
	weight_label.modulate = Color.RED if weight > cap else Color.WHITE

	slots_label.text = "Weapons: %d/%d · Modules: %d/%d" % [
		game.player_weapons.size(), chassis["weapon_slots"],
		game.player_modules.size(), chassis["module_slots"],
	]

	stats_label.text = "HP: %d · Speed: %d" % [chassis["hp"], chassis["speed"]]

	var validation := game.validate_loadout()
	if validation["valid"]:
		error_label.text = ""
		fight_button.disabled = false
	else:
		error_label.text = "\n".join(validation["errors"])
		fight_button.disabled = true


func _on_fight_pressed() -> void:
	game.start_match()
