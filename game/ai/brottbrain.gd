# brottbrain.gd — Behavior card evaluation engine
# Evaluates cards top→bottom each tick, first match fires
# Falls back to current stance if no card matches

class_name BrottBrain

## Maximum number of behavior cards
const MAX_CARDS: int = 8

## Current active stance (default behavior when no card fires)
var stance: int = BehaviorCard.Stance.AGGRESSIVE

## Priority-ordered behavior cards
var cards: Array = []  ## Array[BehaviorCard]

## Last action result (for external systems to read)
var last_action_type: int = -1
var last_action_value: int = 0
var action_fired: bool = false  ## True if a card fired this tick, false if using stance default


## Add a behavior card. Returns false if at max capacity.
func add_card(card: BehaviorCard) -> bool:
	if cards.size() >= MAX_CARDS:
		return false
	cards.append(card)
	return true


## Remove card at index
func remove_card(index: int) -> void:
	if index >= 0 and index < cards.size():
		cards.remove_at(index)


## Move card up in priority (lower index = higher priority)
func move_card_up(index: int) -> void:
	if index > 0 and index < cards.size():
		var card: BehaviorCard = cards[index]
		cards.remove_at(index)
		cards.insert(index - 1, card)


## Move card down in priority
func move_card_down(index: int) -> void:
	if index >= 0 and index < cards.size() - 1:
		var card: BehaviorCard = cards[index]
		cards.remove_at(index)
		cards.insert(index + 1, card)


## Clear all cards
func clear_cards() -> void:
	cards.clear()


## Evaluate all cards against current game state
## Called once per tick (tick phase 1)
## Returns the action to execute, or null if no card fires
func evaluate(brott_hp_pct: float, brott_energy_pct: float,
		nearest_enemy_dist: float, nearest_enemy_hp_pct: float) -> Dictionary:
	action_fired = false
	last_action_type = -1
	last_action_value = 0
	
	for card in cards:
		if card.evaluate_trigger(brott_hp_pct, brott_energy_pct,
				nearest_enemy_dist, nearest_enemy_hp_pct):
			last_action_type = card.action_type
			last_action_value = card.action_value
			action_fired = true
			return {
				&"action": card.action_type,
				&"value": card.action_value,
				&"source": "card"
			}
	
	# No card fired — return stance default
	return {
		&"action": BehaviorCard.ActionType.SET_STANCE,
		&"value": stance,
		&"source": "stance_default"
	}


## Get the current effective stance (may be overridden by card action)
func get_effective_stance() -> int:
	if action_fired and last_action_type == BehaviorCard.ActionType.SET_STANCE:
		return last_action_value
	return stance


## Create a default BrottBrain with basic cards
## Used for Scrapyard league (before player unlocks BrottBrain editor)
static func create_default() -> BrottBrain:
	var brain := BrottBrain.new()
	brain.stance = BehaviorCard.Stance.AGGRESSIVE
	
	# Card 1: If HP < 25%, go defensive
	brain.add_card(BehaviorCard.new(
		BehaviorCard.TriggerType.HP_BELOW, 0.25,
		BehaviorCard.ActionType.SET_STANCE, BehaviorCard.Stance.DEFENSIVE
	))
	
	# Card 2: If energy < 20%, conserve
	brain.add_card(BehaviorCard.new(
		BehaviorCard.TriggerType.ENERGY_BELOW, 0.20,
		BehaviorCard.ActionType.CONSERVE_ENERGY, 0
	))
	
	# Card 3: If enemy HP < 20%, go aggressive (finish them)
	brain.add_card(BehaviorCard.new(
		BehaviorCard.TriggerType.ENEMY_HP_BELOW, 0.20,
		BehaviorCard.ActionType.SET_STANCE, BehaviorCard.Stance.AGGRESSIVE
	))
	
	return brain
