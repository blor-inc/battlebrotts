# campaign_controller.gd — Master campaign loop
# BattleBrotts Sprint 6 · S6-001
#
# Ties all systems together: Shop → Loadout → Opponent Select → Match → Result → repeat.
# Manages player state (economy, progression, inventory) across the full game loop.
class_name CampaignController

# ── Signals ──────────────────────────────────────────────
signal phase_changed(phase: String)
signal campaign_complete(league: String)

# ── Phases ───────────────────────────────────────────────
enum Phase { SHOP, LOADOUT, OPPONENT_SELECT, MATCH, RESULT, LEAGUE_COMPLETE }

const PHASE_NAMES := {
	Phase.SHOP: "shop",
	Phase.LOADOUT: "loadout",
	Phase.OPPONENT_SELECT: "opponent_select",
	Phase.MATCH: "match",
	Phase.RESULT: "result",
	Phase.LEAGUE_COMPLETE: "league_complete",
}

# ── State ────────────────────────────────────────────────
var current_phase: Phase = Phase.SHOP
var economy: EconomyManager = null
var shop: Shop = null
var league: LeagueManager = null
var game_controller: GameController = null

# Match context
var selected_opponent_index: int = -1
var last_match_result: Dictionary = {}
var last_bolts_earned: int = 0
var last_repair_cost: int = 0

# Starting bolts
const STARTING_BOLTS: int = 200

# ─────────────────────────────────────────────────────────
# Init
# ─────────────────────────────────────────────────────────
func _init() -> void:
	economy = EconomyManager.new()
	shop = Shop.new(economy)
	league = LeagueManager.new()
	game_controller = GameController.new()


func new_game() -> void:
	"""Start a fresh campaign."""
	economy.reset()
	economy.add_bolts(STARTING_BOLTS)
	league.reset()

	# Set default loadout from starter items
	game_controller.player_chassis = "scout"
	game_controller.player_weapons = ["minigun"]
	game_controller.player_armor = "plating"
	game_controller.player_modules = []

	_go_to_phase(Phase.SHOP)

# ─────────────────────────────────────────────────────────
# Phase transitions
# ─────────────────────────────────────────────────────────
func _go_to_phase(phase: Phase) -> void:
	current_phase = phase
	phase_changed.emit(PHASE_NAMES[phase])


func go_to_shop() -> void:
	_go_to_phase(Phase.SHOP)


func go_to_loadout() -> void:
	_go_to_phase(Phase.LOADOUT)


func go_to_opponent_select() -> void:
	_go_to_phase(Phase.OPPONENT_SELECT)


func start_match(opponent_index: int) -> Dictionary:
	"""Start a match against the selected opponent. Returns match result."""
	selected_opponent_index = opponent_index
	var opponent := league.get_opponent(league.current_league, opponent_index)
	if opponent.is_empty():
		return {"error": "invalid_opponent"}

	# Configure enemy loadout on game controller
	game_controller.match_manager = MatchManager.new()
	game_controller.match_manager.match_ended.connect(_on_match_ended)

	# Build player brott
	var arena := ArenaManager.new()
	arena.load_layout("the_pit")
	game_controller.arena = arena

	game_controller.player_brott = Brott.create(
		0, 0, game_controller.player_chassis,
		game_controller.player_weapons,
		game_controller.player_armor,
		game_controller.player_modules,
		Vector2(2 * 32, 8 * 32)
	)

	# Build enemy brott
	game_controller.enemy_brott = Brott.create(
		1, 1, opponent["chassis"],
		opponent["weapons"],
		opponent.get("armor", ""),
		opponent.get("modules", []),
		Vector2(13 * 32, 8 * 32)
	)

	# Run match
	game_controller.match_manager.setup_match(
		[game_controller.player_brott],
		[game_controller.enemy_brott]
	)
	game_controller.match_manager.start_match()

	_go_to_phase(Phase.MATCH)

	# Run full simulation
	var result := game_controller.run_full_simulation()
	return result


