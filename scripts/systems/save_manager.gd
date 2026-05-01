extends Node
class_name SaveManager

const SAVE_PATH := "user://savegame.json"

var state: RacheGameState

func setup(state_ref: RacheGameState) -> void:
	state = state_ref

func save_checkpoint() -> bool:
	if state == null:
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state.to_snapshot()))
	file.close()
	return true

func load_checkpoint() -> bool:
	if state == null:
		return false
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	state.apply_snapshot(parsed)
	return true

func delete_checkpoint() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
