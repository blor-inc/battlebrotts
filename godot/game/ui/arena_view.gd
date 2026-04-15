# arena_view.gd — Visual combat arena renderer
# BattleBrotts Sprint 13 · S13-001
#
# Renders the arena grid, bots with health/energy bars, projectiles,
# damage numbers, shield effects, hit flashes, and death explosions.
# All rendering via _draw() — no sprites needed, clean geometric shapes.
extends Control

var arena: ArenaManager = null
var player_brott: Brott = null
var enemy_brott: Brott = null

const CELL_SIZE: int = 32
const BROTT_RADIUS: float = 12.0
const BAR_WIDTH: float = 28.0
const BAR_HEIGHT: float = 4.0
const BAR_OFFSET_HP: float = -20.0  # above bot center
const BAR_OFFSET_EN: float = -14.0  # below HP bar

# Tile colors
const COLORS := {
	0: Color(0.15, 0.18, 0.22),     # Floor — dark gray
	1: Color(0.35, 0.35, 0.40),     # Wall — lighter gray
	2: Color(0.2, 0.35, 0.2),       # Cover — dark green
	3: Color(0.4, 0.35, 0.3),       # Pillar — tan
	4: Color(0.5, 0.15, 0.1),       # Hazard — dark red
}

# Bot colors
const PLAYER_COLOR := Color(0.2, 0.7, 1.0)   # Blue
const ENEMY_COLOR := Color(1.0, 0.3, 0.2)    # Red

# Visual effect state
var _floating_numbers: Array = []  # {position, text, color, ticks_remaining, velocity}
var _hit_flashes: Dictionary = {}  # brott_id → ticks_remaining
var _death_explosions: Array = []  # {position, ticks_remaining, max_ticks}
var _match_over: bool = false
var _match_result: Dictionary = {}
var _result_display_ticks: int = 0

# Last snapshot for projectile rendering
var _last_snapshot: Dictionary = {}


func setup(p_arena: ArenaManager, p_player: Brott, p_enemy: Brott) -> void:
	arena = p_arena
	player_brott = p_player
	enemy_brott = p_enemy
	custom_minimum_size = Vector2(arena.width * CELL_SIZE, arena.height * CELL_SIZE)
	_floating_numbers.clear()
	_hit_flashes.clear()
	_death_explosions.clear()
	_match_over = false
	_match_result = {}
	_result_display_ticks = 0
	_last_snapshot = {}


func on_tick(snapshot: Dictionary) -> void:
	_last_snapshot = snapshot

	# Process visual events from this tick
	var events: Array = snapshot.get("events", [])
	for event in events:
		match event["type"]:
			"damage":
				_spawn_damage_number(event["position"], event["amount"], event["is_crit"])
			"hit":
				_hit_flashes[event["target_id"]] = 3  # flash for 3 ticks
			"death":
				_death_explosions.append({
					"position": event["position"],
					"ticks_remaining": 12,
					"max_ticks": 12,
				})

	# Update floating numbers
	var alive_nums: Array = []
	for num in _floating_numbers:
		num["ticks_remaining"] -= 1
		num["position"] += num["velocity"]
		if num["ticks_remaining"] > 0:
			alive_nums.append(num)
	_floating_numbers = alive_nums

	# Update hit flashes
	var expired_ids: Array = []
	for bid in _hit_flashes:
		_hit_flashes[bid] -= 1
		if _hit_flashes[bid] <= 0:
			expired_ids.append(bid)
	for bid in expired_ids:
		_hit_flashes.erase(bid)

	# Update death explosions
	var alive_explosions: Array = []
	for expl in _death_explosions:
		expl["ticks_remaining"] -= 1
		if expl["ticks_remaining"] > 0:
			alive_explosions.append(expl)
	_death_explosions = alive_explosions

	queue_redraw()


func on_match_finished(result: Dictionary) -> void:
	_match_over = true
	_match_result = result
	_result_display_ticks = 0
	queue_redraw()


func _spawn_damage_number(pos: Vector2, amount: float, is_crit: bool) -> void:
	_floating_numbers.append({
		"position": pos + Vector2(0, -16),
		"text": ("%.0f" % amount) if not is_crit else ("%.0f!" % amount),
		"color": Color.YELLOW if is_crit else Color.WHITE,
		"ticks_remaining": 12,
		"velocity": Vector2(0, -1.5),  # float upward
	})