func _on_match_ended(result: Dictionary) -> void:
	last_match_result = result
	_process_match_rewards()
	_go_to_phase(Phase.RESULT)


func _process_match_rewards() -> void:
	"""Process economy rewards and repair costs after a match."""
	var won: bool = last_match_result.get("winner_team", -1) == 0
	var opp_id := league.get_opponent_id(league.current_league, selected_opponent_index)

	# Award bolts
	last_bolts_earned = economy.award_match_result(won, opp_id)

	# Pay repair costs
	var repair := economy.pay_repair(
		game_controller.player_weapons,
		game_controller.player_armor,
		game_controller.player_modules,
		won
	)
	last_repair_cost = repair["cost"]

	# Record in league
	league.record_match(league.current_league, selected_opponent_index, won)


func finish_result() -> void:
	"""Called when player dismisses result screen."""
	if league.is_league_beaten(league.current_league):
		_go_to_phase(Phase.LEAGUE_COMPLETE)
		campaign_complete.emit(league.current_league)
	else:
		_go_to_phase(Phase.SHOP)

# ─────────────────────────────────────────────────────────
# Shop helpers
# ─────────────────────────────────────────────────────────
func buy_item(item_type: String, item_id: String) -> Dictionary:
	return shop.buy(item_type, item_id)


func get_shop_catalog(item_type: String) -> Array:
	return shop.get_catalog(item_type)


func get_bolts() -> int:
	return economy.bolts

# ─────────────────────────────────────────────────────────
# Loadout helpers (delegate to game_controller)
# ─────────────────────────────────────────────────────────
func set_loadout(chassis: String, weapons: Array, armor: String, modules: Array) -> void:
	game_controller.player_chassis = chassis
	game_controller.player_weapons = weapons
	game_controller.player_armor = armor
	game_controller.player_modules = modules


func get_loadout() -> Dictionary:
	return {
		"chassis": game_controller.player_chassis,
		"weapons": game_controller.player_weapons.duplicate(),
		"armor": game_controller.player_armor,
		"modules": game_controller.player_modules.duplicate(),
	}


func validate_loadout() -> Dictionary:
	return game_controller.validate_loadout()


func get_owned_items(item_type: String) -> Array:
	return economy.get_owned_items(item_type)

# ─────────────────────────────────────────────────────────
# Opponent helpers
# ─────────────────────────────────────────────────────────
func get_league_progress() -> Dictionary:
	return league.get_league_progress(league.current_league)


func get_opponent_info(index: int) -> Dictionary:
	return league.get_opponent(league.current_league, index)


func has_beaten_opponent(index: int) -> bool:
	return league.has_beaten_opponent(league.current_league, index)

# ─────────────────────────────────────────────────────────
# Result helpers
# ─────────────────────────────────────────────────────────
func get_last_result() -> Dictionary:
	return {
		"match_result": last_match_result,
		"won": last_match_result.get("winner_team", -1) == 0,
		"bolts_earned": last_bolts_earned,
		"repair_cost": last_repair_cost,
		"net_bolts": last_bolts_earned - last_repair_cost,
		"opponent_name": league.get_opponent(
			league.current_league, selected_opponent_index
		).get("name", "Unknown"),
	}

# ─────────────────────────────────────────────────────────
# Save / Load
# ─────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"economy": economy.to_dict(),
		"league": league.to_dict(),
		"loadout": get_loadout(),
	}


func from_dict(data: Dictionary) -> void:
	if data.has("economy"):
		economy.from_dict(data["economy"])
	if data.has("league"):
		league.from_dict(data["league"])
	if data.has("loadout"):
		var lo: Dictionary = data["loadout"]
		set_loadout(
			lo.get("chassis", "scout"),
			lo.get("weapons", ["minigun"]),
			lo.get("armor", "plating"),
			lo.get("modules", [])
		)
