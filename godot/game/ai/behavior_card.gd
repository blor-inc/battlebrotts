# behavior_card.gd — Behavior card data structure for BrottBrain
# Each card is a trigger + action pair evaluated in priority order

class_name BehaviorCard

## Trigger types
enum TriggerType {
	HP_BELOW,         ## My HP below threshold %
	HP_ABOVE,         ## My HP above threshold %
	ENEMY_HP_BELOW,   ## Enemy HP below threshold %
	ENEMY_IN_RANGE,   ## Enemy within distance (tiles)
	ENERGY_ABOVE,     ## My energy above threshold %
	ENERGY_BELOW,     ## My energy below threshold %
	ALWAYS,           ## Always true (catch-all)
}

## Action types
enum ActionType {
	SET_STANCE,       ## Switch to a stance
	MOVE_TO_COVER,    ## Find nearest cover, move there
	HOLD_POSITION,    ## Stop moving
	FOCUS_FIRE,       ## Target lowest HP enemy
	CONSERVE_ENERGY,  ## Only fire cheapest weapon
}

## Stance enum (shared with steering.gd)
enum Stance {
	AGGRESSIVE,
	DEFENSIVE,
	KITING,
	AMBUSH,
}

## Target selection for FOCUS_FIRE
enum TargetSelection {
	LOWEST_HP,
	NEAREST,
	HIGHEST_THREAT,
}

## Card data
var trigger_type: int = TriggerType.ALWAYS
var trigger_value: float = 0.0  ## Threshold or range value
var action_type: int = ActionType.SET_STANCE
var action_value: int = 0  ## Stance enum, TargetSelection, etc.


func _init(p_trigger: int = TriggerType.ALWAYS, p_trigger_val: float = 0.0,
		p_action: int = ActionType.SET_STANCE, p_action_val: int = 0) -> void:
	trigger_type = p_trigger
	trigger_value = p_trigger_val
	action_type = p_action
	action_value = p_action_val


## Evaluate trigger against current game state
## Returns true if this card's trigger condition is met
func evaluate_trigger(brott_hp_pct: float, brott_energy_pct: float,
		nearest_enemy_dist: float, nearest_enemy_hp_pct: float) -> bool:
	match trigger_type:
		TriggerType.HP_BELOW:
			return brott_hp_pct < trigger_value
		TriggerType.HP_ABOVE:
			return brott_hp_pct > trigger_value
		TriggerType.ENEMY_HP_BELOW:
			return nearest_enemy_hp_pct < trigger_value
		TriggerType.ENEMY_IN_RANGE:
			return nearest_enemy_dist <= trigger_value
		TriggerType.ENERGY_ABOVE:
			return brott_energy_pct > trigger_value
		TriggerType.ENERGY_BELOW:
			return brott_energy_pct < trigger_value
		TriggerType.ALWAYS:
			return true
	return false
