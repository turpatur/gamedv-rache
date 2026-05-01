extends Node
class_name InvestigationController

signal verdict_open_requested

const ClueConfigScript := preload("res://data/config/clue_config.gd")
const ScoreConfigScript := preload("res://data/config/score_config.gd")
const TableDialogueScript := preload("res://data/dialogue/table_dialogue.gd")
const BodyDialogueScript := preload("res://data/dialogue/body_dialogue.gd")
const DoorDialogueScript := preload("res://data/dialogue/door_dialogue.gd")
const RacheDialogueScript := preload("res://data/dialogue/rache_dialogue.gd")
const PhotoDialogueScript := preload("res://data/dialogue/photo_dialogue.gd")
const WatchDialogueScript := preload("res://data/dialogue/watch_dialogue.gd")

var state: RacheGameState
var narrative: NarrativeController
var loop_manager: LoopManager
var ui_root: UIRoot
var pending_profile_return: bool = false

var clue_config: ClueConfig = ClueConfigScript.new()
var score_config: ScoreConfig = ScoreConfigScript.new()
var table_dialogue := TableDialogueScript.new()
var body_dialogue := BodyDialogueScript.new()
var door_dialogue := DoorDialogueScript.new()
var rache_dialogue := RacheDialogueScript.new()
var photo_dialogue := PhotoDialogueScript.new()
var watch_dialogue := WatchDialogueScript.new()

func setup(state_ref: RacheGameState, narrative_ref: NarrativeController, loop_ref: LoopManager, ui_ref: UIRoot = null) -> void:
	state = state_ref
	narrative = narrative_ref
	loop_manager = loop_ref
	ui_root = ui_ref
	narrative.choice_selected.connect(_dispatch_choice)
	narrative.dialogue_closed.connect(_on_dialogue_closed)

func inspect(object_id: String) -> void:
	match object_id:
		"table":
			_inspect_table()
		"body":
			_inspect_body()
		"door":
			_inspect_door()
		"rache":
			_inspect_rache()
		"photo":
			_inspect_photo()
		"watch":
			_inspect_watch()

func try_door_rach_ambient() -> void:
	state.door_approach_count += 1
	var pool: Array = clue_config.door_rache_pool()
	if state.door_rach_index < pool.size() and state.door_approach_count % 2 == 1:
		var lines: Array = pool[state.door_rach_index].duplicate()
		state.door_rach_index += 1
		narrative.show_dialogue(lines)

func _dep_met(object_id: String) -> bool:
	var dep := clue_config.dependency_for(object_id)
	if dep == "":
		return true
	return int(state.clue_state[dep]) == RacheGameState.MemoryState.CLEAR

func _phase() -> int:
	return state.phase()

func _inspect_table() -> void:
	if int(state.clue_state["table"]) == RacheGameState.MemoryState.CLEAR:
		if state.ng_plus and int(state.clue_state["body"]) == RacheGameState.MemoryState.CLEAR and not bool(state.route["poison_after_body"]):
			narrative.present_object_choice("table",
				table_dialogue.revisit(_phase()) + ["The residue is still there."],
				[
					{"label": "A) Follow the scent.", "key": "taste"},
					{"label": "B) Leave it.", "key": "leave"},
				]
			)
			return
		narrative.show_dialogue(table_dialogue.revisit(_phase()))
		return
	narrative.present_object_choice("table", table_dialogue.intro(_phase()), [
		{"label": "A) Examine the glass.", "key": "glass"},
		{"label": "B) Smell the residue.", "key": "smell"},
		{"label": "C) Leave it.", "key": "leave"},
	])

