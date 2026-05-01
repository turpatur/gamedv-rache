extends Node

func run() -> void:
	var state := RacheGameState.new()
	state.route["ledger_overview_seen"] = true
	state.add_score("R", 1)
	assert(state.score["R"] == 1)

	state.ledger_profiles_seen["R"] = true
	state.add_score("R", 2)
	assert(state.score["R"] == 3)
	assert(not state.all_ledger_profiles_seen())

	state.ledger_profiles_seen["A"] = true
	state.add_score("A", 1)
	state.ledger_profiles_seen["C"] = true
	state.add_score("C", 1)
	state.ledger_profiles_seen["H"] = true
	state.add_score("H", 1)
	assert(state.all_ledger_profiles_seen())

	state.set_clue_clear("photo")
	assert(state.clue_state["photo"] == RacheGameState.MemoryState.CLEAR)
	assert(state.score["A"] == 1)
	assert(state.score["C"] == 1)
	assert(state.score["H"] == 1)
