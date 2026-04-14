# league_manager.gd — League progression system
# BattleBrotts Sprint 5 · S5-003
#
# Manages league structure, opponent definitions, win/loss tracking,
# and league advancement. Starting with Scrapyard league.
class_name LeagueManager

# ── Signals ──────────────────────────────────────────────
signal league_advanced(from_league: String, to_league: String)
signal opponent_defeated(league: String, opponent_index: int)
signal match_recorded(league: String, opponent_index: int, won: bool)

# ── Constants ────────────────────────────────────────────
const LEAGUES := {
	"scrapyard": {
		"name": "Scrapyard",
		"order": 0,
		"unlock_requirement": "",  # Start of game
		"wins_to_advance": 3,      # Must beat all 3 opponents
		"advance_to": "bronze",
		"opponents": [
			{
				"name": "Junkbot",
				"chassis": "scout",
				"weapons": ["minigun"],
				"armor": "",
				"modules": [],
				"stance": "aggressive",
				"behavior_cards": [],
			},
			{
				"name": "Scrapper",
				"chassis": "scout",
				"weapons": ["plasma_cutter"],
				"armor": "plating",
				"modules": [],
				"stance": "aggressive",
				"behavior_cards": [],
			},
			{
				"name": "Bonebreaker",
				"chassis": "brawler",
				"weapons": ["minigun", "shotgun"],
				"armor": "",
				"modules": [],
				"stance": "aggressive",
				"behavior_cards": [],
			},
		],
	},
	"bronze": {
		"name": "Bronze",
		"order": 1,
		"unlock_requirement": "scrapyard",  # Beat Scrapyard to unlock
		"wins_to_advance": 3,  # Beat 3/5 Bronze opponents
		"advance_to": "silver",
		"opponents": [],  # TODO: Define in future sprint
	},
}

const LEAGUE_ORDER := ["scrapyard", "bronze", "silver", "gold", "platinum", "champion"]

# ── State ────────────────────────────────────────────────
var current_league: String = "scrapyard"
var unlocked_leagues: Array = ["scrapyard"]
var match_history: Array = []  # Array of { league, opponent_index, won, timestamp }
var opponent_wins: Dictionary = {}  # { "scrapyard_0": true, "scrapyard_1": false, ... }

# ─────────────────────────────────────────────────────────
# Init
# ─────────────────────────────────────────────────────────
func _init() -> void:
	reset()


func reset() -> void:
	current_league = "scrapyard"
	unlocked_leagues = ["scrapyard"]
	match_history = []
	opponent_wins = {}

# ─────────────────────────────────────────────────────────
# League info
# ─────────────────────────────────────────────────────────
func get_league(league_id: String) -> Dictionary:
	if not LEAGUES.has(league_id):
		return {}
	return LEAGUES[league_id]


func get_current_league() -> Dictionary:
	return get_league(current_league)


func get_opponents(league_id: String) -> Array:
	var league := get_league(league_id)
	if league.is_empty():
		return []
	return league["opponents"]


func get_opponent(league_id: String, index: int) -> Dictionary:
	var opponents := get_opponents(league_id)
	if index < 0 or index >= opponents.size():
		return {}
	return opponents[index]


func get_opponent_id(league_id: String, index: int) -> String:
	return "%s_%d" % [league_id, index]

# ─────────────────────────────────────────────────────────
# Match tracking
# ─────────────────────────────────────────────────────────
func record_match(league_id: String, opponent_index: int, won: bool) -> Dictionary:
	"""Record match result. Returns { recorded, league_beaten, advanced_to }."""
	var opp_id := get_opponent_id(league_id, opponent_index)

	match_history.append({
		"league": league_id,
		"opponent_index": opponent_index,
		"won": won,
	})

	var first_win := false
	if won and not opponent_wins.has(opp_id):
		opponent_wins[opp_id] = true
		first_win = true
		opponent_defeated.emit(league_id, opponent_index)

	match_recorded.emit(league_id, opponent_index, won)

	# Check league completion
	var advanced_to := ""
	var league_beaten := is_league_beaten(league_id)
	if league_beaten and LEAGUES.has(league_id):
		var next: String = LEAGUES[league_id].get("advance_to", "")
		if next != "" and not next in unlocked_leagues:
			unlocked_leagues.append(next)
			advanced_to = next
			league_advanced.emit(league_id, next)

	return {
		"recorded": true,
		"first_win": first_win,
		"league_beaten": league_beaten,
		"advanced_to": advanced_to,
	}

# ─────────────────────────────────────────────────────────
# Progress queries
# ─────────────────────────────────────────────────────────
func is_league_beaten(league_id: String) -> bool:
	if not LEAGUES.has(league_id):
		return false
	var league: Dictionary = LEAGUES[league_id]
	var wins := count_unique_wins(league_id)
	return wins >= league["wins_to_advance"]


func count_unique_wins(league_id: String) -> int:
	var count := 0
	var opponents: Array = get_opponents(league_id)
	for i in range(opponents.size()):
		var opp_id := get_opponent_id(league_id, i)
		if opponent_wins.has(opp_id):
			count += 1
	return count


func has_beaten_opponent(league_id: String, opponent_index: int) -> bool:
	return opponent_wins.has(get_opponent_id(league_id, opponent_index))


func is_league_unlocked(league_id: String) -> bool:
	return league_id in unlocked_leagues


func get_league_progress(league_id: String) -> Dictionary:
	"""Returns { wins, total, beaten, opponents: [{ index, name, beaten }] }."""
	if not LEAGUES.has(league_id):
		return {}
	var league: Dictionary = LEAGUES[league_id]
	var opponents: Array = league["opponents"]
	var opp_progress := []
	for i in range(opponents.size()):
		opp_progress.append({
			"index": i,
			"name": opponents[i]["name"],
			"beaten": has_beaten_opponent(league_id, i),
		})
	return {
		"wins": count_unique_wins(league_id),
		"total": opponents.size(),
		"required": league["wins_to_advance"],
		"beaten": is_league_beaten(league_id),
		"opponents": opp_progress,
	}


func get_next_opponent_index(league_id: String) -> int:
	"""Returns the index of the first unbeaten opponent, or -1 if all beaten."""
	var opponents := get_opponents(league_id)
	for i in range(opponents.size()):
		if not has_beaten_opponent(league_id, i):
			return i
	return -1

# ─────────────────────────────────────────────────────────
# Win/Loss record
# ─────────────────────────────────────────────────────────
func get_total_wins() -> int:
	var count := 0
	for entry in match_history:
		if entry["won"]:
			count += 1
	return count


func get_total_losses() -> int:
	var count := 0
	for entry in match_history:
		if not entry["won"]:
			count += 1
	return count


func get_win_loss_record() -> Dictionary:
	return {"wins": get_total_wins(), "losses": get_total_losses()}

# ─────────────────────────────────────────────────────────
# Save / Load
# ─────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"current_league": current_league,
		"unlocked_leagues": unlocked_leagues.duplicate(),
		"match_history": match_history.duplicate(true),
		"opponent_wins": opponent_wins.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	current_league = data.get("current_league", "scrapyard")
	unlocked_leagues = data.get("unlocked_leagues", ["scrapyard"]).duplicate()
	match_history = data.get("match_history", []).duplicate(true)
	opponent_wins = data.get("opponent_wins", {}).duplicate(true)
