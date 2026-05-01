extends RefCounted
class_name PhotoDialogue

func intro(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"A bookshelf behind the desk. Heavy mahogany.",
				"Ledgers, debt books, and files on everyone who worked here.",
				"The kind of records you keep when you want to own people.",
			]
		_:
			return [
				"The ledger is still there. Pages of people held under a thumb.",
				"A few entries have been thumbed so much the ink is fading.",
			]

func revisit(phase: int, ng_plus: bool, diary_seen: bool) -> Array[String]:
	if ng_plus and not diary_seen:
		return [
			"The ledger feels heavier now.",
			"Something hidden in its spine is waiting to be found.",
		]
	match phase:
		0:
			return [
				"The profiles are organized by department. By utility.",
				"I keep seeing the same initials in the red-ink margins.",
				"One name in particular has a lot of notes in the 'Reprimand' column.",
			]
		_:
			return [
				"My name isn't in there. I'm the ghost in this room.",
				"It's a cold thought that won't go away.",
			]

func shelf() -> Array[String]:
	return [
		"Debt records and medical expenses marked as 'advances'.",
		"To the boss, it was just accounting. To them, it was a cage.",
	]

func open_ledger_intro() -> Array[String]:
	return [
		"The employee ledger opens with a dry crack.",
		"Each tab is marked with a single letter.",
		"I'm starting to see a pattern in the way this man kept his people.",
	]

func profile_raphael(phase: int, ng_plus: bool) -> Array[String]:
	var lines: Array[String] = [
		"Raphael Alexandre.",
		"The favored weapon. Trusted enough to be summoned for private meetings.",
		"He knew the victim's habits better than anyone else.",
	]
	if ng_plus:
		lines.append("He was forced to betray his own blood to keep his job.")
		lines.append("The victim had him on a short, painful leash.")
	elif phase == 0:
		lines.append("He's the obvious suspect. Maybe too obvious.")
	return lines

func profile_aleph(_phase: int, ng_plus: bool) -> Array[String]:
	var lines: Array[String] = [
		"Aleph Cerny.",
		"The records clerk who made ugly things look orderly.",
		"He managed the debts and the punishments with cold efficiency.",
	]
	if ng_plus:
		lines.append("He was forced to balance the books while his own family went under.")
		lines.append("Every record he kept was a nail in his own coffin.")
	else:
		lines.append("A planner's mind. But someone else had to be the one with the blood on them.")
	return lines

func profile_charlotte(_phase: int, ng_plus: bool) -> Array[String]:
	var lines: Array[String] = [
		"Charlotte Hahn.",
		"The cleaner. Responsible for drinks, remedies, and hiding stains.",
		"Her record notes chemical purchases as 'household necessities'.",
	]
	if ng_plus:
		lines.append("She was forced to clean the rooms where her own people were hurt.")
		lines.append("The victim made her sweep up her own grief.")
	else:
		lines.append("Poison is her specialty, but she needs a reason to pour the glass.")
	return lines

func profile_harold(_phase: int, ng_plus: bool) -> Array[String]:
	var lines: Array[String] = [
		"Harold Evans.",
		"The locksmith. Paid to build barriers and punished when they failed.",
		"He's the man you call when a door needs to stay closed.",
	]
	if ng_plus:
		lines.append("He was forced to build the very cells used to disappear his friends.")
		lines.append("The victim turned his craftsmanship into a nightmare of isolation.")
	else:
		lines.append("He explains the trap on the door, but not the invited guest.")
	return lines

func diary_page() -> Array[String]:
	return [
		"A hidden page. The victim's private diary entry.",
		"He suspected his circle, but felt safe because of the watch.",
		"An antique fail-safe that resets the day upon its owner's death.",
	]

func diary_revisit() -> Array[String]:
	return [
		"The note at the bottom mentions 'E' as an advisor.",
		"I unknowingly taught them how a detective thinks.",
		"I showed them how to make a murder look like a mystery.",
	]

func close_ledger() -> Array[String]:
	return ["The ledger closes. The names stay buried for now."]
