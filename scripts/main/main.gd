extends Node2D

@export_group("Gameplay Settings")
@export var player_speed: float = 230.0
@export var room_bounds: Rect2 = Rect2(80, 70, 800, 470)

@export_group("Audio Assets")
@export_file("*.mp3") var title_bgm: String = "res://assets/audio/title.mp3"
@export_file("*.mp3") var gameplay_bgm: String = "res://assets/audio/gameplay.mp3"
@export_file("*.mp3") var interact_sfx: String = "res://assets/audio/Interact.mp3"

@export_group("Timers")
@export var load_flash_fade_speed: float = 1.8
@export var input_disorientation_fade_speed: float = 1.0
@export var prompt_notice_default_duration: float = 1.8

const GameStateScript := preload("res://scripts/systems/game_state.gd")
const SaveManagerScript := preload("res://scripts/systems/save_manager.gd")
const LoopManagerScript := preload("res://scripts/systems/loop_manager.gd")
const InvestigationControllerScript := preload("res://scripts/systems/investigation_controller.gd")
const EndingRouterScript := preload("res://scripts/systems/ending_router.gd")
const NarrativeControllerScript := preload("res://scripts/systems/narrative_controller.gd")

var state: RacheGameState
var save_manager: SaveManager
var loop_manager: LoopManager
var investigation: InvestigationController
var ending_router: EndingRouter
var narrative: NarrativeController

@onready var player: Node2D = get_node_or_null("Player") as Node2D
@onready var ui_root: UIRoot = get_node_or_null("UIRoot") as UIRoot

var interactables: Array[Node] = []

func _ready() -> void:
	_build_systems()
	_bind_ui()
	_collect_interactables()
	_configure_player()
	_show_title()

func _process(delta: float) -> void:
	if state.game_state == GameStateScript.ScreenState.PLAYING:
		_update_movement(delta)
		_update_nearest()
		_update_hud()

	state.load_flash = max(state.load_flash - delta * load_flash_fade_speed, 0.0)
	state.prompt_notice_timer = max(state.prompt_notice_timer - delta, 0.0)
	state.input_disorientation = max(state.input_disorientation - delta * input_disorientation_fade_speed, 0.0)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if state.input_disorientation > 0.0:
		return

	match state.game_state:
		GameStateScript.ScreenState.TITLE:
			if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
				_start_game()
		GameStateScript.ScreenState.ENDING:
			if event.keycode in [KEY_R, KEY_ENTER, KEY_SPACE]:
				_on_restart_pressed()
			elif event.keycode == KEY_ESCAPE:
				get_tree().quit()
		GameStateScript.ScreenState.VERDICT:
			pass
		GameStateScript.ScreenState.PLAYING:
			if state.verdict_active:
				return
			if state.awaiting_choice:
				if event.keycode >= KEY_1 and event.keycode <= KEY_6:
					var idx := int(event.keycode) - int(KEY_1)
					narrative.pick_choice(idx)
				return
			if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
				if state.dialogue_active:
					if ui_root.dialogue_ui.is_typing:
						ui_root.dialogue_ui.skip_typing()
					else:
						SoundManager.play_sfx(interact_sfx)
						narrative.advance()
				else:
					if state.nearest_id != "":
						SoundManager.play_sfx(interact_sfx)
						_interact()

func _build_systems() -> void:
	state = GameStateScript.new()
	save_manager = SaveManagerScript.new()
	loop_manager = LoopManagerScript.new()
	investigation = InvestigationControllerScript.new()
	ending_router = EndingRouterScript.new()
	narrative = NarrativeControllerScript.new()

	add_child(state)
	add_child(save_manager)
	add_child(loop_manager)
	add_child(investigation)
	add_child(ending_router)
	add_child(narrative)

	save_manager.setup(state)
	loop_manager.setup(state, save_manager)
	narrative.setup(state)
	investigation.setup(state, narrative, loop_manager, ui_root)
	ending_router.setup(state)

	narrative.line_rendered.connect(_on_dialogue_line_rendered)
	narrative.choices_rendered.connect(_on_choices_rendered)
	narrative.dialogue_closed.connect(_on_dialogue_closed)

	loop_manager.death_started.connect(_on_death_started)
	loop_manager.death_overlay_done.connect(_on_death_overlay_done)
	loop_manager.loop_restarted.connect(_on_loop_restarted)

	investigation.verdict_open_requested.connect(_open_verdict)