func _draw() -> void:
	if not arena:
		return

	# 1. Draw tile grid
	for y in arena.height:
		for x in arena.width:
			var tile_type: int = arena.get_tile(Vector2i(x, y))
			var rect := Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(rect, COLORS.get(tile_type, COLORS[0]))
			draw_rect(rect, Color(0.25, 0.28, 0.32), false, 1.0)

	# 2. Draw projectiles
	var projs: Array = _last_snapshot.get("projectiles", [])
	for proj in projs:
		var pos: Vector2 = proj["position"]
		var wid: String = proj["weapon_id"]
		if wid == "missile_pod":
			# Orange rectangle for missiles
			var dir: Vector2 = proj["direction"]
			var angle := dir.angle() if dir.length() > 0 else 0.0
			draw_set_transform(pos, angle)
			draw_rect(Rect2(-4, -2, 8, 4), Color(1.0, 0.6, 0.1))
			draw_set_transform(Vector2.ZERO, 0.0)
		elif wid == "arc_emitter":
			# Yellow line — drawn later if we have attacker pos
			draw_circle(pos, 3, Color(1.0, 1.0, 0.2))
		else:
			# Small white circle for bullets
			draw_circle(pos, 3, Color(0.9, 0.9, 0.9))

	# 3. Draw shield effects (before bots so bot draws on top)
	_draw_shield(player_brott)
	_draw_shield(enemy_brott)

	# 4. Draw bots
	_draw_brott(player_brott, PLAYER_COLOR)
	_draw_brott(enemy_brott, ENEMY_COLOR)

	# 5. Draw in-arena health/energy bars
	_draw_bars(player_brott)
	_draw_bars(enemy_brott)

	# 6. Draw floating damage numbers
	for num in _floating_numbers:
		var alpha: float = float(num["ticks_remaining"]) / 12.0
		var col: Color = num["color"]
		col.a = alpha
		var font := ThemeDB.fallback_font
		var font_size: int = 14 if "!" in num["text"] else 11
		draw_string(font, num["position"], num["text"], HORIZONTAL_ALIGNMENT_CENTER,
			-1, font_size, col)

	# 7. Draw death explosions
	for expl in _death_explosions:
		var progress: float = 1.0 - (float(expl["ticks_remaining"]) / float(expl["max_ticks"]))
		var radius: float = BROTT_RADIUS + progress * 24.0
		var alpha: float = 1.0 - progress
		draw_circle(expl["position"], radius, Color(1.0, 0.3, 0.1, alpha * 0.7))
		draw_circle(expl["position"], radius * 0.6, Color(1.0, 0.8, 0.2, alpha * 0.5))

	# 8. Draw match result overlay
	if _match_over:
		_draw_result_overlay()


func _draw_brott(brott: Brott, base_color: Color) -> void:
	if brott == null or not brott.alive:
		return

	var color := base_color
	# Hit flash: override to white
	if _hit_flashes.has(brott.id):
		color = Color.WHITE

	draw_circle(brott.position, BROTT_RADIUS, color)
	draw_circle(brott.position, BROTT_RADIUS, Color.WHITE, false, 2.0)


func _draw_shield(brott: Brott) -> void:
	if brott == null or not brott.alive or brott.shield_hp <= 0.0:
		return
	var shield_alpha: float = clampf(brott.shield_hp / 40.0, 0.1, 0.4)
	draw_circle(brott.position, BROTT_RADIUS + 6.0, Color(0.3, 0.5, 1.0, shield_alpha))
	draw_circle(brott.position, BROTT_RADIUS + 6.0, Color(0.4, 0.6, 1.0, shield_alpha + 0.2), false, 2.0)


func _draw_bars(brott: Brott) -> void:
	if brott == null or not brott.alive:
		return

	var center := brott.position
	var bar_x := center.x - BAR_WIDTH / 2.0

	# HP bar background
	var hp_rect := Rect2(bar_x, center.y + BAR_OFFSET_HP, BAR_WIDTH, BAR_HEIGHT)
	draw_rect(hp_rect, Color(0.15, 0.15, 0.15))

	# HP bar fill (green→yellow→red)
	var hp_ratio: float = brott.hp_ratio()
	var hp_color := Color.GREEN
	if hp_ratio < 0.3:
		hp_color = Color.RED
	elif hp_ratio < 0.6:
		hp_color = Color.YELLOW
	var hp_fill := Rect2(bar_x, center.y + BAR_OFFSET_HP, BAR_WIDTH * hp_ratio, BAR_HEIGHT)
	draw_rect(hp_fill, hp_color)
	draw_rect(hp_rect, Color(0.4, 0.4, 0.4), false, 1.0)

	# Energy bar background
	var en_rect := Rect2(bar_x, center.y + BAR_OFFSET_EN, BAR_WIDTH, BAR_HEIGHT - 1.0)
	draw_rect(en_rect, Color(0.1, 0.1, 0.15))

	# Energy bar fill (blue)
	var en_ratio: float = brott.energy / Brott.MAX_ENERGY
	var en_fill := Rect2(bar_x, center.y + BAR_OFFSET_EN, BAR_WIDTH * en_ratio, BAR_HEIGHT - 1.0)
	draw_rect(en_fill, Color(0.2, 0.4, 0.9))


func _draw_result_overlay() -> void:
	# Semi-transparent background
	var full_rect := Rect2(Vector2.ZERO, size)
	draw_rect(full_rect, Color(0, 0, 0, 0.5))

	var font := ThemeDB.fallback_font
	var center := size / 2.0

	var winner: int = _match_result.get("winner_team", -1)
	var text: String = "DRAW!"
	var color := Color.YELLOW
	if winner == 0:
		text = "VICTORY!"
		color = Color.GREEN
	elif winner == 1:
		text = "DEFEAT!"
		color = Color.RED

	# Main result text
	draw_string(font, center + Vector2(0, -20), text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, 32, color)

	# Subtext with stats
	var duration: float = _match_result.get("duration_sec", 0.0)
	var sub_text := "Match duration: %.1fs" % duration
	draw_string(font, center + Vector2(0, 15), sub_text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func update_positions() -> void:
	queue_redraw()
