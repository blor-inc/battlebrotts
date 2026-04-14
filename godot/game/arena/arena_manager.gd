# arena_manager.gd — Arena tile system for BattleBrotts
# Manages tile grid, line-of-sight, and environment effects

class_name ArenaManager

## Tile type enum
enum TileType {
	FLOOR = 0,    ## Walkable, no effect
	WALL = 1,     ## Blocks movement + LoS, indestructible
	COVER = 2,    ## Walkable, 50% miss chance, destructible (50 HP)
	PILLAR = 3,   ## Blocks movement + LoS, indestructible
	HAZARD = 4    ## Walkable, deals damage (lava: 10 dmg/sec ignoring armor)
}

## Constants
const TILE_SIZE: int = 32  ## Pixels per tile
const COVER_MAX_HP: int = 50
const COVER_MISS_CHANCE: float = 0.5  ## 50% miss chance behind cover
const HAZARD_DAMAGE_PER_TICK: float = 0.5  ## 10 dmg/sec at 20 ticks/sec

## Arena dimensions (in tiles)
var width: int = 0
var height: int = 0

## Grid data: 2D array of TileType
var grid: Array = []

## Cover HP tracking: Dictionary of Vector2i → int
var cover_hp: Dictionary = {}

## LoS result structure
class LosResult:
	var blocked: bool = false
	var cover_count: int = 0
	
	func _init(p_blocked: bool = false, p_cover_count: int = 0) -> void:
		blocked = p_blocked
		cover_count = p_cover_count


## Initialize empty arena
func init_arena(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	grid = []
	cover_hp = {}
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(TileType.FLOOR)
		grid.append(row)


## Set a tile type at grid position
func set_tile(pos: Vector2i, tile_type: int) -> void:
	if not _in_bounds(pos):
		return
	grid[pos.y][pos.x] = tile_type
	if tile_type == TileType.COVER:
		cover_hp[pos] = COVER_MAX_HP
	elif cover_hp.has(pos):
		cover_hp.erase(pos)


## Get tile type at grid position
func get_tile(pos: Vector2i) -> int:
	if not _in_bounds(pos):
		return TileType.WALL  # Out of bounds treated as wall
	return grid[pos.y][pos.x]


## Check if a tile blocks movement
func blocks_movement(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	return tile == TileType.WALL or tile == TileType.PILLAR


## Check if a tile blocks line of sight
func blocks_los(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	return tile == TileType.WALL or tile == TileType.PILLAR


## Check if a tile provides cover
func provides_cover(pos: Vector2i) -> bool:
	return get_tile(pos) == TileType.COVER and cover_hp.get(pos, 0) > 0


## Check if a tile is a hazard
func is_hazard(pos: Vector2i) -> bool:
	return get_tile(pos) == TileType.HAZARD


## Check if position is in bounds
func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


## Convert world position (pixels) to tile position
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))


## Convert tile position to world position (center of tile)
func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE / 2.0, tile_pos.y * TILE_SIZE + TILE_SIZE / 2.0)


## Line of Sight check using Bresenham's line algorithm
## Returns LosResult with blocked status and cover count
func check_los(from_tile: Vector2i, to_tile: Vector2i) -> LosResult:
	var result := LosResult.new()
	
	# Same tile — always visible
	if from_tile == to_tile:
		return result
	
	var points := _bresenham_line(from_tile, to_tile)
	
	# Skip first (origin) and last (target) tiles
	for i in range(1, points.size() - 1):
		var point: Vector2i = points[i]
		if blocks_los(point):
			result.blocked = true
			return result
		if provides_cover(point):
			result.cover_count += 1
	
	return result


## Check LoS from world positions (convenience)
func check_los_world(from_world: Vector2, to_world: Vector2) -> LosResult:
	return check_los(world_to_tile(from_world), world_to_tile(to_world))


