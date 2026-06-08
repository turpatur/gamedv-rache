extends Control
class_name DialogueUI

@export var dialogue_label_path: NodePath
@export var continue_hint: String = "[E] Continue"
@export var show_continue_hint: bool = true
@export var characters_per_second: float = 75.0

@export_group("Show Transition Settings")
@export var show_fade_duration: float = 0.25
@export var show_scale_duration: float = 0.35
@export var show_slide_duration: float = 0.30
@export var show_slide_offset: float = 20.0
@export var show_initial_scale: Vector2 = Vector2(0.95, 0.95)

@export_group("Hide Transition Settings")
@export var hide_duration: float = 0.18
@export var hide_slide_offset: float = 15.0
@export var hide_final_scale: Vector2 = Vector2(0.95, 0.95)

@export_group("Continue Hint Placement")
@export var hint_font_size_reduction: int = 4
@export var hint_offset_left: float = -250.0
@export var hint_offset_top: float = -60.0
@export var hint_offset_right: float = -65.0
@export var hint_offset_bottom: float = -30.0

@export_group("Continue Hint Animation")
@export var hint_pulse_duration: float = 0.5
@export var hint_pulse_min_alpha: float = 0.3
@export var hint_pulse_max_alpha: float = 1.0



@export_group("Idle Bobbing Settings")
@export var idle_bobbing_enabled: bool = true
@export var idle_bob_up_offset: float = -3.0
@export var idle_bob_down_offset: float = 1.0
@export var idle_bob_duration: float = 1.5

@onready var dialogue_label: Label = _resolve_label()
@onready var dialogue_panel: NinePatchRect = find_child("DialoguePanel", true, false) as NinePatchRect

var is_typing: bool = false
var _active_tween: Tween
var _current_dialogue_text: String = ""
var _should_show_hint: bool = false

# Polishing variables
var continue_label: Label
var _default_panel_y: float = -1.0
var _idle_tween: Tween
var _hint_tween: Tween
var _transition_tween: Tween


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if dialogue_label == null:
		push_error("DialogueUI needs Dialogue Label Path assigned to DialoguePanel/MarginContainer/DialogueText.")
	
	_setup_continue_label()


