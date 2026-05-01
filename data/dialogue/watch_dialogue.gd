extends RefCounted
class_name WatchDialogue

func ng_plus_intro() -> Array[String]:
	return [
		"The watch is still ticking. It's vibrating in my pocket, even though it's not mine.",
		"Every click feels like a needle behind my eyes.",
		"It's been constant since the first time I woke up.",
	]

func forced_death_intro() -> Array[String]:
	return [
		"The case is almost neat, but the watch isn't finished.",
		"It starts ticking louder, like it's counting down to something I can't see.",
	]

func no_death_intro() -> Array[String]:
	return [
		"A pocket watch, stopped near the time of death.",
		"It belongs to the victim.",
		"The metal is still warm to the touch.",
	]

func after_death_intro(phase: int) -> Array[String]:
	match phase:
		0:
			return [
				"The watch again. I knew it was here before I saw it.",
				"That sense of deja vu is becoming a habit.",
			]
		1:
			return [
				"The watch is in the same place every time.",
				"I keep thinking I should leave it alone, yet here I am.",
			]
		_:
			return [
				"Still here, waiting for me to admit what I already know.",
				"There's something in this mechanism that isn't ready to be found.",
				"I hate this case.",
			]

func listen_it() -> Array[String]:
	return [
		"The ticking is loud enough to hear in my teeth.",
		"It's cold. Heavy. Like it’s pulling heat out of my hand.",
		"I'm not holding a watch. I'm holding a reason to stay dead.",
	]

func hold_ng_plus_gate() -> Array[String]:
	return [
		"The lid gives under my thumb. There's no mechanism inside.",
		"Only a sound I recognize too late.",
	]

func hold_ng_plus_waiting() -> Array[String]:
	return [
		"The lid catches under my thumb. It refuses to open.",
		"It's not locked. It's waiting.",
	]

func hold(phase: int) -> Array[String]:
	match phase:
		1:
			return [
				"No sound, no image. Just a sudden, cold pressure in my chest.",
				"It feels like someone is standing right behind me.",
				"They wanted me to see this. They wanted a witness.",
			]
		_:
			return [
				"That pressure is back. The victim's last few seconds, trapped in metal.",
				"They didn't want to just disappear. They wanted to be remembered.",
				"I know that feeling better than I'd like to admit.",
			]

func leave(phase: int) -> Array[String]:
	match phase:
		0:
			return ["Not yet."]
		1:
			return ["Still not yet."]
		_:
			return [
				"I keep saying 'not yet'.",
				"At some point, caution becomes something else entirely.",
			]

func listen_true_end() -> Array[String]:
	return [
		"I know why you're ticking in my head.",
		"I am the 'E' in RACHE. The missing link that turns four suspects into a conspiracy.",
		"To break the cycle, I have to stop pointing fingers and take the blame.",
	]

func not_yet_ng_plus() -> Array[String]:
	return [
		"Right. Not yet.",
		"I really need to stop saying that.",
	]
