# test_brottbrain.gd — Tests for BrottBrain + BehaviorCard
extends RefCounted

const BehaviorCard = preload("res://game/ai/behavior_card.gd")
const BrottBrain = preload("res://game/ai/brottbrain.gd")

func test_card_hp_below_trigger_true() -> bool:
	var card = BehaviorCard.new(BehaviorCard.TriggerType.HP_BELOW, 0.5)
	return card.evaluate_trigger(0.3, 1.0, 5.0, 1.0)

func test_card_hp_below_trigger_false() -> bool:
	var card = BehaviorCard.new(BehaviorCard.TriggerType.HP_BELOW, 0.5)
	return not card.evaluate_trigger(0.7, 1.0, 5.0, 1.0)

func test_card_hp_above_trigger() -> bool:
	var card = BehaviorCard.new(BehaviorCard.TriggerType.HP_ABOVE, 0.5)
	return card.evaluate_trigger(0.7, 1.0, 5.0, 1.0) and not card.evaluate_trigger(0.3, 1.0, 5.0, 1.0)

func test_card_enemy_hp_below() -> bool:
	var card = BehaviorCard.new(BehaviorCard.TriggerType.ENEMY_HP_BELOW, 0.3)
	return card.evaluate_trigger(1.0, 1.0, 5.0, 0.2) and not card.evaluate_trigger(1.0, 1.0, 5.0, 0.5)

func test_card_enemy_in_range() -> bool:
	var card = BehaviorCard.new(BehaviorCard.TriggerType.ENEMY_IN_RANGE, 3.0)
	return card.evaluate_trigger(1.0, 1.0, 2.0, 1.0) and not card.evaluate_trigger(1.0, 1.0, 5.0, 1.0)

func test_card_energy_above() -> bool:
	var card = BehaviorCard.new(BehaviorCard.TriggerType.ENERGY_ABOVE, 0.8)
	return card.evaluate_trigger(1.0, 0.9, 5.0, 1.0) and not card.evaluate_trigger(1.0, 0.5, 5.0, 1.0)

func test_card_energy_below() -> bool:
	var card = BehaviorCard.new(BehaviorCard.TriggerType.ENERGY_BELOW, 0.3)
	return card.evaluate_trigger(1.0, 0.2, 5.0, 1.0) and not card.evaluate_trigger(1.0, 0.5, 5.0, 1.0)

func test_card_always_trigger() -> bool:
	var card = BehaviorCard.new(BehaviorCard.TriggerType.ALWAYS, 0.0)
	return card.evaluate_trigger(1.0, 1.0, 5.0, 1.0)

func test_brain_max_cards() -> bool:
	var brain = BrottBrain.new()
	for i in range(8):
		brain.add_card(BehaviorCard.new())
	return not brain.add_card(BehaviorCard.new())

func test_brain_priority_order() -> bool:
	var brain = BrottBrain.new()
	brain.add_card(BehaviorCard.new(
		BehaviorCard.TriggerType.HP_BELOW, 0.5,
		BehaviorCard.ActionType.SET_STANCE, BehaviorCard.Stance.DEFENSIVE))
	brain.add_card(BehaviorCard.new(
		BehaviorCard.TriggerType.ALWAYS, 0.0,
		BehaviorCard.ActionType.SET_STANCE, BehaviorCard.Stance.AGGRESSIVE))
	var result = brain.evaluate(0.3, 1.0, 5.0, 1.0)
	return result[&"value"] == BehaviorCard.Stance.DEFENSIVE and result[&"source"] == "card"

func test_brain_first_match_wins() -> bool:
	var brain = BrottBrain.new()
	brain.add_card(BehaviorCard.new(
		BehaviorCard.TriggerType.ALWAYS, 0.0,
		BehaviorCard.ActionType.SET_STANCE, BehaviorCard.Stance.KITING))
	brain.add_card(BehaviorCard.new(
		BehaviorCard.TriggerType.ALWAYS, 0.0,
		BehaviorCard.ActionType.SET_STANCE, BehaviorCard.Stance.AGGRESSIVE))
	var result = brain.evaluate(1.0, 1.0, 5.0, 1.0)
	return result[&"value"] == BehaviorCard.Stance.KITING

func test_brain_no_match_returns_stance_default() -> bool:
	var brain = BrottBrain.new()
	brain.stance = BehaviorCard.Stance.KITING
	brain.add_card(BehaviorCard.new(
		BehaviorCard.TriggerType.HP_BELOW, 0.1,
		BehaviorCard.ActionType.SET_STANCE, BehaviorCard.Stance.DEFENSIVE))
	var result = brain.evaluate(1.0, 1.0, 5.0, 1.0)
	return result[&"source"] == "stance_default" and result[&"value"] == BehaviorCard.Stance.KITING

func test_brain_remove_card() -> bool:
	var brain = BrottBrain.new()
	brain.add_card(BehaviorCard.new())
	brain.add_card(BehaviorCard.new())
	brain.remove_card(0)
	return brain.cards.size() == 1

func test_brain_move_card_up() -> bool:
	var brain = BrottBrain.new()
	var c1 = BehaviorCard.new(BehaviorCard.TriggerType.HP_BELOW, 0.5)
	var c2 = BehaviorCard.new(BehaviorCard.TriggerType.ALWAYS, 0.0)
	brain.add_card(c1)
	brain.add_card(c2)
	brain.move_card_up(1)
	return brain.cards[0] == c2

func test_brain_move_card_down() -> bool:
	var brain = BrottBrain.new()
	var c1 = BehaviorCard.new(BehaviorCard.TriggerType.HP_BELOW, 0.5)
	var c2 = BehaviorCard.new(BehaviorCard.TriggerType.ALWAYS, 0.0)
	brain.add_card(c1)
	brain.add_card(c2)
	brain.move_card_down(0)
	return brain.cards[0] == c2

func test_brain_clear_cards() -> bool:
	var brain = BrottBrain.new()
	brain.add_card(BehaviorCard.new())
	brain.add_card(BehaviorCard.new())
	brain.clear_cards()
	return brain.cards.size() == 0

func test_default_brain_creation() -> bool:
	var brain = BrottBrain.create_default()
	return brain.stance == BehaviorCard.Stance.AGGRESSIVE and brain.cards.size() == 3

func test_default_brain_low_hp_goes_defensive() -> bool:
	var brain = BrottBrain.create_default()
	var result = brain.evaluate(0.2, 1.0, 5.0, 1.0)
	return result[&"value"] == BehaviorCard.Stance.DEFENSIVE

func test_default_brain_low_energy_conserves() -> bool:
	var brain = BrottBrain.create_default()
	var result = brain.evaluate(0.5, 0.15, 5.0, 1.0)
	return result[&"action"] == BehaviorCard.ActionType.CONSERVE_ENERGY

func test_get_effective_stance() -> bool:
	var brain = BrottBrain.new()
	brain.stance = BehaviorCard.Stance.KITING
	brain.add_card(BehaviorCard.new(
		BehaviorCard.TriggerType.ALWAYS, 0.0,
		BehaviorCard.ActionType.SET_STANCE, BehaviorCard.Stance.AGGRESSIVE))
	brain.evaluate(1.0, 1.0, 5.0, 1.0)
	return brain.get_effective_stance() == BehaviorCard.Stance.AGGRESSIVE
