# arena_view.gd — Simple 2D arena renderer for The Pit
# BattleBrotts Sprint 4 · S4-001
#
# Renders the arena grid and brott positions using draw calls.
# No sprites needed — uses colored rectangles and circles.
extends Control

var arena: ArenaManager = null
var player_brott: Brott = null
var enemy_brott: Brott = null

const CELL_SIZE: int = 32
const BROTT_RADIUS: float = 12.0

# Tile colors
const COLORS := {
	0: Color(0.15, 0.18, 0.22),     # Floor — dark gray
	1: Color(0.35, 0.35, 0.40),     # Wall — lighter gray
	2: Color(0.2, 0.35, 0.2),       # Cover — dark green
	3: Color(0.4, 0.35, 0.3),       # Pillar — tan
	4: Color(0.5, 0.15, 0.1),       # Hazard — dark red
}


func setup(p_arena: ArenaManager, p_player: Brott, p_enemy: Brott) -> void:
	arena = p_arena
	player_brott = p_player
	enemy_brott = p_enemy
	custom_minimum_size = Vector2(arena.width * CELL_SIZE, arena.height * CELL_SIZE)


func _draw() -> void:
	if not arena:
		return

	# Draw grid
	for y in arena.height:
		for x in arena.width:
			var tile_type: int = arena.get_tile(Vector2i(x, y))
			var rect := Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(rect, COLORS.get(tile_type, COLORS[0]))
			# Grid lines
			draw_rect(rect, Color(0.25, 0.28, 0.32), false, 1.0)

	# Draw brotts
	if player_brott and player_brott.alive:
		draw_circle(player_brott.position, BROTT_RADIUS, Color(0.2, 0.7, 1.0))
		draw_circle(player_brott.position, BROTT_RADIUS, Color.WHITE, false, 2.0)

	if enemy_brott and enemy_brott.alive:
		draw_circle(enemy_brott.position, BROTT_RADIUS, Color(1.0, 0.3, 0.2))
		draw_circle(enemy_brott.position, BROTT_RADIUS, Color.WHITE, false, 2.0)


func update_positions() -> void:
	queue_redraw()
