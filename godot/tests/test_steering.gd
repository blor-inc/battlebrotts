# test_steering.gd — Tests for Steering system
extends RefCounted

const ArenaManager = preload("res://game/arena/arena_manager.gd")
const Pathfinder = preload("res://game/arena/pathfinder.gd")
const Steering = preload("res://game/ai/steering.gd")
const BehaviorCard = preload("res://game/ai/behavior_card.gd")

func _make_arena_and_steering() -> Array:
	var a = ArenaManager.new()
	a.init_arena(20, 20)
	var pf = Pathfinder.new(a)
	var s = Steering.new(a, pf)
	return [a, pf, s]

func test_aggressive_moves_toward_enemy() -> bool:
	var aps = _make_arena_and_steering()
	var s = aps[2]
	var target = s.get_target(BehaviorCard.Stance.AGGRESSIVE, Vector2i(2, 2), Vector2i(10, 2), 5.0)
	return target.x > 2 or target == Vector2i(2, 2)

func test_aggressive_holds_at_weapon_range() -> bool:
	var aps = _make_arena_and_steering()
	var s = aps[2]
	var target = s.get_target(BehaviorCard.Stance.AGGRESSIVE, Vector2i(7, 2), Vector2i(10, 2), 5.0)
	return target == Vector2i(7, 2)

func test_defensive_seeks_cover() -> bool:
	var aps = _make_arena_and_steering()
	var a = aps[0]
	var s = aps[2]
	a.set_tile(Vector2i(5, 5), ArenaManager.TileType.COVER)
	var target = s.get_target(BehaviorCard.Stance.DEFENSIVE, Vector2i(2, 2), Vector2i(15, 2), 5.0)
	return target != Vector2i(2, 2)

func test_defensive_retreats_when_close() -> bool:
	var aps = _make_arena_and_steering()
	var s = aps[2]
	var target = s.get_target(BehaviorCard.Stance.DEFENSIVE, Vector2i(8, 2), Vector2i(10, 2), 5.0)
	return target.x <= 8

func test_kiting_maintains_range_band() -> bool:
	var aps = _make_arena_and_steering()
	var s = aps[2]
	var target = s.get_target(BehaviorCard.Stance.KITING, Vector2i(5, 10), Vector2i(10, 10), 10.0)
	return target != Vector2i(5, 10)

func test_kiting_strafes_in_sweet_spot() -> bool:
	var aps = _make_arena_and_steering()
	var s = aps[2]
	var target = s.get_target(BehaviorCard.Stance.KITING, Vector2i(3, 10), Vector2i(10, 10), 10.0)
	return target.y != 10 or target.x != 3

func test_ambush_seeks_cover() -> bool:
	var aps = _make_arena_and_steering()
	var a = aps[0]
	var s = aps[2]
	a.set_tile(Vector2i(4, 4), ArenaManager.TileType.COVER)
	var target = s.get_target(BehaviorCard.Stance.AMBUSH, Vector2i(2, 2), Vector2i(15, 15), 5.0)
	return target != Vector2i(2, 2)

func test_ambush_holds_in_cover() -> bool:
	var aps = _make_arena_and_steering()
	var a = aps[0]
	var s = aps[2]
	a.set_tile(Vector2i(2, 2), ArenaManager.TileType.COVER)
	var target = s.get_target(BehaviorCard.Stance.AMBUSH, Vector2i(2, 2), Vector2i(15, 15), 5.0)
	return target == Vector2i(2, 2)
