extends Node

func run() -> void:
	var state := RacheGameState.new()
	var config := ClueConfig.new()
	assert(config.dependency_for("table") == "")
	assert(config.dependency_for("body") == "table")
	assert(config.dependency_for("rache") == "body")
	assert(config.dependency_for("door") == "rache")
	assert(config.dependency_for("photo") == "door")
	assert(config.dependency_for("watch") == "")

	state.set_clue_clear("table")
	assert(state.clue_state["table"] == RacheGameState.MemoryState.CLEAR)
	state.set_clue_clear("body")
	state.set_clue_clear("rache")
	state.set_clue_clear("door")
	state.set_clue_clear("photo")
	assert(state.core_clues_seen())
