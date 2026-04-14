# test_pathfinder.gd — Tests for A* Pathfinder
extends RefCounted

const ArenaManager = preload("res://game/arena/arena_manager.gd")
const Pathfinder = preload("res://game/arena/pathfinder.gd")

func _make_arena_and_pf(w: int = 10, h: int = 10) -> Array:
	var a = ArenaManager.new()
	a.init_arena(w, h)
	var pf = Pathfinder.new(a)
	return [a, pf]

func test_same_start_goal() -> bool:
	var ap = _make_arena_and_pf()
	var pf = ap[1]
	var path = pf.find_path(Vector2i(3, 3), Vector2i(3, 3))
	return path.size() == 1 and path[0] == Vector2i(3, 3)

func test_straight_line_path() -> bool:
	var ap = _make_arena_and_pf()
	var pf = ap[1]
	var path = pf.find_path(Vector2i(0, 0), Vector2i(5, 0))
	return path.size() > 0 and path[0] == Vector2i(0, 0) and path[path.size() - 1] == Vector2i(5, 0)

func test_path_around_obstacle() -> bool:
	var ap = _make_arena_and_pf()
	var a = ap[0]
	var pf = ap[1]
	a.set_tile(Vector2i(3, 0), ArenaManager.TileType.WALL)
	a.set_tile(Vector2i(3, 1), ArenaManager.TileType.WALL)
	a.set_tile(Vector2i(3, 2), ArenaManager.TileType.WALL)
	var path = pf.find_path(Vector2i(0, 0), Vector2i(5, 0))
	if path.size() == 0:
		return false
	for p in path:
		if a.blocks_movement(p):
			return false
	return path[path.size() - 1] == Vector2i(5, 0)

func test_no_path_to_blocked_goal() -> bool:
	var ap = _make_arena_and_pf()
	var a = ap[0]
	var pf = ap[1]
	a.set_tile(Vector2i(5, 5), ArenaManager.TileType.WALL)
	var path = pf.find_path(Vector2i(0, 0), Vector2i(5, 5))
	return path.size() == 0

func test_hazard_avoidance() -> bool:
	var ap = _make_arena_and_pf()
	var a = ap[0]
	var pf = ap[1]
	for x in range(10):
		a.set_tile(Vector2i(x, 2), ArenaManager.TileType.HAZARD)
	var path = pf.find_path(Vector2i(0, 0), Vector2i(9, 4))
	return path.size() > 0

func test_path_caching() -> bool:
	var ap = _make_arena_and_pf()
	var pf = ap[1]
	var path1 = pf.get_path(1, Vector2i(0, 0), Vector2i(5, 5))
	var path2 = pf.get_path(1, Vector2i(0, 0), Vector2i(5, 5))
	return path1.size() == path2.size()

func test_cache_force_recalc() -> bool:
	var ap = _make_arena_and_pf()
	var pf = ap[1]
	var path1 = pf.get_path(1, Vector2i(0, 0), Vector2i(5, 5))
	var path2 = pf.get_path(1, Vector2i(0, 0), Vector2i(5, 5), true)
	return path1.size() > 0 and path2.size() > 0

func test_diagonal_movement() -> bool:
	var ap = _make_arena_and_pf()
	var pf = ap[1]
	var path = pf.find_path(Vector2i(0, 0), Vector2i(3, 3))
	return path.size() > 0 and path.size() <= 4

func test_heuristic_admissible() -> bool:
	var ap = _make_arena_and_pf()
	var pf = ap[1]
	var h = pf._heuristic(Vector2i(0, 0), Vector2i(3, 4))
	var actual_min = 3.0 * 1.414 + 1.0
	return h <= actual_min + 0.01
