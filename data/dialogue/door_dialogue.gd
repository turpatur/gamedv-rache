extends RefCounted
class_name DoorDialogue

func intro(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"Locked from the outside.",
				"The mechanism was modified by someone who knows how doors work.",
				"It's a cage. Anyone trying to leave is going to regret it.",
			]
		1:
			return [
				"Still locked, same modified mechanism.",
				"Whoever built this made it to hold once, and hold well.",
				"Precise handiwork, if I had to guess.",
			]
		_:
			return [
				"I keep checking the door like it's going to miraculously open.",
				"It won't.",
				"I'm locked in here with a corpse and a ticking clock.",
			]

func revisit(phase: int, ng_plus: bool, door_after_rache: bool) -> Array[String]:
	if phase == 0:
		return [
			"Trap. Precision work.",
			"It reacts exactly how an investigator would test a locked room.",
		]
	if ng_plus and door_after_rache:
		return [
			"Same trap, same precision.",
			"Not just built for an investigator.",
			"Built for me.",
		]
	return [
		"Same trap, same precision.",
		"Built for someone who tests doors exactly like I do.",
	]

func mechanism_clear(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"This rig is precise. It wasn't built in a hurry.",
				"A technician's signature is all over this. They turned security into a weapon.",
			]
		_:
			return [
				"Same rig, same precision.",
				"Designed for the investigator.",
				"Designed for me, technically.",
			]

func mechanism_hazy() -> Array[String]:
	return [
		"A trap.",
		"But I don't have enough context to say who it was built for.",
	]

func frame(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"Small, precise markings on the frame.",
				"This was measured and tested.",
				"Whoever did this works within strict systems.",
			]
		_:
			return [
				"The markings again.",
				"Precise, almost bureaucratic.",
				"They didn't think of it as violence, just procedure.",
			]

func force_ng_plus() -> Array[String]:
	return [
		"I don't need to open it, I know exactly where the wire is.",
		"The trap wasn't built for a body, it was built for a habit.",
		"They knew exactly where my hand would go.",
	]

func force_repeat() -> Array[String]:
	return [
		"I already know how this ends.",
		"Repeating it won't make me any smarter.",
	]

func force_death_intro() -> Array[String]:
	return [
		"The handle clicks. A spike shoots through my palm.",
		"White light. Sharp, cold agony in my nerves.",
		"I'm falling. Not again. I don't want to go back.",
	]

func leave() -> Array[String]:
	return ["I shouldn't touch that without a reason."]
