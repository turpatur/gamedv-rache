extends RefCounted
class_name EndingTexts

func text_for(ending_id: String) -> Dictionary:
	match ending_id:
		"good_end_1":
			return {
				"button": "Loop Again",
				"title": "Case Closed.",
				"body": "I found a killer, but the room is still locked. The police will find me here with a body and no explanation. I need a better answer than this.",
			}
		"r_repeat":
			return {
				"button": "Loop Again",
				"title": "Case Reopened.",
				"body": "Raphael again. It's the easiest name to pick, and that's exactly why it's wrong. I'm just lying to myself to get out of this room.",
			}
		"true_end":
			return {
				"button": "Return to Title",
				"title": "Loop Ends.",
				"body": "I took the blame, and the watch finally stopped. The door is forced open, and for once, the police are the ones asking the questions. RACH walks free into the night while I walk toward a cell.",
			}
		"bad_end_scapegoat":
			return {
				"button": "Return to Title",
				"title": "Case Closed.",
				"body": "The investigator couldn't explain his presence, so he confessed to everything. Everyone else goes home free while I rot in a cell. The watch is still running, and nobody noticed.",
			}
		"bad_end_C":
			return {
				"button": "Return to Title",
				"title": "Case Closed.",
				"body": "Charlotte takes the fall. The glass she held was enough to convict her, even if she wasn't the one who decided to pour it. I'm still here, and the watch is still ticking.",
			}
		"bad_end_A":
			return {
				"button": "Return to Title",
				"title": "Case Closed.",
				"body": "Aleph is in cuffs, but his systems are still running. Locking up the man who balanced the books doesn't change what's already been written. I failed to stop the actual crime.",
			}
		"bad_end_H":
			return {
				"button": "Return to Title",
				"title": "Case Closed.",
				"body": "Harold was the last line of defense, and now he's the first sacrifice. The trap at the door worked perfectly, just not on the person they expected. I'm still trapped in this room.",
			}
		"bad_end_weak":
			return {
				"button": "Return to Title",
				"title": "Case Closed.",
				"body": "A guess is just a guess. The room doesn't care about my doubts, it only cares about the results. I'm still stuck in the silence.",
			}
		_:
			return {
				"button": "Return to Title",
				"title": "Case Closed.",
				"body": "The room keeps its secret.",
			}
