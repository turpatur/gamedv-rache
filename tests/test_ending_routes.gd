extends Node

func run() -> void:
	var state := RacheGameState.new()
	var router := EndingRouter.new()
	router.setup(state)

	state.route["has_valid_death"] = true
	state.score["R"] = 3
	for key: String in ["table", "body", "door", "rache", "photo"]:
		state.clue_state[key] = RacheGameState.MemoryState.CLEAR
	assert(router.resolve_ending("R") == "good_end_1")

	state.ng_plus = true
	state.route["good_R_seen"] = true
	state.route["poison_after_body"] = true
	state.route["door_after_rache"] = true
	state.route["watch_after_deaths"] = true
	state.score["SELF"] = 5
	state.route["ledger_diary_seen"] = false
	assert(not state.can_true_end())
	assert(router.resolve_ending("self") == "bad_end_scapegoat")

	state.route["ledger_diary_seen"] = true
	assert(state.can_true_end())
	assert(router.resolve_ending("self") == "true_end")
