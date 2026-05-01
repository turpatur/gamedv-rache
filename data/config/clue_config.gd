extends RefCounted
class_name ClueConfig

const CLUE_IDS: Array[String] = ["table", "body", "rache", "door", "photo", "watch"]
const CORE_CLUES: Array[String] = ["table", "body", "rache", "door", "photo"]

const CLUE_DEPS: Dictionary = {
	"table": "",
	"body": "table",
	"rache": "body",
	"door": "rache",
	"photo": "door",
	"watch": "",
}

const INTERACTABLES: Array[Dictionary] = [
	{"id": "body",  "name": "Body",         "pos": Vector2(265, 342), "radius": 85.0},
	{"id": "rache", "name": "RACHE",        "pos": Vector2(735, 150), "radius": 92.0},
	{"id": "table", "name": "Table",        "pos": Vector2(485, 255), "radius": 95.0},
	{"id": "door",  "name": "Door",         "pos": Vector2(498, 93),  "radius": 86.0},
	{"id": "photo", "name": "Bookshelf",    "pos": Vector2(195, 165), "radius": 65.0},
	{"id": "watch", "name": "Pocket Watch", "pos": Vector2(760, 432), "radius": 72.0},
]

const DOOR_RACHE_POOL: Array[Array] = [
	[
		"[Voices outside the door.]",
		"Voice 1: \"It's done.\"",
		"Flat voice: \"Clean enough.\"",
	],
	[
		"[Footsteps stop outside.]",
		"Low voice: \"No witnesses.\"",
		"Low voice: \"Check it again.\"",
	],
	[
		"Shaking voice: \"Was there another way?\"",
		"Flat voice: \"Probably.\"",
		"Flat voice: \"But we'd already waited long enough.\"",
	],
	[
		"Voice 1: \"How long do we hold?\"",
		"Flat voice: \"Until it's not a question anymore.\"",
		"Shaking voice: \"...Yeah. Okay.\"",
	],
	[
		"Flat voice: \"The timeline moved. Messy.\"",
		"Flat voice: \"But the outcome is correct.\"",
		"Flat voice: \"The outcome was always going to be correct.\"",
	],
	[
		"Low voice: \"The investigator is contained.\"",
		"Shaking voice: \"I just want to go home.\"",
		"Voice 1: \"The door holds. We're done.\"",
	],
]

func dependency_for(object_id: String) -> String:
	return String(CLUE_DEPS.get(object_id, ""))

func core_clues() -> Array[String]:
	return CORE_CLUES.duplicate()

func clue_ids() -> Array[String]:
	return CLUE_IDS.duplicate()

func interactable_defs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in INTERACTABLES:
		result.append(item.duplicate(true))
	return result

func door_rache_pool() -> Array[Array]:
	var result: Array[Array] = []
	for entry in DOOR_RACHE_POOL:
		result.append(entry.duplicate())
	return result