func _on_table_choice(key: String) -> void:
	match key:
		"glass":
			if _dep_met("table"):
				state.set_clue_clear("table")
				state.add_score("C", 2)
				narrative.show_dialogue(table_dialogue.glass_clear(_phase()))
			else:
				state.bump_clue_to_hazy("table")
				narrative.show_dialogue(table_dialogue.glass_hazy())
		"smell":
			state.bump_clue_to_hazy("table")
			state.add_score("C", 1)
			narrative.show_dialogue(table_dialogue.smell(_phase()))
		"taste":
			if state.ng_plus and int(state.clue_state["table"]) == RacheGameState.MemoryState.CLEAR and int(state.clue_state["body"]) == RacheGameState.MemoryState.CLEAR and not bool(state.route["poison_after_body"]):
				state.route["poison_after_body"] = true
				state.route["poison_death_spent"] = true
				state.add_score("SELF", 1)
				state.reduce_score("C", 1)
				narrative.show_dialogue(table_dialogue.taste_ng_plus())
				return
			if bool(state.route["poison_death_spent"]):
				narrative.show_dialogue(table_dialogue.taste_repeat())
				return
			loop_manager.queue_death("poison", "Sweet almond. Warm glass. Then the floor rises too fast.")
			narrative.show_dialogue(table_dialogue.taste_death_intro())
		"leave":
			state.bump_clue_to_hazy("table")
			narrative.show_dialogue(table_dialogue.leave())

func _inspect_body() -> void:
	if int(state.clue_state["body"]) == RacheGameState.MemoryState.CLEAR:
		narrative.show_dialogue(body_dialogue.revisit(_phase()))
		return
	if int(state.clue_state["body"]) == RacheGameState.MemoryState.HAZY and _dep_met("body") and state.seen_dialogs["body"].has("position"):
		state.set_clue_clear("body")
		state.add_score("R", 1)
		var lines: Array = ["The residue on that glass... it matches the stillness of this body."]
		lines.append_array(body_dialogue.position_clear(_phase()))
		narrative.show_dialogue(lines)
		return
	narrative.present_object_choice("body", body_dialogue.intro(_phase()), [
		{"label": "A) Examine the position.", "key": "position"},
		{"label": "B) Examine the second glass.", "key": "glass2"},
		{"label": "C) Leave it.", "key": "leave"},
	])

func _on_body_choice(key: String) -> void:
	match key:
		"position":
			if _dep_met("body"):
				state.set_clue_clear("body")
				state.add_score("R", 2)
				narrative.show_dialogue(body_dialogue.position_clear(_phase()))
			else:
				state.bump_clue_to_hazy("body")
				state.add_score("R", 1)
				narrative.show_dialogue(body_dialogue.position_hazy())
		"glass2":
			state.add_score("R", 1)
			state.add_score("A", 1)
			narrative.show_dialogue(body_dialogue.glass2(_phase()))
		"leave":
			state.bump_clue_to_hazy("body")
			narrative.show_dialogue(body_dialogue.leave())

func _inspect_door() -> void:
	if int(state.clue_state["door"]) == RacheGameState.MemoryState.CLEAR:
		if state.ng_plus and int(state.clue_state["rache"]) == RacheGameState.MemoryState.CLEAR and not bool(state.route["door_after_rache"]):
			narrative.present_object_choice("door",
				door_dialogue.revisit(_phase(), state.ng_plus, bool(state.route["door_after_rache"])) + ["The handle waits like a dare."],
				[
					{"label": "A) Force it again.", "key": "force"},
					{"label": "B) Step back.", "key": "frame"},
				]
			)
			return
		narrative.show_dialogue(door_dialogue.revisit(_phase(), state.ng_plus, bool(state.route["door_after_rache"])))
		return
	if int(state.clue_state["door"]) == RacheGameState.MemoryState.HAZY and _dep_met("door") and state.seen_dialogs["door"].has("mechanism"):
		state.set_clue_clear("door")
		state.add_score("H", 1)
		var lines: Array = ["The letters on the floor were a warning. This door isn't a barrier, it's a cage."]
		lines.append_array(door_dialogue.mechanism_clear(_phase()))
		narrative.show_dialogue(lines)
		return
	narrative.present_object_choice("door", door_dialogue.intro(_phase()), [
		{"label": "A) Examine the mechanism.", "key": "mechanism"},
		{"label": "B) Examine the frame.", "key": "frame"},
		{"label": "C) Try to open it.", "key": "force"},
	])

