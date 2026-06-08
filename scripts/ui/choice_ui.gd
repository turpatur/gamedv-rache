extends Control
class_name ChoiceUI

signal option_selected(index: int)

@export var options_container_path: NodePath

@export_group("Hover Caret Settings")
@export var caret_character: String = ">"
@export var caret_hidden_x: float = 12.0
@export var caret_hover_x: float = 28.0
@export var caret_transition_duration: float = 0.2
@export var caret_fade_duration: float = 0.15

@export_group("Button Polish Settings")
@export var button_hover_scale: Vector2 = Vector2(1.02, 1.02)
@export var button_transition_duration: float = 0.12
@export var button_cascade_delay: float = 0.06
@export var button_cascade_duration_fade: float = 0.22
@export var button_cascade_duration_scale: float = 0.28
@export var button_pressed_scale_multiplier: float = 1.03
@export var button_other_unselected_scale: float = 0.95

var options_container: VBoxContainer
var buttons: Array[Button] = []

# Polishing variables
var _button_tweens: Dictionary = {}
var _cascade_tweens: Array[Tween] = []


func _ready() -> void:
	visible = false

	if options_container_path != NodePath():
		options_container = get_node_or_null(options_container_path) as VBoxContainer

	if options_container == null:
		options_container = find_child("OptionsContainer", true, false) as VBoxContainer

	if options_container == null:
		push_error("ChoiceUI needs a VBoxContainer named OptionsContainer.")
		return

	buttons.clear()

	for child in options_container.get_children():
		if child is Button:
			var button := child as Button
			var index := buttons.size()
			button.visible = false
			button.pressed.connect(_on_button_pressed.bind(index))
			_setup_button_events(button)
			_setup_button_arrow(button)
			buttons.append(button)


func show_choices(options: Array) -> void:
	print("[ChoiceUI] show_choices called. Options count: ", options.size())
	_kill_cascade_tweens()
	_kill_button_tweens()
	
	visible = true
	_ensure_button_count(options.size())

	for i in range(buttons.size()):
		var button := buttons[i]
		if i < options.size():
			var option: Dictionary = options[i] as Dictionary
			var label_text = String(option.get("label", ""))
			button.text = label_text
			button.set_meta("original_text", label_text)
			button.visible = true
			button.disabled = false
			
			var arrow = button.get_node_or_null("ArrowIndicator") as Label
			if arrow:
				arrow.position.x = caret_hidden_x
				arrow.modulate.a = 0.0
			
			_setup_pivot_offset(button)
			button.scale = Vector2(0.9, 0.9)
			button.modulate.a = 0.0
			
			var delay = i * button_cascade_delay
			var tween = create_tween().set_parallel(true)
			_cascade_tweens.append(tween)
			tween.tween_property(button, "modulate:a", 1.0, button_cascade_duration_fade).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(button, "scale", Vector2.ONE, button_cascade_duration_scale).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			button.visible = false


func hide_choices() -> void:
	_kill_cascade_tweens()
	_kill_button_tweens()
	visible = false

	for button in buttons:
		button.visible = false
		button.scale = Vector2.ONE
		button.modulate.a = 1.0
		button.disabled = false


func _on_button_pressed(index: int) -> void:
	# Disable all buttons to prevent double-clicking during animation
	for btn in buttons:
		btn.disabled = true
		
	_kill_cascade_tweens()
	_kill_button_tweens()
	
	var pressed_button = buttons[index]
	_setup_pivot_offset(pressed_button)
	
	var fade_tween = create_tween().set_parallel(true)
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn.visible:
			_setup_pivot_offset(btn)
			if i == index:
				fade_tween.tween_property(btn, "scale", Vector2.ONE * button_pressed_scale_multiplier, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				fade_tween.tween_property(btn, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			else:
				fade_tween.tween_property(btn, "scale", Vector2.ONE * button_other_unselected_scale, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				fade_tween.tween_property(btn, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				
	fade_tween.chain().tween_callback(func():
		hide_choices()
		option_selected.emit(index)
	)


func _ensure_button_count(count: int) -> void:
	if options_container == null:
		return
	while buttons.size() < count:
		var source := buttons[buttons.size() - 1] if not buttons.is_empty() else Button.new()
		var button := source.duplicate(0) as Button
		var index := buttons.size()
		button.visible = false
		button.pressed.connect(_on_button_pressed.bind(index))
		_setup_button_events(button)
		_setup_button_arrow(button)
		options_container.add_child(button)
		buttons.append(button)


# --- Modular Polishing Helpers ---

func _setup_button_events(button: Button) -> void:
	button.mouse_entered.connect(func(): _on_button_hover(button))
	button.mouse_exited.connect(func(): _on_button_unhover(button))
	button.focus_entered.connect(func(): _on_button_hover(button))
	button.focus_exited.connect(func(): _on_button_unhover(button))


func _setup_pivot_offset(control: Control) -> void:
	if control != null:
		control.pivot_offset = control.size / 2.0


func _on_button_hover(button: Button) -> void:
	if button == null or button.disabled or not button.visible:
		return
		
	_setup_pivot_offset(button)
	
	if _button_tweens.has(button):
		var old_tween = _button_tweens[button] as Tween
		if old_tween:
			old_tween.kill()
			
	var tween = create_tween().set_parallel(true)
	_button_tweens[button] = tween
	tween.tween_property(button, "scale", button_hover_scale, button_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate:a", 1.0, button_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var arrow = button.get_node_or_null("ArrowIndicator") as Label
	if arrow:
		tween.tween_property(arrow, "position:x", caret_hover_x, caret_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(arrow, "modulate:a", 1.0, caret_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_button_unhover(button: Button) -> void:
	if button == null or button.disabled or not button.visible:
		return
		
	_setup_pivot_offset(button)
	
	if _button_tweens.has(button):
		var old_tween = _button_tweens[button] as Tween
		if old_tween:
			old_tween.kill()
			
	var tween = create_tween().set_parallel(true)
	_button_tweens[button] = tween
	tween.tween_property(button, "scale", Vector2.ONE, button_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate:a", 1.0, button_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var arrow = button.get_node_or_null("ArrowIndicator") as Label
	if arrow:
		tween.tween_property(arrow, "position:x", caret_hidden_x, caret_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(arrow, "modulate:a", 0.0, caret_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _setup_button_arrow(button: Button) -> void:
	if button == null:
		return
	if button.has_node("ArrowIndicator"):
		return
		
	var arrow = Label.new()
	arrow.name = "ArrowIndicator"
	arrow.text = caret_character
	
	# Set anchors for vertical centering on the left side
	arrow.anchor_left = 0.0
	arrow.anchor_right = 0.0
	arrow.anchor_top = 0.0
	arrow.anchor_bottom = 1.0
	arrow.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Initial position and opacity
	arrow.position.x = caret_hidden_x
	arrow.modulate.a = 0.0
	
	# Copy font styling from button to ensure match
	var font = button.get_theme_font("font")
	if font:
		arrow.add_theme_font_override("font", font)
	var font_size = button.get_theme_font_size("font_size")
	if font_size > 0:
		arrow.add_theme_font_size_override("font_size", font_size)
		
	# Vertical alignment
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	button.add_child(arrow)


func _kill_cascade_tweens() -> void:
	for tween in _cascade_tweens:
		if tween:
			tween.kill()
	_cascade_tweens.clear()


func _kill_button_tweens() -> void:
	for button in _button_tweens:
		var tween = _button_tweens[button] as Tween
		if tween:
			tween.kill()
	_button_tweens.clear()