func _bind_ui() -> void:
	if ui_root == null:
		return
	ui_root.start_game_requested.connect(_start_game)
	ui_root.restart_requested.connect(_on_restart_pressed)
	ui_root.quit_requested.connect(func(): get_tree().quit())
	ui_root.choice_selected.connect(func(index: int): narrative.pick_choice(index))
	ui_root.verdict_submitted.connect(_submit_verdict)

func _configure_player() -> void:
	if player == null:
		return
	if player.has_method("configure"):
		player.configure(room_bounds, player_speed)
	if player.has_method("set_player_position"):
		player.set_player_position(state.player_pos)
	else:
		player.global_position = state.player_pos
	_sync_player_movement_lock()

func _collect_interactables() -> void:
	interactables = get_tree().get_nodes_in_group("interactable")

func _show_title() -> void:
	state.reset_for_title()
	_set_player_to_state_position()
	_sync_player_movement_lock()
	if ui_root != null:
		ui_root.close_dialogue()
		ui_root.close_verdict()
		ui_root.hide_ending()
		ui_root.show_title()
		ui_root.hide_death()
	_update_hud()
	SoundManager.play_bgm(title_bgm)

func _start_game() -> void:
	SoundManager.play_bgm(gameplay_bgm)
	save_manager.delete_checkpoint()
	state.reset_for_new_game()
	_set_player_to_state_position()
	_sync_player_movement_lock()
	if ui_root != null:
		ui_root.close_dialogue()
		ui_root.hide_title()
		ui_root.hide_ending()
		ui_root.close_verdict()
		ui_root.hide_death()
	narrative.show_dialogue(RacheIntroDialogue.OPENING)
	_sync_player_movement_lock()
	save_manager.save_checkpoint()

func _restart_ng_plus() -> void:
	SoundManager.play_bgm(gameplay_bgm)
	state.reset_for_ng_plus()
	_set_player_to_state_position()
	_sync_player_movement_lock()
	if ui_root != null:
		ui_root.close_dialogue()
		ui_root.hide_ending()
		ui_root.hide_title()
		ui_root.close_verdict()
		ui_root.hide_death()
	save_manager.save_checkpoint()
	narrative.show_dialogue(RacheIntroDialogue.NG_PLUS_OPENING)
	_sync_player_movement_lock()

func _on_restart_pressed() -> void:
	if state.ng_plus and state.game_state == GameStateScript.ScreenState.ENDING:
		_restart_ng_plus()
	else:
		_show_title()

func _update_movement(delta: float) -> void:
	if player == null:
		return
	var locked := state.movement_locked or state.dialogue_active or state.awaiting_choice or state.verdict_active or state.dying
	if player.has_method("set_movement_locked"):
		player.set_movement_locked(locked)
	if player.has_method("process_movement"):
		player.process_movement(delta)
	state.player_pos = player.global_position

func _update_nearest() -> void:
	state.nearest_id = ""
	var best := INF
	for item in interactables:
		if item == null:
			continue
		var item_node := item as Node2D
		if item_node == null:
			continue
		var item_id := String(item.get("object_id"))
		if item_id == "":
			continue
		var radius := float(item.get("interaction_radius"))
		var pos := item_node.global_position
		if item.has_method("get_interaction_position"):
			pos = item.get_interaction_position()
		var d := state.player_pos.distance_to(pos)
		if d <= radius and d < best:
			best = d
			state.nearest_id = item_id

	for item in interactables:
		if item != null and item.has_method("set_highlighted"):
			item.set_highlighted(String(item.get("object_id")) == state.nearest_id)

	var near_door := state.nearest_id == "door"
	var can_ambient := not state.movement_locked and not state.dialogue_active and not state.awaiting_choice and not state.verdict_active
	if near_door and not state.was_near_door and can_ambient:
		investigation.try_door_rach_ambient()
	state.was_near_door = near_door

