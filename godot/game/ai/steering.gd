# steering.gd — Stance-based movement behaviors
# Produces target positions for pathfinder based on current stance

class_name Steering

## Reference to arena for cover/tile queries
var arena: ArenaManager = null

## Reference to pathfinder
var pathfinder: Pathfinder = null


func _init(p_arena: ArenaManager, p_pathfinder: Pathfinder) -> void:
	arena = p_arena
	pathfinder = p_pathfinder


## Get target tile for a brott based on its stance and game state
## Returns Vector2i target tile position
func get_target(stance: int, brott_tile: Vector2i, enemy_tile: Vector2i,
		weapon_range_tiles: float) -> Vector2i:
	match stance:
		BehaviorCard.Stance.AGGRESSIVE:
			return _aggressive(brott_tile, enemy_tile, weapon_range_tiles)
		BehaviorCard.Stance.DEFENSIVE:
			return _defensive(brott_tile, enemy_tile, weapon_range_tiles)
		BehaviorCard.Stance.KITING:
			return _kiting(brott_tile, enemy_tile, weapon_range_tiles)
		BehaviorCard.Stance.AMBUSH:
			return _ambush(brott_tile, enemy_tile, weapon_range_tiles)
	return brott_tile  # Fallback: hold position


## Aggressive: Move toward enemy, close to weapon range
func _aggressive(brott_tile: Vector2i, enemy_tile: Vector2i, weapon_range: float) -> Vector2i:
	var dist := _tile_distance(brott_tile, enemy_tile)
	
	# Already in weapon range — hold position
	if dist <= weapon_range:
		return brott_tile
	
	# Move toward enemy — target is weapon_range distance from enemy
	var direction := Vector2(enemy_tile - brott_tile).normalized()
	var target_dist := dist - weapon_range
	var offset := direction * target_dist
	var target := Vector2i(brott_tile) + Vector2i(Vector2(offset.x, offset.y).round())
	
	# Clamp to arena bounds
	target.x = clampi(target.x, 0, arena.width - 1)
	target.y = clampi(target.y, 0, arena.height - 1)
	
	# If target is blocked, find nearest walkable tile toward enemy
	if arena.blocks_movement(target):
		target = _find_nearest_walkable(target, enemy_tile)
	
	return target


## Defensive: Retreat to nearest cover, maintain max weapon range
func _defensive(brott_tile: Vector2i, enemy_tile: Vector2i, weapon_range: float) -> Vector2i:
	# Find nearest cover tile
	var cover_tile := _find_nearest_cover(brott_tile, enemy_tile)
	
	if cover_tile != Vector2i(-1, -1):
		return cover_tile
	
	# No cover available — retreat to max range from enemy
	var dist := _tile_distance(brott_tile, enemy_tile)
	if dist < weapon_range:
		# Move away from enemy
		var direction := Vector2(brott_tile - enemy_tile).normalized()
		var retreat := Vector2i(brott_tile) + Vector2i(Vector2(direction * 3.0).round())
		retreat.x = clampi(retreat.x, 0, arena.width - 1)
		retreat.y = clampi(retreat.y, 0, arena.height - 1)
		if not arena.blocks_movement(retreat):
			return retreat
	
	return brott_tile  # Hold position if can't retreat


## Kiting: Maintain 60-80% max weapon range, circle-strafe clockwise
func _kiting(brott_tile: Vector2i, enemy_tile: Vector2i, weapon_range: float) -> Vector2i:
	var dist := _tile_distance(brott_tile, enemy_tile)
	var ideal_min := weapon_range * 0.6
	var ideal_max := weapon_range * 0.8
	var ideal_dist := (ideal_min + ideal_max) / 2.0
	
	# Direction from enemy to brott
	var away := Vector2(brott_tile - enemy_tile)
	if away.length() < 0.01:
		away = Vector2(1, 0)  # Arbitrary direction if overlapping
	away = away.normalized()
	
	# Clockwise perpendicular (rotate 90° clockwise)
	var strafe := Vector2(away.y, -away.x)
	
	# Blend: move to ideal distance + strafe
	var target_dir: Vector2
	if dist < ideal_min:
		# Too close — retreat + strafe
		target_dir = (away * 2.0 + strafe).normalized()
	elif dist > ideal_max:
		# Too far — approach + strafe
		target_dir = (-away + strafe * 2.0).normalized()
	else:
		# In sweet spot — just strafe
		target_dir = strafe
	
	var target := Vector2i(Vector2(brott_tile) + target_dir * 3.0)
	target.x = clampi(target.x, 0, arena.width - 1)
	target.y = clampi(target.y, 0, arena.height - 1)
	
	if arena.blocks_movement(target):
		target = _find_nearest_walkable(target, brott_tile)
	
	return target


## Ambush: Move to cover, hold position, engage at 50% weapon range
func _ambush(brott_tile: Vector2i, enemy_tile: Vector2i, weapon_range: float) -> Vector2i:
	var dist := _tile_distance(brott_tile, enemy_tile)
	
	# If we're in cover, hold position
	if arena.provides_cover(brott_tile):
		return brott_tile
	
	# If enemy is within 50% weapon range and we're in cover nearby, hold
	# Otherwise, find cover
	var cover_tile := _find_nearest_cover(brott_tile, enemy_tile)
	if cover_tile != Vector2i(-1, -1):
		# Move to adjacent tile (behind cover relative to enemy)
		var behind := _get_tile_behind_cover(cover_tile, enemy_tile)
		if behind != Vector2i(-1, -1):
			return behind
		return cover_tile
	
	# No cover — just hold position
	return brott_tile


## Find nearest cover tile that provides protection from enemy direction
func _find_nearest_cover(from_tile: Vector2i, enemy_tile: Vector2i) -> Vector2i:
	var best_tile := Vector2i(-1, -1)
	var best_dist := INF
	
	for y in range(arena.height):
		for x in range(arena.width):
			var tile := Vector2i(x, y)
			if arena.provides_cover(tile):
				var dist := _tile_distance(from_tile, tile)
				if dist < best_dist:
					best_dist = dist
					best_tile = tile
	
	return best_tile


## Get a walkable tile behind cover (relative to enemy)
func _get_tile_behind_cover(cover_tile: Vector2i, enemy_tile: Vector2i) -> Vector2i:
	var dir := Vector2(cover_tile - enemy_tile).normalized()
	var behind := cover_tile + Vector2i(Vector2(dir).round())
	
	if arena._in_bounds(behind) and not arena.blocks_movement(behind):
		return behind
	
	# Try adjacent tiles
	for neighbor in arena.get_walkable_neighbors(cover_tile):
		# Prefer tiles farther from enemy
		if _tile_distance(neighbor, enemy_tile) > _tile_distance(cover_tile, enemy_tile):
			return neighbor
	
	return Vector2i(-1, -1)


## Find nearest walkable tile to target, searching from a reference point
func _find_nearest_walkable(target: Vector2i, reference: Vector2i) -> Vector2i:
	var best := target
	var best_dist := INF
	
	# Search in a small radius around the target
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var candidate := target + Vector2i(dx, dy)
			if arena._in_bounds(candidate) and not arena.blocks_movement(candidate):
				var dist := _tile_distance(candidate, reference)
				if dist < best_dist:
					best_dist = dist
					best = candidate
	
	return best


## Euclidean distance between two tiles
func _tile_distance(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a - b).length()