## Bresenham's line algorithm — returns all tiles the line passes through
func _bresenham_line(from: Vector2i, to: Vector2i) -> Array:
	var points: Array = []
	var dx: int = abs(to.x - from.x)
	var dy: int = abs(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx - dy
	var x: int = from.x
	var y: int = from.y
	
	while true:
		points.append(Vector2i(x, y))
		if x == to.x and y == to.y:
			break
		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
	
	return points


## Apply damage to a cover tile. Returns true if cover was destroyed.
func damage_cover(pos: Vector2i, damage: int) -> bool:
	if not provides_cover(pos):
		return false
	cover_hp[pos] -= damage
	if cover_hp[pos] <= 0:
		cover_hp.erase(pos)
		grid[pos.y][pos.x] = TileType.FLOOR  # Cover destroyed → becomes floor
		return true
	return false


## Get all hazard tiles (for tick damage processing)
func get_hazard_tiles() -> Array:
	var hazards: Array = []
	for y in range(height):
		for x in range(width):
			if grid[y][x] == TileType.HAZARD:
				hazards.append(Vector2i(x, y))
	return hazards


## Get all walkable neighbors of a tile (for pathfinding)
func get_walkable_neighbors(pos: Vector2i) -> Array:
	var neighbors: Array = []
	var directions := [
		Vector2i(0, -1),  # Up
		Vector2i(1, 0),   # Right
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
	]
	for dir: Vector2i in directions:
		var neighbor: Vector2i = pos + dir
		if _in_bounds(neighbor) and not blocks_movement(neighbor):
			neighbors.append(neighbor)
	return neighbors


## Get all walkable neighbors including diagonals (for pathfinding)
func get_walkable_neighbors_8dir(pos: Vector2i) -> Array:
	var neighbors: Array = []
	var directions := [
		Vector2i(0, -1), Vector2i(1, -1),   # Up, Up-Right
		Vector2i(1, 0), Vector2i(1, 1),     # Right, Down-Right
		Vector2i(0, 1), Vector2i(-1, 1),    # Down, Down-Left
		Vector2i(-1, 0), Vector2i(-1, -1),  # Left, Up-Left
	]
	for dir: Vector2i in directions:
		var neighbor: Vector2i = pos + dir
		if _in_bounds(neighbor) and not blocks_movement(neighbor):
			# For diagonals, also check that both adjacent cardinal tiles are walkable
			# (prevents cutting corners through walls)
			if dir.x != 0 and dir.y != 0:
				var adj1 := pos + Vector2i(dir.x, 0)
				var adj2 := pos + Vector2i(0, dir.y)
				if blocks_movement(adj1) or blocks_movement(adj2):
					continue
			neighbors.append(neighbor)
	return neighbors


## Load a predefined arena layout
func load_layout(layout_name: String) -> void:
	match layout_name:
		"the_pit":
			_load_the_pit()
		"junkyard":
			_load_junkyard()
		_:
			push_warning("Unknown arena layout: " + layout_name)


## The Pit — 16×16 open arena with minimal cover
func _load_the_pit() -> void:
	init_arena(16, 16)
	
	# Walls around the border (already handled by out-of-bounds = WALL)
	# Add some cover blocks in the center area
	set_tile(Vector2i(4, 4), TileType.COVER)
	set_tile(Vector2i(4, 11), TileType.COVER)
	set_tile(Vector2i(11, 4), TileType.COVER)
	set_tile(Vector2i(11, 11), TileType.COVER)
	
	# Center pillars
	set_tile(Vector2i(7, 7), TileType.PILLAR)
	set_tile(Vector2i(8, 8), TileType.PILLAR)
	
	# Small lava hazard in corners
	set_tile(Vector2i(0, 0), TileType.HAZARD)
	set_tile(Vector2i(15, 0), TileType.HAZARD)
	set_tile(Vector2i(0, 15), TileType.HAZARD)
	set_tile(Vector2i(15, 15), TileType.HAZARD)


## Junkyard — 20×20 cover-heavy arena
func _load_junkyard() -> void:
	init_arena(20, 20)
	
	# Lots of cover scattered around
	var cover_positions := [
		Vector2i(3, 3), Vector2i(3, 10), Vector2i(3, 16),
		Vector2i(7, 5), Vector2i(7, 14),
		Vector2i(10, 3), Vector2i(10, 10), Vector2i(10, 16),
		Vector2i(12, 7), Vector2i(12, 12),
		Vector2i(16, 3), Vector2i(16, 10), Vector2i(16, 16),
	]
	for pos in cover_positions:
		set_tile(pos, TileType.COVER)
	
	# Wall clusters
	set_tile(Vector2i(5, 9), TileType.WALL)
	set_tile(Vector2i(5, 10), TileType.WALL)
	set_tile(Vector2i(14, 9), TileType.WALL)
	set_tile(Vector2i(14, 10), TileType.WALL)
	
	# Pillars
	set_tile(Vector2i(9, 9), TileType.PILLAR)
	set_tile(Vector2i(10, 10), TileType.PILLAR)
