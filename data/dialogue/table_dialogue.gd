extends RefCounted
class_name TableDialogue

func intro(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"A single glass on the table. Most of it is gone.",
				"There's a residue on the rim. It's not wine.",
				"Smells like almonds and copper.",
			]
		1:
			return [
				"The glass is still here.",
				"I already know what's in it.",
				"The question is who had the patience to watch him drink it.",
			]
		_:
			return [
				"I keep coming back to this glass.",
				"It won't give me a different answer.",
				"A calculated move, maybe.",
			]

func revisit(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"Bitter almond and a metallic bite.",
				"Perfectly measured. Lethal.",
				"A professional job.",
			]
		_:
			return [
				"Same bitter read.",
				"Someone made peace with murdering him before they ever walked in.",
			]

func glass_clear(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"The residue is undeniable. It's a calculated dose.",
				"Whoever poured this knew exactly when it would take hold.",
				"Someone with steady hands. This is their work.",
			]
		_:
			return [
				"Same residue, same cold precision.",
				"Surgical work.",
				"One of his people must have poured this.",
			]

func glass_hazy() -> Array[String]:
	return [
		"There's residue on the rim.",
		"I need more context to understand the poison.",
	]

func smell(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"Bitter almond and metal.",
				"Not a drink.",
				"A weapon.",
			]
		_:
			return [
				"The same poison.",
				"I don't need to smell it again.",
			]

func taste_ng_plus() -> Array[String]:
	return [
		"I don't need to taste it, my throat remembers the burning.",
		"This glass was a rehearsal.",
		"They knew exactly how this would feel.",
	]

func taste_repeat() -> Array[String]:
	return [
		"I already know how this ends.",
		"Repeating it won't make me any smarter.",
	]

func taste_death_intro() -> Array[String]:
	return [
		"I touch the residue to my tongue. Bitter almonds.",
		"My throat is tightening. It feels like I'm swallowing fire.",
		"I can't get any air. Everything is going cold.",
	]

func leave() -> Array[String]:
	return ["Not everything needs to be touched."]
