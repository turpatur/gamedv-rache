extends Node

func run() -> void:
	var state := RacheGameState.new()
	var save := SaveManager.new()
	save.setup(state)
	state.score["R"] = 4
	state.ledger_profiles_seen["R"] = true
	state.ledger_profiles_seen["C"] = true
	state.route["ledger_diary_seen"] = true
	assert(save.save_checkpoint())

	var loaded := RacheGameState.new()
	var loader := SaveManager.new()
	loader.setup(loaded)
	assert(loader.load_checkpoint())
	assert(loaded.score["R"] == 4)
	assert(loaded.ledger_profiles_seen["R"])
	assert(loaded.ledger_profiles_seen["C"])
	assert(not loaded.ledger_profiles_seen["A"])
	assert(loaded.route["ledger_diary_seen"])