func _update_hud() -> void:
	if ui_root == null:
		return
	var prompt := ""
	if state.prompt_notice_timer > 0.0:
		prompt = state.prompt_notice
	elif state.dialogue_active or state.awaiting_choice or state.verdict_active:
		prompt = ""
	elif state.nearest_id != "":
		if state.nearest_id == "watch" and state.can_open_verdict():
			prompt = "[E] Verdict"
		elif state.nearest_id == "photo":
			prompt = "[E] Examine bookshelf"
		else:
			prompt = "[E] Examine %s" % state.nearest_id.capitalize()

	ui_root.update_hud(prompt, state.loop_count, state.clear_count(), state.hazy_count(), state.current_lead(), state.has_died)

func _interact() -> void:
	if state.nearest_id == "":
		return
	investigation.inspect(state.nearest_id)

func _open_verdict() -> void:
	state.game_state = GameStateScript.ScreenState.VERDICT
	state.verdict_active = true
	state.movement_locked = true
	state.dialogue_active = false
	if ui_root != null:
		ui_root.close_dialogue()
		ui_root.open_verdict(ending_router.build_verdict_title(), ending_router.build_verdict_labels())

func _submit_verdict(key: String) -> void:
	if key == "back":
		state.game_state = GameStateScript.ScreenState.PLAYING
		state.verdict_active = false
		state.movement_locked = false
		if ui_root != null:
			ui_root.close_verdict()
		return

	state.game_state = GameStateScript.ScreenState.PLAYING
	state.verdict_active = false
	state.movement_locked = false
	state.verdict_choice = key
	if ui_root != null:
		ui_root.close_verdict()

	var resolved := ending_router.resolve_ending(key)
	state.pending_ending_id = resolved
	narrative.show_dialogue(ending_router.verdict_dialogue(key, resolved))

func _show_ending(ending_id: String) -> void:
	state.game_state = GameStateScript.ScreenState.ENDING
	state.movement_locked = true
	state.dialogue_active = false
	state.verdict_active = false
	_sync_player_movement_lock()

	ending_router.apply_ending_side_effects(ending_id)
	var data := ending_router.ending_data(ending_id)

	if ui_root != null:
		ui_root.close_dialogue()
		ui_root.close_verdict()
		ui_root.show_ending(String(data["title"]), String(data["body"]), String(data["button"]))

	save_manager.save_checkpoint()

func _on_dialogue_line_rendered(text: String) -> void:
	if ui_root != null:
		ui_root.show_dialogue_line(text)

func _on_choices_rendered(options: Array) -> void:
	if ui_root != null:
		ui_root.show_choices(options)

func _on_dialogue_closed() -> void:
	if state.pending_death:
		state.pending_death = false
		var reason := state.pending_death_reason
		state.pending_death_reason = ""
		loop_manager.die(reason)
		return
	if state.pending_ending_id != "":
		var ending_id := state.pending_ending_id
		state.pending_ending_id = ""
		_show_ending(ending_id)
		return
	state.show_prompt_notice(state.after_clue_hint(), prompt_notice_default_duration)

func _on_death_started(reason: String, fast_mode: bool) -> void:
	if ui_root != null:
		ui_root.show_death(reason, fast_mode)

func _on_death_overlay_done() -> void:
	_set_player_to_state_position()
	if ui_root != null:
		await ui_root.play_death_return_transition()
		ui_root.hide_death()

func _on_loop_restarted(lines: Array) -> void:
	_set_player_to_state_position()
	narrative.show_dialogue(lines)

func _set_player_to_state_position() -> void:
	if player == null:
		return
	if player.has_method("set_player_position"):
		player.set_player_position(state.player_pos)
	else:
		player.global_position = state.player_pos

func _sync_player_movement_lock() -> void:
	if player != null and player.has_method("set_movement_locked"):
		player.set_movement_locked(state.movement_locked)
