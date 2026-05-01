extends Node
class_name NarrativeController

signal line_rendered(text: String)
signal choices_rendered(options: Array)
signal dialogue_opened
signal dialogue_closed
signal choice_selected(object_id: String, key: String)

var state: RacheGameState

func setup(state_ref: RacheGameState) -> void:
	state = state_ref

func show_dialogue(lines: Array) -> void:
	state.dialogue_lines = lines.duplicate()
	state.dialogue_index = 0
	state.choice_options = []
	state.awaiting_choice = false
	state.current_object = ""
	state.dialogue_active = true
	state.movement_locked = true
	dialogue_opened.emit()
	_render_dialogue_line()

func present_object_choice(obj_id: String, intro_lines: Array, options: Array) -> void:
	state.current_object = obj_id
	var decorated: Array = []

	var has_seen: bool = state.seen_dialogs.has(obj_id) and not (state.seen_dialogs[obj_id] as Array).is_empty()

	for option in options:
		var copy: Dictionary = (option as Dictionary).duplicate(true)
		if has_seen and not (state.seen_dialogs[obj_id] as Array).has(copy["key"]):
			copy["label"] = "[NEW] %s" % copy["label"]
		decorated.append(copy)

	state.dialogue_lines = intro_lines.duplicate()
	state.dialogue_index = 0
	state.choice_options = decorated
	state.awaiting_choice = false
	state.dialogue_active = true
	state.movement_locked = true
	dialogue_opened.emit()
	_render_dialogue_line()

func advance() -> void:
	if not state.dialogue_active:
		return
	state.dialogue_index += 1
	if state.dialogue_index < state.dialogue_lines.size():
		_render_dialogue_line()
		return
	if not state.choice_options.is_empty() and not state.awaiting_choice:
		_render_dialogue_line()
		return
	if state.awaiting_choice:
		_render_dialogue_line()
		return
	_close_dialogue()

func pick_choice(idx: int) -> void:
	if not state.awaiting_choice:
		return
	if idx < 0 or idx >= state.choice_options.size():
		return

	state.awaiting_choice = false
	choices_rendered.emit([])
	state.dialogue_active = false
	state.movement_locked = false

	var key := String(state.choice_options[idx]["key"])
	var obj := state.current_object
	if state.seen_dialogs.has(obj) and not state.seen_dialogs[obj].has(key):
		state.seen_dialogs[obj].append(key)

	state.choice_options = []
	state.current_object = ""
	choice_selected.emit(obj, key)

func force_close() -> void:
	_close_dialogue()

func _render_dialogue_line() -> void:
	if state.dialogue_index < state.dialogue_lines.size():
		line_rendered.emit(String(state.dialogue_lines[state.dialogue_index]))
		choices_rendered.emit([])
		return

	line_rendered.emit("")
	state.awaiting_choice = true
	choices_rendered.emit(state.choice_options)

func _close_dialogue() -> void:
	state.dialogue_active = false
	state.awaiting_choice = false
	state.movement_locked = false
	choices_rendered.emit([])
	line_rendered.emit("")
	dialogue_closed.emit()
