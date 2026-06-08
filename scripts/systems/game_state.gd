extends Node
class_name RacheGameState

enum ScreenState { TITLE, PLAYING, VERDICT, ENDING }
enum LoopPhase { EARLY, MID, LATE }
enum MemoryState { UNKNOWN, HAZY, CLEAR }

const SCORE_KEYS: Array[String] = ["R", "A", "C", "H", "SELF"]
const CLUE_IDS: Array[String] = ["table", "body", "rache", "door", "photo", "watch"]
const CORE_CLUES: Array[String] = ["table", "body", "rache", "door", "photo"]

var game_state: int = ScreenState.TITLE
var loop_count: int = 1
var ng_plus: bool = false
var has_died: bool = false

var score: Dictionary = {}
var route: Dictionary = {}
var clue_state: Dictionary = {}
var seen_dialogs: Dictionary = {}
var ledger_profiles_seen: Dictionary = {}

# Runtime only.
var player_pos: Vector2 = Vector2(460, 420)
var movement_locked: bool = false
var dying: bool = false
var load_flash: float = 0.0
var input_disorientation: float = 0.0
var prompt_notice: String = ""
var prompt_notice_timer: float = 0.0
var nearest_id: String = ""
var was_near_door: bool = false
var pending_death: bool = false
var pending_death_reason: String = ""
var pending_ending_id: String = ""
var verdict_active: bool = false
var verdict_choice: String = ""

# Dialogue runtime mirrors the old monolith fields.
var dialogue_active: bool = false
var current_object: String = ""
var awaiting_choice: bool = false
var choice_options: Array = []
var dialogue_lines: Array = []
var dialogue_index: int = 0

# Door ambient runtime.
var door_rach_index: int = 0
var door_approach_count: int = 0

func _ready() -> void:
	reset_for_title()

func reset_for_title() -> void:
	reset_persistent()
	reset_runtime()
	game_state = ScreenState.TITLE
	movement_locked = true

func reset_for_new_game() -> void:
	reset_persistent()
	reset_runtime()
	game_state = ScreenState.PLAYING
	movement_locked = false

func reset_for_ng_plus() -> void:
	reset_persistent()
	reset_runtime()
	ng_plus = true
	has_died = true
	loop_count = 5
	route["good_R_seen"] = true
	game_state = ScreenState.PLAYING
	movement_locked = false

func reset_persistent() -> void:
	loop_count = 1
	ng_plus = false
	has_died = false
	score = {}
	for key in SCORE_KEYS:
		score[key] = 0
	route = {
		"has_valid_death": false,
		"good_R_seen": false,
		"poison_death_spent": false,
		"door_death_spent": false,
		"watch_death_spent": false,
		"poison_after_body": false,
		"door_after_rache": false,
		"watch_after_deaths": false,
		"ledger_overview_seen": false,
		"ledger_diary_seen": false,
	}
	clue_state = {}
	for key in CLUE_IDS:
		clue_state[key] = MemoryState.UNKNOWN
	seen_dialogs = {}
	for key in CLUE_IDS:
		seen_dialogs[key] = []
	ledger_profiles_seen = {
		"R": false,
		"A": false,
		"C": false,
		"H": false,
	}

func reset_runtime() -> void:
	player_pos = Vector2(460, 420)
	movement_locked = false
	dying = false
	load_flash = 0.0
	input_disorientation = 0.0
	prompt_notice = ""
	prompt_notice_timer = 0.0
	nearest_id = ""
	was_near_door = false
	pending_death = false
	pending_death_reason = ""
	pending_ending_id = ""
	verdict_active = false
	verdict_choice = ""
	dialogue_active = false
	current_object = ""
	awaiting_choice = false
	choice_options = []
	dialogue_lines = []
	dialogue_index = 0
	door_rach_index = 0
	door_approach_count = 0

func to_snapshot() -> Dictionary:
	return {
		"loop_count": loop_count,
		"ng_plus": ng_plus,
		"has_died": has_died,
		"score": score.duplicate(true),
		"route": route.duplicate(true),
		"clue_state": clue_state.duplicate(true),
		"seen_dialogs": seen_dialogs.duplicate(true),
		"ledger_profiles_seen": ledger_profiles_seen.duplicate(true),
	}

func apply_snapshot(data: Dictionary) -> void:
	if score.is_empty() or route.is_empty() or clue_state.is_empty() or seen_dialogs.is_empty():
		reset_persistent()

	loop_count = int(data.get("loop_count", 1))
	ng_plus = bool(data.get("ng_plus", false))
	has_died = bool(data.get("has_died", false))

	var loaded_score: Dictionary = data.get("score", {})
	for key in SCORE_KEYS:
		score[key] = clampi(int(loaded_score.get(key, 0)), 0, 10)

	var loaded_route: Dictionary = data.get("route", {})
	for key in route.keys():
		route[key] = bool(loaded_route.get(key, false))

	var loaded_clues: Dictionary = data.get("clue_state", {})
	for key in CLUE_IDS:
		clue_state[key] = int(loaded_clues.get(key, MemoryState.UNKNOWN))

	var loaded_seen: Dictionary = data.get("seen_dialogs", {})
	for key in CLUE_IDS:
		var arr: Array = loaded_seen.get(key, [])
		seen_dialogs[key] = arr.duplicate()

	var loaded_profiles: Dictionary = data.get("ledger_profiles_seen", {})
	for key in ["R", "A", "C", "H"]:
		ledger_profiles_seen[key] = bool(loaded_profiles.get(key, false))

