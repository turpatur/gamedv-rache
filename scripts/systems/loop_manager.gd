extends Node
class_name LoopManager

signal death_started(reason: String, fast_mode: bool)
signal death_overlay_done
signal loop_restarted(lines: Array)

var state: RacheGameState
var save_manager: SaveManager

func setup(state_ref: RacheGameState, save_ref: SaveManager) -> void:
	state = state_ref
	save_manager = save_ref

func apply_death_bias_shift(cause: String) -> void:
	state.route["has_valid_death"] = true
	match cause:
		"poison":
			state.route["poison_death_spent"] = true
			state.add_score("C", 1)
		"door":
			state.route["door_death_spent"] = true
			state.add_score("H", 1)
			state.add_score("SELF", 1)
			state.reduce_score("C", 1)
		"watch":
			state.route["watch_death_spent"] = true
			state.add_score("SELF", 2)
			state.reduce_score("R", 1)
			state.reduce_score("A", 1)
			state.reduce_score("C", 1)
			state.reduce_score("H", 1)

func queue_death(cause: String, reason: String) -> void:
	state.pending_death_reason = reason
	state.pending_death = true
	apply_death_bias_shift(cause)

func die(reason: String) -> void:
	if state.dying:
		return
	state.dying = true
	state.has_died = true
	state.movement_locked = true
	
	var is_fast: bool = state.loop_count > 1
	death_started.emit(reason, is_fast)
	
	var death_wait: float = 1.5 if is_fast else 4.5
	await get_tree().create_timer(death_wait).timeout

	state.loop_count += 1
	state.door_approach_count = 0
	if save_manager != null:
		save_manager.save_checkpoint()

	state.player_pos = Vector2(460, 420)
	state.load_flash = 1.0
	state.input_disorientation = 0.4

	death_overlay_done.emit()
	state.dying = false
	await get_tree().create_timer(1.08).timeout
	loop_restarted.emit(death_return_lines())

func death_return_lines() -> Array[String]:
	if state.loop_count == 2:
		return [
			"My head—it's splitting. A dull, rhythmic ache behind my eyes.",
			"The watch is ticking in my skull. I know exactly where it is.",
			"Dying... it wasn't just a dream. It hurt. It still hurts.",
		]
	return [
		"Again. Same room, same splitting headache.",
		"The pain is starting to feel permanent. I can't keep doing this.",
		"What did I miss? Why am I still here?",
	]