func _on_door_choice(key: String) -> void:
	match key:
		"mechanism":
			if _dep_met("door"):
				state.set_clue_clear("door")
				state.add_score("H", 2)
				narrative.show_dialogue(door_dialogue.mechanism_clear(_phase()))
			else:
				state.bump_clue_to_hazy("door")
				state.add_score("H", 1)
				narrative.show_dialogue(door_dialogue.mechanism_hazy())
		"frame":
			state.add_score("H", 1)
			state.add_score("A", 1)
			narrative.show_dialogue(door_dialogue.frame(_phase()))
		"force":
			if state.ng_plus and int(state.clue_state["door"]) == RacheGameState.MemoryState.CLEAR and int(state.clue_state["rache"]) == RacheGameState.MemoryState.CLEAR and not bool(state.route["door_after_rache"]):
				state.route["door_after_rache"] = true
				state.route["door_death_spent"] = true
				state.add_score("SELF", 2)
				state.reduce_score("H", 1)
				narrative.show_dialogue(door_dialogue.force_ng_plus())
				return
			if bool(state.route["door_death_spent"]):
				narrative.show_dialogue(door_dialogue.force_repeat())
				return
			state.bump_clue_to_hazy("door")
			loop_manager.queue_death("door", "The door mechanism snaps. Something tightens.")
			narrative.show_dialogue(door_dialogue.force_death_intro())

func _inspect_rache() -> void:
	if int(state.clue_state["rache"]) == RacheGameState.MemoryState.CLEAR:
		narrative.show_dialogue(rache_dialogue.revisit(_phase()))
		return
	if int(state.clue_state["rache"]) == RacheGameState.MemoryState.HAZY and _dep_met("rache") and state.seen_dialogs["rache"].has("pressure"):
		state.set_clue_clear("rache")
		state.add_score("R", 1)
		if state.ng_plus:
			state.add_score("C", 1)
			state.add_score("H", 1)
		var lines: Array = ["He didn't struggle because he knew them. The letters aren't a word, they're a roll call."]
		lines.append_array(rache_dialogue.pressure_marks(_phase()))
		narrative.show_dialogue(lines)
		return
	narrative.present_object_choice("rache", rache_dialogue.intro(_phase()), [
		{"label": "A) Read the letters.", "key": "read"},
		{"label": "B) Examine the pressure marks.", "key": "pressure"},
		{"label": "C) Examine the faint final stroke.", "key": "faint"},
		{"label": "D) Leave it.", "key": "leave"},
	])

func _on_rache_choice(key: String) -> void:
	match key:
		"read":
			state.bump_clue_to_hazy("rache")
			state.add_score("R", 1)
			state.add_score("C", 1)
			narrative.show_dialogue(rache_dialogue.read())
		"pressure":
			if _dep_met("rache"):
				state.set_clue_clear("rache")
				state.add_score("R", 1)
				state.add_score("A", 1)
				if state.ng_plus:
					state.add_score("C", 1)
					state.add_score("H", 1)
			else:
				state.bump_clue_to_hazy("rache")
				state.add_score("A", 1)
			narrative.show_dialogue(rache_dialogue.pressure_marks(_phase()))
		"faint":
			state.bump_clue_to_hazy("rache")
			state.add_score("SELF", 2 if state.ng_plus else 1)
			narrative.show_dialogue(rache_dialogue.faint_final_stroke(state.ng_plus))
		"leave":
			state.bump_clue_to_hazy("rache")
			narrative.show_dialogue(rache_dialogue.leave())

func _inspect_photo() -> void:
	if _dep_met("photo") and state.all_ledger_profiles_seen():
		state.set_clue_clear("photo")
	var intro_lines: Array = photo_dialogue.revisit(_phase(), state.ng_plus, bool(state.route["ledger_diary_seen"])) if int(state.clue_state["photo"]) == RacheGameState.MemoryState.CLEAR else photo_dialogue.intro(_phase())
	narrative.present_object_choice("photo", intro_lines, _ledger_root_options())

