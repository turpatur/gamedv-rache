extends RefCounted
class_name ScoreConfig

const SCORE_KEYS: Array[String] = ["R", "A", "C", "H", "SELF"]
const VERDICT_KEYS: Array[String] = ["R", "A", "C", "H", "self", "back"]
const KEY_LABELS: Array[String] = ["A", "B", "C", "D", "E", "F"]

func score_key(id: String) -> String:
	var up := id.to_upper()
	return "SELF" if (up == "SELF" or id.to_lower() == "self") else up

func empty_score() -> Dictionary:
	var result := {}
	for key in SCORE_KEYS:
		result[key] = 0
	return result

func case_strength(score: Dictionary, id: String) -> String:
	var key := score_key(id)
	var v := int(score.get(key, 0))
	if v >= 4:
		return "Strong case"
	if v >= 2:
		return "Plausible case"
	return "Weak case"

func next_key_label(count: int) -> String:
	return KEY_LABELS[clampi(count, 0, KEY_LABELS.size() - 1)]
