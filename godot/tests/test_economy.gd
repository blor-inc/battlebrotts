# test_economy.gd — Tests for EconomyManager
# BattleBrotts Sprint 5 · S5-003
extends RefCounted

const EconomyManager = preload("res://game/economy/economy_manager.gd")

func _make_economy() -> EconomyManager:
	return EconomyManager.new()

# ── Currency ─────────────────────────────────────────────

func test_initial_bolts_zero() -> bool:
	var e := _make_economy()
	return e.bolts == 0

func test_add_bolts() -> bool:
	var e := _make_economy()
	e.add_bolts(100)
	return e.bolts == 100

func test_spend_bolts_success() -> bool:
	var e := _make_economy()
	e.add_bolts(200)
	var ok := e.spend_bolts(150)
	return ok and e.bolts == 50

func test_spend_bolts_insufficient() -> bool:
	var e := _make_economy()
	e.add_bolts(50)
	var ok := e.spend_bolts(100)
	return not ok and e.bolts == 50

func test_can_afford_true() -> bool:
	var e := _make_economy()
	e.add_bolts(200)
	return e.can_afford(200)

func test_can_afford_false() -> bool:
	var e := _make_economy()
	e.add_bolts(50)
	return not e.can_afford(100)

# ── Match Rewards ────────────────────────────────────────

func test_award_win() -> bool:
	var e := _make_economy()
	var earned := e.award_match_result(true, "opp_1")
	# First win = 200
	return earned == 200 and e.bolts == 200

func test_award_win_repeat() -> bool:
	var e := _make_economy()
	e.award_match_result(true, "opp_1")  # First win: 200
	var earned := e.award_match_result(true, "opp_1")  # Repeat: 100
	return earned == 100 and e.bolts == 300

func test_award_loss() -> bool:
	var e := _make_economy()
	var earned := e.award_match_result(false, "opp_1")
	return earned == 40 and e.bolts == 40

func test_first_win_different_opponents() -> bool:
	var e := _make_economy()
	var e1 := e.award_match_result(true, "opp_1")  # 200
	var e2 := e.award_match_result(true, "opp_2")  # 200
	return e1 == 200 and e2 == 200 and e.bolts == 400

# ── Repair ───────────────────────────────────────────────

func test_repair_cost_win() -> bool:
	var e := _make_economy()
	var cost := e.calc_repair_cost(500, true)
	return cost == 20  # Flat 20 bolts

func test_repair_cost_loss() -> bool:
	var e := _make_economy()
	var cost := e.calc_repair_cost(500, false)
	return cost == 50  # Flat 50 bolts

func test_repair_cost_zero_value() -> bool:
	var e := _make_economy()
	var cost := e.calc_repair_cost(0, true)
	return cost == 20  # Flat rate regardless of equipment value

func test_pay_repair_success() -> bool:
	var e := _make_economy()
	e.add_bolts(200)
	var result := e.pay_repair(["shotgun"], "plating", [], true)
	# Flat repair cost: 20 bolts on win
	return result["paid"] and result["cost"] == 20 and e.bolts == 180

func test_pay_repair_insufficient() -> bool:
	var e := _make_economy()
	e.add_bolts(5)
	var result := e.pay_repair(["railgun", "missile_pod"], "ablative_shell", ["emp_charge"], false)
	# Flat repair cost: 50 bolts on loss
	return not result["paid"] and result["cost"] == 50 and e.bolts == 5

func test_equipment_value_starters_free() -> bool:
	var e := _make_economy()
	var value := e.calc_equipment_value(["minigun", "plasma_cutter"], "plating", [])
	return value == 50  # minigun=50, plasma_cutter=0, plating=0

func test_equipment_value_mixed() -> bool:
	var e := _make_economy()
	var value := e.calc_equipment_value(["shotgun", "minigun"], "reactive_mesh", ["overclock"])
	# shotgun=120, minigun=50, reactive=150, overclock=100 → 420
	return value == 420

# ── Ownership ────────────────────────────────────────────

func test_starter_items_owned() -> bool:
	var e := _make_economy()
	return e.owns_item("chassis", "scout") and e.owns_item("weapon", "plasma_cutter") and e.owns_item("armor", "plating")

func test_non_starter_not_owned() -> bool:
	var e := _make_economy()
	return not e.owns_item("chassis", "brawler") and not e.owns_item("weapon", "railgun")

func test_purchase_item_success() -> bool:
	var e := _make_economy()
	e.add_bolts(200)
	var result := e.purchase_item("chassis", "brawler")
	return result["success"] and e.owns_item("chassis", "brawler") and e.bolts == 0

func test_purchase_item_already_owned() -> bool:
	var e := _make_economy()
	e.add_bolts(500)
	var result := e.purchase_item("weapon", "plasma_cutter")
	return not result["success"] and result["reason"] == "already_owned"

func test_purchase_item_insufficient_bolts() -> bool:
	var e := _make_economy()
	e.add_bolts(50)
	var result := e.purchase_item("chassis", "brawler")
	return not result["success"] and result["reason"] == "insufficient_bolts" \
		and not e.owns_item("chassis", "brawler")

func test_purchase_invalid_item() -> bool:
	var e := _make_economy()
	e.add_bolts(1000)
	var result := e.purchase_item("weapon", "nonexistent")
	return not result["success"] and result["reason"] == "invalid_item"

# ── Save/Load ────────────────────────────────────────────

func test_save_load_roundtrip() -> bool:
	var e := _make_economy()
	e.add_bolts(500)
	e.purchase_item("chassis", "brawler")
	e.award_match_result(true, "opp_1")
	var data := e.to_dict()

	var e2 := EconomyManager.new()
	e2.from_dict(data)
	return e2.bolts == e.bolts and e2.owns_item("chassis", "brawler") \
		and e2.first_wins.has("opp_1")