func show_line(text: String, with_hint: bool = true) -> void:
	if dialogue_label == null:
		return

	_kill_tween()
	_kill_idle_tween()
	_kill_transition_tween()
	_hide_hint()

	var clean_text: String = text.strip_edges()
	if clean_text == "":
		clear()
		return

	_current_dialogue_text = clean_text
	_should_show_hint = with_hint and show_continue_hint

	dialogue_label.text = _current_dialogue_text
	dialogue_label.visible_ratio = 0.0
	
	var was_invisible: bool = not visible
	visible = true
	is_typing = true

	if dialogue_panel != null:
		_setup_pivot_offset(dialogue_panel)
		if _default_panel_y < 0:
			_default_panel_y = dialogue_panel.position.y
		
		if was_invisible:
			# Start appearance animation
			dialogue_panel.modulate.a = 0.0
			dialogue_panel.scale = show_initial_scale
			dialogue_panel.position.y = _default_panel_y + show_slide_offset
			
			_transition_tween = create_tween().set_parallel(true)
			_transition_tween.tween_property(dialogue_panel, "modulate:a", 1.0, show_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_transition_tween.tween_property(dialogue_panel, "scale", Vector2.ONE, show_scale_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_transition_tween.tween_property(dialogue_panel, "position:y", _default_panel_y, show_slide_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			# Reset position immediately to prevent typing jump
			dialogue_panel.position.y = _default_panel_y
			dialogue_panel.scale = Vector2.ONE
			dialogue_panel.modulate.a = 1.0

	var duration = _current_dialogue_text.length() / characters_per_second
	_active_tween = create_tween()
	_active_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	_active_tween.finished.connect(_on_typing_finished)


func _on_typing_finished() -> void:
	is_typing = false
	if dialogue_label != null:
		dialogue_label.visible_ratio = 1.0
	if _should_show_hint:
		_show_hint()
	_start_idle_animation()


func skip_typing() -> void:
	_kill_tween()
	_on_typing_finished()


func clear() -> void:
	_kill_tween()
	_kill_idle_tween()
	_kill_transition_tween()
	_hide_hint()
	
	if dialogue_label != null:
		dialogue_label.text = ""
	is_typing = false
	
	if dialogue_panel != null and visible:
		_setup_pivot_offset(dialogue_panel)
		_transition_tween = create_tween().set_parallel(true)
		_transition_tween.tween_property(dialogue_panel, "modulate:a", 0.0, hide_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_transition_tween.tween_property(dialogue_panel, "scale", hide_final_scale, hide_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_transition_tween.tween_property(dialogue_panel, "position:y", _default_panel_y + hide_slide_offset, hide_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_transition_tween.chain().tween_callback(func(): visible = false)
	else:
		visible = false


func _kill_tween() -> void:
	if _active_tween:
		_active_tween.kill()
		_active_tween = null


func _kill_transition_tween() -> void:
	if _transition_tween:
		_transition_tween.kill()
		_transition_tween = null


func _kill_idle_tween() -> void:
	if _idle_tween:
		_idle_tween.kill()
		_idle_tween = null


func _resolve_label() -> Label:
	if dialogue_label_path != NodePath():
		var node: Node = get_node_or_null(dialogue_label_path)
		if node is Label:
			return node as Label

	var found: Node = find_child("DialogueText", true, false)
	if found is Label:
		return found as Label

	return null


# --- Modular Polishing Helpers ---

func _setup_continue_label() -> void:
	if dialogue_panel == null:
		return
	
	continue_label = Label.new()
	continue_label.text = continue_hint
	continue_label.name = "ContinueHintLabel"
	
	if dialogue_label != null:
		var font = dialogue_label.get_theme_font("font")
		if font != null:
			continue_label.add_theme_font_override("font", font)
		var font_size = dialogue_label.get_theme_font_size("font_size")
		if font_size > 0:
			continue_label.add_theme_font_size_override("font_size", font_size - hint_font_size_reduction)
	
	continue_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	continue_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	dialogue_panel.add_child(continue_label)
	
	# Use standard Godot 4 set_anchors_preset to correctly anchor to bottom-right
	continue_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_label.offset_left = hint_offset_left
	continue_label.offset_top = hint_offset_top
	continue_label.offset_right = hint_offset_right
	continue_label.offset_bottom = hint_offset_bottom
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	continue_label.visible = false


func _setup_pivot_offset(control: Control) -> void:
	if control != null:
		control.pivot_offset = control.size / 2.0


func _start_idle_animation() -> void:
	if not idle_bobbing_enabled or dialogue_panel == null or _default_panel_y < 0:
		return
	
	_setup_pivot_offset(dialogue_panel)
	
	_idle_tween = create_tween().set_loops()
	var up_y = _default_panel_y + idle_bob_up_offset
	var down_y = _default_panel_y + idle_bob_down_offset
	
	_idle_tween.tween_property(dialogue_panel, "position:y", up_y, idle_bob_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(dialogue_panel, "position:y", down_y, idle_bob_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _show_hint() -> void:
	if continue_label == null:
		return
	
	continue_label.modulate.a = 0.0
	continue_label.visible = true
	
	if _hint_tween:
		_hint_tween.kill()
		
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(continue_label, "modulate:a", hint_pulse_max_alpha, hint_pulse_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hint_tween.tween_property(continue_label, "modulate:a", hint_pulse_min_alpha, hint_pulse_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _hide_hint() -> void:
	if _hint_tween:
		_hint_tween.kill()
		_hint_tween = null
	if continue_label != null:
		continue_label.visible = false