func _on_photo_choice(key: String) -> void:
	match key:
		"open":
			if not bool(state.route["ledger_overview_seen"]):
				state.route["ledger_overview_seen"] = true
				state.add_score("R", 1)
			if not _dep_met("photo"):
				state.bump_clue_to_hazy("photo")
			narrative.present_object_choice("photo", photo_dialogue.open_ledger_intro(), _ledger_profile_options())
		"shelf":
			state.bump_clue_to_hazy("photo")
			narrative.show_dialogue(photo_dialogue.shelf())
		"profile_R":
			_read_ledger_profile("R")
		"profile_A":
			_read_ledger_profile("A")
		"profile_C":
			_read_ledger_profile("C")
		"profile_H":
			_read_ledger_profile("H")
		"diary":
			_read_ledger_diary()
		"back":
			narrative.present_object_choice("photo", photo_dialogue.revisit(_phase(), state.ng_plus, bool(state.route["ledger_diary_seen"])), _ledger_root_options())
		"leave":
			narrative.show_dialogue(photo_dialogue.close_ledger())

func _ledger_root_options() -> Array:
	var options: Array = [
		{"label": "A) Open the employee ledger.", "key": "open"},
		{"label": "B) Examine the shelf.", "key": "shelf"},
	]
	if state.ng_plus and state.all_ledger_profiles_seen():
		if bool(state.route["ledger_diary_seen"]):
			options.append({"label": "C) Re-read the overlooked diary page.", "key": "diary"})
		else:
			options.append({"label": "C) Read the overlooked diary page.", "key": "diary"})
	options.append({"label": "%s) Leave it." % score_config.next_key_label(options.size()), "key": "leave"})
	return options

func _ledger_profile_options() -> Array:
	var options: Array = [
		{"label": "A) Raphael Alexandre", "key": "profile_R"},
		{"label": "B) Aleph Cerny", "key": "profile_A"},
		{"label": "C) Charlotte Hahn", "key": "profile_C"},
		{"label": "D) Harold Evans", "key": "profile_H"},
	]
	if state.ng_plus and state.all_ledger_profiles_seen():
		if bool(state.route["ledger_diary_seen"]):
			options.append({"label": "E) Re-read the overlooked diary page.", "key": "diary"})
		else:
			options.append({"label": "E) Read the overlooked diary page.", "key": "diary"})
	options.append({"label": "%s) Close the ledger / Back" % score_config.next_key_label(options.size()), "key": "back"})
	return options

func _read_ledger_profile(letter: String) -> void:
	var score_amounts: Dictionary = {"R": 2, "A": 1, "C": 1, "H": 1}
	var was_seen: bool = bool(state.ledger_profiles_seen.get(letter, false))
	state.ledger_profiles_seen[letter] = true
	if not was_seen:
		state.add_score(letter, int(score_amounts.get(letter, 0)))
	if _dep_met("photo") and state.all_ledger_profiles_seen():
		state.set_clue_clear("photo")
	else:
		state.bump_clue_to_hazy("photo")
	if ui_root != null:
		ui_root.show_profile(letter)
	pending_profile_return = true
	match letter:
		"R":
			narrative.show_dialogue(photo_dialogue.profile_raphael(_phase(), state.ng_plus))
		"A":
			narrative.show_dialogue(photo_dialogue.profile_aleph(_phase(), state.ng_plus))
		"C":
			narrative.show_dialogue(photo_dialogue.profile_charlotte(_phase(), state.ng_plus))
		"H":
			narrative.show_dialogue(photo_dialogue.profile_harold(_phase(), state.ng_plus))

