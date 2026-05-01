extends Node
class_name EndingRouter

const EndingTextsScript := preload("res://data/endings/ending_texts.gd")

var state: RacheGameState
var ending_texts := EndingTextsScript.new()

func setup(state_ref: RacheGameState) -> void:
	state = state_ref

func resolve_ending(verdict: String) -> String:
	if state.ng_plus:
		return resolve_ng_ending(verdict)
	return resolve_game1_ending(verdict)

func resolve_game1_ending(verdict: String) -> String:
	match verdict:
		"R":
			if int(state.score["R"]) >= 3 and state.clear_count() >= 5 and bool(state.route["has_valid_death"]):
				return "good_end_1"
			return "bad_end_weak"
		"A":
			return "bad_end_A" if int(state.score["A"]) >= 3 else "bad_end_weak"
		"C":
			return "bad_end_C" if int(state.score["C"]) >= 3 else "bad_end_weak"
		"H":
			return "bad_end_H" if int(state.score["H"]) >= 3 else "bad_end_weak"
		"self":
			return "bad_end_scapegoat" if int(state.score["SELF"]) >= 2 else "bad_end_weak"
	return "bad_end_weak"

func resolve_ng_ending(verdict: String) -> String:
	match verdict:
		"self":
			return "true_end" if state.can_true_end() else "bad_end_scapegoat"
		"R":
			return "r_repeat"
		"A":
			return "bad_end_A"
		"C":
			return "bad_end_C"
		"H":
			return "bad_end_H"
	return "bad_end_weak"

func build_verdict_title() -> String:
	var nc := state.clear_count()
	var intro: String
	if nc >= 6:
		intro = "The room demands your answer.Who is responsible?"
	elif nc >= 3:
		intro = "Steel your resolve.Who is responsible?"
	else:
		intro = "Doubt even yourself. Who is responsible?"

	match state.highest_bias():
		"A":
			intro += "\n\nThe plan keeps pointing at A."
		"C":
			intro += "\n\nThe poison keeps pointing at C."
		"H":
			intro += "\n\nThe door keeps pointing at H."
		"R":
			intro += "\n\nTrust keeps pointing at R."
		"SELF":
			intro += "\n\nThe room keeps pointing back at me."
	return intro

func build_verdict_labels() -> Array[String]:
	var self_label: String
	if state.ng_plus and int(state.score["SELF"]) >= 5:
		self_label = "Myself -- The missing piece"
	elif int(state.score["SELF"]) >= 2:
		self_label = "Myself -- Unstable suspicion"
	else:
		self_label = "Myself -- Weak case"

	return [
		"R -- %s" % state.case_strength("R"),
		"A -- %s" % state.case_strength("A"),
		"C -- %s" % state.case_strength("C"),
		"H -- %s" % state.case_strength("H"),
		self_label,
		"Back / Not yet",
	]

func verdict_dialogue(key: String, resolved: String) -> Array[String]:
	match key:
		"R":
			if resolved == "good_end_1":
				return [
					"R.",
					"The one closest to the victim.",
					"The one who could invite them here",
					"without turning trust into alarm.",
					"The room points at R first.",
					"Maybe too cleanly.",
				]
			if resolved == "r_repeat":
				return [
					"Raphael again. It's the only name that makes sense, but the room still won't open.",
					"He has the blood on him, but he’s not the only one.",
				]
			return [
				"It was Raphael. He was the one closest to the victim.",
				"He had the motive, the means, and the blood on his cuffs.",
			]
		"A":
			return [
				"A.",
				"The mind behind it all.",
				"The one who turned a grievance into a blueprint.",
				"But architects don't always lay the first stone.",
				"I'm missing something.",
			]
		"C":
			return [
				"C.",
				"Poison in the glass. The most visible thread.",
				"Visible threads are usually there for a reason.",
				"I should know better.",
			]
		"H":
			return [
				"H.",
				"The trap. The door.",
				"The trap at the door—who was it really built for?",
				"I'm letting it get personal.",
			]
		"self":
			if resolved == "true_end":
				return [
					"I am the 'E' in RACHE. The link that turns four suspects into a conspiracy.",
					"I wasn't just an advisor. I was the architect who showed them how to build this cage.",
					"R, A, C, H—they all played their part, but I gave them the blueprint.",
					"To stop this, I have to stop pointing fingers and take the fall.",
				]
			return [
				"I don't know who did this. It's all just a blur of blood and ticking.",
				"The room is laughing at me. I'm missing something, and it's killing me.",
			]
	return ["The room keeps its secret."]

func ending_data(ending_id: String) -> Dictionary:
	return ending_texts.text_for(ending_id)

func apply_ending_side_effects(ending_id: String) -> void:
	match ending_id:
		"good_end_1":
			state.route["good_R_seen"] = true
			state.ng_plus = true
		"r_repeat":
			state.ng_plus = true
		"true_end":
			state.ng_plus = false
