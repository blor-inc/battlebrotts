# test_shop.gd — Tests for Shop
# BattleBrotts Sprint 5 · S5-003
extends RefCounted

const EconomyManager = preload("res://game/economy/economy_manager.gd")
const Shop = preload("res://game/economy/shop.gd")

func _make_shop(bolts: int = 0) -> Shop:
	var e := EconomyManager.new()
	e.add_bolts(bolts)
	return Shop.new(e)

# ── Catalog ──────────────────────────────────────────────

func test_catalog_chassis_has_all() -> bool:
	var s := _make_shop()
	var catalog := s.get_catalog("chassis")
	return catalog.size() == 3  # scout, brawler, fortress

func test_catalog_weapons_has_all() -> bool:
	var s := _make_shop()
	var catalog := s.get_catalog("weapon")
	return catalog.size() == 7

func test_catalog_shows_owned_status() -> bool:
	var s := _make_shop()
	var catalog := s.get_catalog("chassis")
	var scout_entry = null
	var brawler_entry = null
	for item in catalog:
		if item["id"] == "scout":
			scout_entry = item
		elif item["id"] == "brawler":
			brawler_entry = item
	return scout_entry != null and scout_entry["owned"] == true \
		and brawler_entry != null and brawler_entry["owned"] == false

func test_purchasable_excludes_owned() -> bool:
	var s := _make_shop()
	var purchasable := s.get_purchasable("weapon")
	for item in purchasable:
		if item["id"] == "minigun" or item["id"] == "plasma_cutter":
			return false  # These are owned starters
	return purchasable.size() == 5  # 7 total - 2 starters

# ── Buying ───────────────────────────────────────────────

func test_buy_success() -> bool:
	var s := _make_shop(200)
	var result := s.buy("chassis", "brawler")
	return result["success"] and result["cost"] == 200 and s.get_player_bolts() == 0

func test_buy_insufficient_bolts() -> bool:
	var s := _make_shop(50)
	var result := s.buy("chassis", "brawler")
	return not result["success"] and result["reason"] == "insufficient_bolts"

func test_buy_already_owned() -> bool:
	var s := _make_shop(500)
	var result := s.buy("weapon", "minigun")
	return not result["success"] and result["reason"] == "already_owned"

func test_can_buy_true() -> bool:
	var s := _make_shop(300)
	return s.can_buy("weapon", "railgun")

func test_can_buy_false_no_bolts() -> bool:
	var s := _make_shop(50)
	return not s.can_buy("weapon", "railgun")

func test_can_buy_false_already_owned() -> bool:
	var s := _make_shop(500)
	return not s.can_buy("weapon", "minigun")

func test_buy_free_item() -> bool:
	# If somehow a free item isn't owned yet
	var s := _make_shop(0)
	# Scout is already owned by default, test with an edge case
	# Just verify buying an owned free item fails
	var result := s.buy("chassis", "scout")
	return not result["success"]  # Already owned

func test_sequential_purchases() -> bool:
	var s := _make_shop(500)
	var r1 := s.buy("weapon", "shotgun")   # 120
	var r2 := s.buy("weapon", "arc_emitter")  # 150
	return r1["success"] and r2["success"] and s.get_player_bolts() == 230