func _read_ledger_diary() -> void:
	if bool(state.route["ledger_diary_seen"]):
		narrative.show_dialogue(photo_dialogue.diary_revisit())
		return
	state.route["ledger_diary_seen"] = true
	state.add_score("SELF", 3)
	state.add_score("R", 1)
	state.add_score("A", 1)
	state.add_score("C", 1)
	state.add_score("H", 1)
	narrative.show_dialogue(photo_dialogue.diary_page())

func _inspect_watch() -> void:
	if state.ng_plus:
		var opts: Array = [{"label": "A) Synchronize.", "key": "hold"}]
		if state.can_open_verdict():
			opts.append({"label": "B) Open verdict.", "key": "verdict"})
		opts.append({"label": "%s) Not yet." % score_config.next_key_label(opts.size()), "key": "notyet"})
		narrative.present_object_choice("watch", watch_dialogue.ng_plus_intro(), opts)
		return

	if state.core_clues_seen() and not bool(state.route["has_valid_death"]) and not bool(state.route["watch_death_spent"]):
		state.bump_clue_to_hazy("watch")
		loop_manager.queue_death("watch", "The watch opens inside my skull.")
		narrative.show_dialogue(watch_dialogue.forced_death_intro())
		return

	if state.can_open_verdict():
		verdict_open_requested.emit()
		return

	if not state.has_died:
		narrative.present_object_choice("watch", watch_dialogue.no_death_intro(), [
			{"label": "A) Listen.", "key": "take"},
			{"label": "B) Leave it.", "key": "leave"},
		])
	else:
		narrative.present_object_choice("watch", watch_dialogue.after_death_intro(_phase()), [
			{"label": "A) Listen.", "key": "hold"},
			{"label": "B) Leave it.", "key": "leave"},
		])

func _on_watch_choice(key: String) -> void:
	match key:
		"take":
			state.bump_clue_to_hazy("watch")
			state.add_score("SELF", 1)
			narrative.show_dialogue(watch_dialogue.listen_it())
		"hold":
			state.set_clue_clear("watch")
			state.add_score("SELF", 1)
			if state.ng_plus and bool(state.route["poison_after_body"]) and bool(state.route["door_after_rache"]) and not bool(state.route["watch_after_deaths"]) and not bool(state.route["watch_death_spent"]):
				state.route["watch_after_deaths"] = true
				state.add_score("SELF", 3)
				state.reduce_score("R", 1)
				state.reduce_score("A", 1)
				state.reduce_score("C", 1)
				state.reduce_score("H", 1)
				loop_manager.queue_death("watch", "The watch opens inside my skull.")
				narrative.show_dialogue(watch_dialogue.hold_ng_plus_gate())
				return
			if state.ng_plus and not bool(state.route["watch_after_deaths"]):
				narrative.show_dialogue(watch_dialogue.hold_ng_plus_waiting())
				return
			narrative.show_dialogue(watch_dialogue.hold(_phase()))
		"leave":
			narrative.show_dialogue(watch_dialogue.leave(_phase()))
		"listen":
			state.pending_ending_id = "true_end"
			narrative.show_dialogue(watch_dialogue.listen_true_end())
		"verdict":
			verdict_open_requested.emit()
		"notyet":
			narrative.show_dialogue(watch_dialogue.not_yet_ng_plus())

func _dispatch_choice(obj_id: String, key: String) -> void:
	if state.seen_dialogs.has(obj_id) and not state.seen_dialogs[obj_id].has(key):
		state.seen_dialogs[obj_id].append(key)
	match obj_id:
		"table":
			_on_table_choice(key)
		"body":
			_on_body_choice(key)
		"door":
			_on_door_choice(key)
		"rache":
			_on_rache_choice(key)
		"photo":
			_on_photo_choice(key)
		"watch":
			_on_watch_choice(key)

func _on_dialogue_closed() -> void:
	if not pending_profile_return:
		return
	pending_profile_return = false
	if ui_root != null:
		ui_root.hide_profile()
	narrative.present_object_choice("photo", photo_dialogue.open_ledger_intro(), _ledger_profile_options())
