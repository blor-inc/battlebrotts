# test_arena.gd — Tests for ArenaManager
extends RefCounted

const ArenaManager = preload("res://game/arena/arena_manager.gd")

func _make_arena(w: int = 10, h: int = 10):
	var a = ArenaManager.new()
	a.init_arena(w, h)
	return a

func test_init_size() -> bool:
	var a = _make_arena(16, 16)
	return a.width == 16 and a.height == 16

func test_init_all_floor() -> bool:
	var a = _make_arena(5, 5)
	for y in range(5):
		for x in range(5):
			if a.get_tile(Vector2i(x, y)) != ArenaManager.TileType.FLOOR:
				return false
	return true

func test_set_and_get_tile() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(3, 3), ArenaManager.TileType.WALL)
	return a.get_tile(Vector2i(3, 3)) == ArenaManager.TileType.WALL

func test_out_of_bounds_returns_wall() -> bool:
	var a = _make_arena(10, 10)
	return a.get_tile(Vector2i(-1, 0)) == ArenaManager.TileType.WALL and a.get_tile(Vector2i(10, 0)) == ArenaManager.TileType.WALL

func test_wall_blocks_movement() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(5, 5), ArenaManager.TileType.WALL)
	return a.blocks_movement(Vector2i(5, 5))

func test_pillar_blocks_movement() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(5, 5), ArenaManager.TileType.PILLAR)
	return a.blocks_movement(Vector2i(5, 5))

func test_floor_doesnt_block_movement() -> bool:
	var a = _make_arena()
	return not a.blocks_movement(Vector2i(0, 0))

func test_cover_doesnt_block_movement() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(5, 5), ArenaManager.TileType.COVER)
	return not a.blocks_movement(Vector2i(5, 5))

func test_hazard_doesnt_block_movement() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(5, 5), ArenaManager.TileType.HAZARD)
	return not a.blocks_movement(Vector2i(5, 5))

func test_wall_blocks_los() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(5, 5), ArenaManager.TileType.WALL)
	return a.blocks_los(Vector2i(5, 5))

func test_floor_doesnt_block_los() -> bool:
	var a = _make_arena()
	return not a.blocks_los(Vector2i(0, 0))

func test_cover_provides_cover() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(3, 3), ArenaManager.TileType.COVER)
	return a.provides_cover(Vector2i(3, 3))

func test_cover_has_hp() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(3, 3), ArenaManager.TileType.COVER)
	return a.cover_hp[Vector2i(3, 3)] == 50

func test_cover_destruction() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(3, 3), ArenaManager.TileType.COVER)
	var destroyed = a.damage_cover(Vector2i(3, 3), 50)
	return destroyed and a.get_tile(Vector2i(3, 3)) == ArenaManager.TileType.FLOOR and not a.provides_cover(Vector2i(3, 3))

func test_cover_partial_damage() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(3, 3), ArenaManager.TileType.COVER)
	var destroyed = a.damage_cover(Vector2i(3, 3), 20)
	return not destroyed and a.cover_hp[Vector2i(3, 3)] == 30 and a.provides_cover(Vector2i(3, 3))

func test_hazard_detection() -> bool:
	var a = _make_arena()
	a.set_tile(Vector2i(2, 2), ArenaManager.TileType.HAZARD)
	return a.is_hazard(Vector2i(2, 2)) and not a.is_hazard(Vector2i(0, 0))

func test_los_clear_path() -> bool:
	var a = _make_arena(10, 10)
	var result = a.check_los(Vector2i(0, 0), Vector2i(5, 5))
	return not result.blocked and result.cover_count == 0

func test_los_blocked_by_wall() -> bool:
	var a = _make_arena(10, 10)
	a.set_tile(Vector2i(3, 3), ArenaManager.TileType.WALL)
	var result = a.check_los(Vector2i(0, 0), Vector2i(5, 5))
	return result.blocked

func test_los_cover_in_path() -> bool:
	var a = _make_arena(10, 10)
	a.set_tile(Vector2i(3, 3), ArenaManager.TileType.COVER)
	var result = a.check_los(Vector2i(0, 0), Vector2i(5, 5))
	return not result.blocked and result.cover_count >= 1

func test_los_same_tile() -> bool:
	var a = _make_arena()
	var result = a.check_los(Vector2i(5, 5), Vector2i(5, 5))
	return not result.blocked

func test_world_to_tile() -> bool:
	var a = _make_arena()
	var tile = a.world_to_tile(Vector2(48, 80))
	return tile == Vector2i(1, 2)

func test_tile_to_world() -> bool:
	var a = _make_arena()
	var world = a.tile_to_world(Vector2i(1, 2))
	return world == Vector2(48, 80)

func test_walkable_neighbors_4dir() -> bool:
	var a = _make_arena(5, 5)
	a.set_tile(Vector2i(3, 2), ArenaManager.TileType.WALL)
	var neighbors = a.get_walkable_neighbors(Vector2i(2, 2))
	return neighbors.size() == 3 and not neighbors.has(Vector2i(3, 2))

func test_walkable_neighbors_8dir() -> bool:
	var a = _make_arena(5, 5)
	var neighbors = a.get_walkable_neighbors_8dir(Vector2i(2, 2))
	return neighbors.size() == 8

func test_diagonal_corner_cutting_blocked() -> bool:
	var a = _make_arena(5, 5)
	a.set_tile(Vector2i(3, 2), ArenaManager.TileType.WALL)
	var neighbors = a.get_walkable_neighbors_8dir(Vector2i(2, 2))
	return not neighbors.has(Vector2i(3, 1))

func test_load_the_pit() -> bool:
	var a = ArenaManager.new()
	a.load_layout("the_pit")
	return a.width == 16 and a.height == 16

func test_load_junkyard() -> bool:
	var a = ArenaManager.new()
	a.load_layout("junkyard")
	return a.width == 20 and a.height == 20
