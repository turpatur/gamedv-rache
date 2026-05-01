extends CanvasLayer
class_name UIRoot

signal start_game_requested
signal restart_requested
signal quit_requested
signal choice_selected(index: int)
signal verdict_submitted(key: String)

@export var hud_path: NodePath
@export var dialogue_path: NodePath
@export var choice_path: NodePath
@export var verdict_path: NodePath
@export var death_path: NodePath
@export var title_path: NodePath
@export var end_path: NodePath
@export var profile_path: NodePath

@onready var hud: HUDView = _resolve(hud_path, "HUD") as HUDView
@onready var dialogue_ui: DialogueUI = _resolve(dialogue_path, "DialogueUI") as DialogueUI
@onready var choice_ui: ChoiceUI = _resolve(choice_path, "ChoiceUI") as ChoiceUI
@onready var verdict_ui: VerdictUI = _resolve(verdict_path, "VerdictUI") as VerdictUI
@onready var death_ui: DeathUI = _resolve(death_path, "DeathUI") as DeathUI
@onready var title_screen: TitleScreen = _resolve(title_path, "TitleScreen") as TitleScreen
@onready var end_screen: EndScreen = _resolve(end_path, "EndScreen") as EndScreen
@onready var profile_overlay: ProfileOverlay = _resolve(profile_path, "ProfileOverlay") as ProfileOverlay

func _ready() -> void:
	if title_screen != null:
		title_screen.start_requested.connect(func(): start_game_requested.emit())
	if end_screen != null:
		end_screen.restart_requested.connect(func(): restart_requested.emit())
		end_screen.quit_requested.connect(func(): quit_requested.emit())
	if choice_ui != null:
		choice_ui.option_selected.connect(func(index: int): choice_selected.emit(index))
	if verdict_ui != null:
		verdict_ui.verdict_selected.connect(func(key: String): verdict_submitted.emit(key))

func update_hud(prompt: String, loop_count: int, clear_count: int, hazy_count: int, lead: String, has_died: bool = false) -> void:
	if hud != null:
		hud.update_hud(prompt, loop_count, clear_count, hazy_count, lead, has_died)

func show_dialogue_line(text: String) -> void:
	if dialogue_ui != null:
		dialogue_ui.show_line(text)

	if choice_ui != null:
		choice_ui.hide_choices()

func close_dialogue() -> void:
	if dialogue_ui != null:
		dialogue_ui.clear()
	if choice_ui != null:
		choice_ui.hide_choices()

func show_choices(options: Array) -> void:
	if choice_ui == null:
		return
	if options.is_empty():
		choice_ui.hide_choices()
	else:
		choice_ui.show_choices(options)

func show_death(reason: String, fast_mode: bool = false) -> void:
	if death_ui != null:
		death_ui.show_death(reason, fast_mode)

func hide_death() -> void:
	if death_ui != null:
		death_ui.hide_death()

func play_death_return_transition() -> void:
	if death_ui != null:
		await death_ui.play_return_transition()

func open_verdict(title: String, labels: Array[String]) -> void:
	if verdict_ui != null:
		verdict_ui.show_verdict(title, labels)
	if hud != null:
		hud.visible = false
	if dialogue_ui != null:
		dialogue_ui.visible = false

func close_verdict() -> void:
	if verdict_ui != null:
		verdict_ui.hide_verdict()
	if hud != null:
		hud.visible = true

func show_title() -> void:
	if title_screen != null:
		title_screen.show_screen()

func hide_title() -> void:
	if title_screen != null:
		title_screen.hide_screen()

func show_ending(title: String, body: String, button_text: String) -> void:
	if end_screen != null:
		end_screen.show_ending(title, body, button_text)

func hide_ending() -> void:
	if end_screen != null:
		end_screen.hide_screen()

func show_profile(letter: String) -> void:
	if profile_overlay != null:
		profile_overlay.show_profile(letter)

func hide_profile() -> void:
	if profile_overlay != null:
		profile_overlay.hide_profile()

func _resolve(path: NodePath, fallback_name: String) -> Node:
	if path != NodePath(""):
		return get_node_or_null(path)
	return find_child(fallback_name, true, false)
