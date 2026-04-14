# pathfinder.gd — A* pathfinding on arena tile grid
# Recalculates every 10 ticks for performance

class_name Pathfinder

## Reference to the arena for walkability queries
var arena: ArenaManager = null

## Cached paths per entity: Dictionary of int (entity_id) → Array[Vector2i]
var cached_paths: Dictionary = {}

## Tick counter for recalculation
var _ticks_since_recalc: Dictionary = {}

## How often to recalculate paths (in ticks)
const RECALC_INTERVAL: int = 10

## Maximum iterations to prevent infinite loops on large grids
const MAX_ITERATIONS: int = 2000


func _init(p_arena: ArenaManager) -> void:
	arena = p_arena


## Request a path for an entity. Uses cache if fresh enough.
func get_path(entity_id: int, from_tile: Vector2i, to_tile: Vector2i, force_recalc: bool = false) -> Array:
	var ticks: int = _ticks_since_recalc.get(entity_id, RECALC_INTERVAL)
	
	if not force_recalc and ticks < RECALC_INTERVAL and cached_paths.has(entity_id):
		_ticks_since_recalc[entity_id] = ticks + 1
		return cached_paths[entity_id]
	
	# Recalculate
	var path := find_path(from_tile, to_tile)
	cached_paths[entity_id] = path
	_ticks_since_recalc[entity_id] = 0
	return path


## Notify that a tick has passed (call once per tick)
func tick() -> void:
	for entity_id in _ticks_since_recalc:
		_ticks_since_recalc[entity_id] += 1


## Clear cached path for an entity
func clear_cache(entity_id: int) -> void:
	cached_paths.erase(entity_id)
	_ticks_since_recalc.erase(entity_id)


## A* pathfinding from start to goal on the tile grid
## Returns Array[Vector2i] of tile positions (empty if no path found)
func find_path(start: Vector2i, goal: Vector2i) -> Array:
	if start == goal:
		return [start]
	
	if arena.blocks_movement(goal):
		return []  # Goal is impassable
	
	# Open set: tiles to evaluate (priority queue using sorted array)
	# Each entry: {pos: Vector2i, f: float}
	var open_set: Array = [{&"pos": start, &"f": 0.0}]
	
	# Closed set: tiles already evaluated
	var closed_set: Dictionary = {}
	
	# g_score: cost from start to this tile
	var g_score: Dictionary = {start: 0.0}
	
	# came_from: for path reconstruction
	var came_from: Dictionary = {}
	
	var iterations: int = 0
	
	while open_set.size() > 0 and iterations < MAX_ITERATIONS:
		iterations += 1
		
		# Get tile with lowest f score
		var current_entry: Dictionary = open_set[0]
		var current_idx: int = 0
		for i in range(1, open_set.size()):
			if open_set[i][&"f"] < current_entry[&"f"]:
				current_entry = open_set[i]
				current_idx = i
		
		var current: Vector2i = current_entry[&"pos"]
		
		# Goal reached
		if current == goal:
			return _reconstruct_path(came_from, current)
		
		open_set.remove_at(current_idx)
		closed_set[current] = true
		
		# Check all walkable neighbors (8-directional)
		var neighbors := arena.get_walkable_neighbors_8dir(current)
		for neighbor in neighbors:
			if closed_set.has(neighbor):
				continue
			
			# Movement cost: 1.0 for cardinal, 1.414 for diagonal
			var move_cost: float = 1.414 if (neighbor - current).x != 0 and (neighbor - current).y != 0 else 1.0
			
			# Hazard tiles have increased cost (AI avoids lava)
			if arena.is_hazard(neighbor):
				move_cost += 5.0
			
			var tentative_g: float = g_score[current] + move_cost
			
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				var f: float = tentative_g + _heuristic(neighbor, goal)
				
				# Add to open set if not already there
				var found := false
				for i in range(open_set.size()):
					if open_set[i][&"pos"] == neighbor:
						open_set[i][&"f"] = f
						found = true
						break
				if not found:
					open_set.append({&"pos": neighbor, &"f": f})
	
	return []  # No path found


## Octile distance heuristic (for 8-directional movement)
func _heuristic(a: Vector2i, b: Vector2i) -> float:
	var dx: int = abs(a.x - b.x)
	var dy: int = abs(a.y - b.y)
	return float(max(dx, dy)) + 0.414 * float(min(dx, dy))


## Reconstruct path from came_from map
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var path: Array = [current]
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	return path
