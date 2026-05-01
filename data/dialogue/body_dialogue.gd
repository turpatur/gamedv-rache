extends RefCounted
class_name BodyDialogue

func intro(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"No signs of a struggle. He just sat there and took it.",
				"Didn't even try to run.",
				"He either knew the killer, or he was too paralyzed to move.",
			]
		1:
			return [
				"The body hasn't moved since my last loop.",
				"He came here willingly, completely unaware of the trap.",
				"Why did he feel so safe in this room?",
			]
		_:
			return [
				"I'm waiting for him to wake up and tell me what happened.",
				"He trusted the wrong person.",
				"His posture says it all. He wasn't afraid until it was too late.",
			]

func revisit(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"No defensive wounds.",
				"He let the killer in. Or they were already here.",
			]
		_:
			return [
				"Someone he knew well. Someone he let get close.",
				"You don't get a kill this clean by accident.",
			]

func position_clear(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"Chair pulled in. He was comfortable.",
				"They were having a regular meeting.",
				"The killer wasn't a stranger. They were a confidant.",
			]
		_:
			return [
				"Same read as before.",
				"The killer was someone allowed to get exactly this close.",
			]

func position_hazy() -> Array[String]:
	return [
		"He trusted the person across from him.",
		"But I don't know why he agreed to meet in the first place.",
	]

func glass2(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"A second glass. Clean. Untouched.",
				"The killer poured a drink just for the look of it.",
				"A hollow gesture for a man about to die.",
			]
		_:
			return [
				"Clean glass again.",
				"You sit across from someone, watch them die, and don't spill a drop.",
				"That's the work of someone used to hiding messes.",
			]

func leave() -> Array[String]:
	return ["Some things are better left where they fell."]
