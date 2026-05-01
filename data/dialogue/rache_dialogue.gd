extends RefCounted
class_name RacheDialogue

func intro(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"Blood smeared beside the corpse, spelling RACHE.",
				"Five marks. Each one looks like a separate, jagged thought.",
				"The E at the end... it's like he ran out of strength or just gave up.",
			]
		1:
			return [
				"The blood message again.",
				"I keep reading it as the German word for revenge.",
				"But this guy doesn't look like the poetic type.",
			]
		_:
			return [
				"Jagged strokes. The spacing is all wrong for a single word.",
				"It’s not just a message. It’s a sequence.",
				"He was pointing at something I'm still not seeing.",
			]

func revisit(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"The letters don't flow. They're punched into the floor individually.",
				"Like he was checking items off a mental list as he died.",
				"The E trails after them like it doesn't belong.",
			]
		_:
			return [
				"A dying declaration.",
				"RACH are written with heavy recognition.",
				"E is the outsider he couldn't quite place.",
			]

func read() -> Array[String]:
	return [
		"RACHE. Revenge, if I force the letters together.",
		"But dead men don't write poetry when they're choking on poison.",
		"This is a list of people.",
	]

func pressure_marks(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"The pressure on each letter is different.",
				"It wasn't written in one go. It was a series of separate, violent strikes.",
				"He wasn't writing a word. He was naming his ghosts.",
			]
		_:
			return [
				"The pressure changes only after H.",
				"R, A, C, H wasn't an accident of handwriting.",
				"A whole room full of debts came due today.",
			]

func faint_final_stroke(ng_plus: bool) -> Array[String]:
	if ng_plus:
		return [
			"The E is almost gone. Not one of his people.",
			"An outsider shape at the edge of the plan.",
			"Elliott. Me. I'm the missing piece.",
		]
	return [
		"The E is faint, like he tried to finish a thought and failed.",
		"Someone outside the obvious four, maybe.",
		"Or just a dying hand running out of blood.",
	]

func leave() -> Array[String]:
	return ["I've seen enough of this mess for one look."]