func score_key(id: String) -> String:
	var up := id.to_upper()
	return "SELF" if (up == "SELF" or id.to_lower() == "self") else up

func add_score(id: String, amount: int) -> void:
	var key := score_key(id)
	if not score.has(key):
		return
	score[key] = clampi(int(score[key]) + amount, 0, 10)

func reduce_score(id: String, amount: int) -> void:
	add_score(id, -amount)

func bump_clue_to_hazy(id: String) -> void:
	if not clue_state.has(id):
		return
	clue_state[id] = max(int(clue_state[id]), int(MemoryState.HAZY))

func set_clue_clear(id: String) -> void:
	if clue_state.has(id):
		clue_state[id] = MemoryState.CLEAR

func clear_count() -> int:
	var n := 0
	for key in clue_state.keys():
		if int(clue_state[key]) == MemoryState.CLEAR:
			n += 1
	return n

func hazy_count() -> int:
	var n := 0
	for key in clue_state.keys():
		if int(clue_state[key]) == MemoryState.HAZY:
			n += 1
	return n

func core_clues_seen() -> bool:
	for key in CORE_CLUES:
		if int(clue_state[key]) == MemoryState.UNKNOWN:
			return false
	return true

func all_ledger_profiles_seen() -> bool:
	for key in ["R", "A", "C", "H"]:
		if not bool(ledger_profiles_seen.get(key, false)):
			return false
	return true

func can_open_verdict() -> bool:
	return core_clues_seen() and has_died

func can_true_end() -> bool:
	return (
		ng_plus
		and bool(route["good_R_seen"])
		and bool(route["poison_after_body"])
		and bool(route["door_after_rache"])
		and bool(route["watch_after_deaths"])
		and bool(route["ledger_diary_seen"])
		and int(score["SELF"]) >= 5
	)

func phase() -> int:
	if loop_count <= 2:
		return LoopPhase.EARLY
	if loop_count <= 4:
		return LoopPhase.MID
	return LoopPhase.LATE

func case_strength(id: String) -> String:
	var value := int(score.get(score_key(id), 0))
	if value >= 4:
		return "Strong case"
	if value >= 2:
		return "Plausible case"
	return "Weak case"

func highest_bias() -> String:
	var best := ""
	var best_v := -1
	for key in score.keys():
		var value := int(score[key])
		if value > best_v:
			best_v = value
			best = key
	return "" if best_v <= 0 else best

func current_lead() -> String:
	if ng_plus:
		if all_ledger_profiles_seen() and not bool(route["ledger_diary_seen"]):
			return "There's a loose page in the ledger."
		if clue_state["table"] == MemoryState.CLEAR and clue_state["body"] == MemoryState.CLEAR and not bool(route["poison_after_body"]):
			return "Check the wine again."
		if clue_state["door"] == MemoryState.CLEAR and clue_state["rache"] == MemoryState.CLEAR and not bool(route["door_after_rache"]):
			return "The door is still rigged."
		if bool(route["poison_after_body"]) and bool(route["door_after_rache"]) and not bool(route["watch_after_deaths"]):
			return "The watch is making a noise."
	if core_clues_seen() and not bool(route["has_valid_death"]):
		return "The room is quiet. The watch isn't."
	if can_open_verdict():
		return "Time to name a name."
	if clue_state["table"] == MemoryState.UNKNOWN or clue_state["table"] == MemoryState.HAZY:
		return "A glass of bitter wine."
	if clue_state["body"] == MemoryState.UNKNOWN or clue_state["body"] == MemoryState.HAZY:
		return "A body in a mahogany chair."
	if clue_state["rache"] == MemoryState.UNKNOWN or clue_state["rache"] == MemoryState.HAZY:
		return "Five bloody letters."
	if clue_state["door"] == MemoryState.UNKNOWN or clue_state["door"] == MemoryState.HAZY:
		return "The door is locked tight."
	if clue_state["photo"] == MemoryState.UNKNOWN:
		return "The shelf has the names."
	if clue_state["photo"] == MemoryState.HAZY:
		return "Read the ledger profiles."
	if clue_state["watch"] == MemoryState.UNKNOWN:
		return "The watch is waiting."
	return "Waiting for a click."

func after_clue_hint() -> String:
	if can_open_verdict():
		return "The watch ticks once. It's time."
	if has_died:
		return "A loose end remains."
	return "Questions linger."

func show_prompt_notice(text: String, duration: float = 1.8) -> void:
	prompt_notice = text
	prompt_notice_timer = duration
