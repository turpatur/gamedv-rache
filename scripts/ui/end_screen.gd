extends Control
class_name EndScreen

signal restart_requested
signal quit_requested

@export var title_label_path: NodePath
@export var body_label_path: NodePath
@export var restart_button_path: NodePath
@export var quit_button_path: NodePath

@export_group("Hover Caret Settings")
@export var caret_character: String = ">"
@export var caret_hidden_x: float = 12.0
@export var caret_hover_x: float = 24.0
@export var caret_transition_duration: float = 0.2
@export var caret_fade_duration: float = 0.15

@export_group("Button Polish Settings")
@export var button_hover_scale: Vector2 = Vector2(1.03, 1.03)
@export var button_transition_duration: float = 0.12
@export var button_pressed_scale_multiplier: float = 1.03
@export var button_other_unselected_scale: float = 0.95

@onready var title_label: Label = _resolve_label(title_label_path, "EndTitle")
@onready var body_label: Label = _resolve_label(body_label_path, "EndBody")
@onready var restart_button: Button = _resolve_button(restart_button_path, "RestartButton")
@onready var quit_button: Button = _resolve_button(quit_button_path, "QuitButton")

var _button_tweens: Dictionary = {}
var _input_locked: bool = false

func _ready() -> void:
	if restart_button != null:
		restart_button.pressed.connect(_on_restart_pressed)
		_setup_button_events(restart_button)
		_setup_button_arrow(restart_button)
		if restart_button.text.begins_with("> "):
			restart_button.text = restart_button.text.replace("> ", "")
			
	if quit_button != null:
		quit_button.pressed.connect(_on_quit_pressed)
		_setup_button_events(quit_button)
		_setup_button_arrow(quit_button)
		
	hide_screen()

func show_ending(title: String, body: String, button_text: String) -> void:
	_kill_button_tweens()
	visible = true
	_input_locked = true
	get_tree().create_timer(0.5).timeout.connect(func():
		_input_locked = false
	)
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = body
	
	var buttons_list = [restart_button, quit_button]
	for btn in buttons_list:
		if btn != null:
			btn.disabled = false
			btn.scale = Vector2.ONE
			btn.modulate.a = 1.0
			var arrow = btn.get_node_or_null("ArrowIndicator") as Label
			if arrow:
				arrow.position.x = caret_hidden_x
				arrow.modulate.a = 0.0

	if restart_button != null:
		restart_button.text = button_text
		restart_button.grab_focus()

func hide_screen() -> void:
	_kill_button_tweens()
	visible = false
	var buttons_list = [restart_button, quit_button]
	for btn in buttons_list:
		if btn != null:
			btn.scale = Vector2.ONE
			btn.modulate.a = 1.0
			btn.disabled = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _input_locked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_R, KEY_ENTER, KEY_SPACE]:
			if restart_button != null and not restart_button.disabled:
				restart_button.pressed.emit()
		elif event.keycode == KEY_ESCAPE:
			if quit_button != null and not quit_button.disabled:
				quit_button.pressed.emit()

func _on_restart_pressed() -> void:
	if _input_locked:
		return
	_play_press_transition(restart_button, func(): restart_requested.emit())

func _on_quit_pressed() -> void:
	if _input_locked:
		return
	_play_press_transition(quit_button, func(): quit_requested.emit())

func _play_press_transition(pressed_btn: Button, callback: Callable) -> void:
	var buttons_list = [restart_button, quit_button]
	for btn in buttons_list:
		if btn != null:
			btn.disabled = true
			
	_kill_button_tweens()
	
	var fade_tween = create_tween().set_parallel(true)
	for btn in buttons_list:
		if btn != null and btn.visible:
			btn.pivot_offset = btn.size / 2.0
			if btn == pressed_btn:
				fade_tween.tween_property(btn, "scale", Vector2.ONE * button_pressed_scale_multiplier, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				fade_tween.tween_property(btn, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			else:
				fade_tween.tween_property(btn, "scale", Vector2.ONE * button_other_unselected_scale, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				fade_tween.tween_property(btn, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				
	fade_tween.chain().tween_callback(func():
		hide_screen()
		callback.call()
	)

func _setup_button_events(button: Button) -> void:
	button.mouse_entered.connect(func(): _on_button_hover(button))
	button.mouse_exited.connect(func(): _on_button_unhover(button))
	button.focus_entered.connect(func(): _on_button_hover(button))
	button.focus_exited.connect(func(): _on_button_unhover(button))

func _on_button_hover(button: Button) -> void:
	if button == null or button.disabled or not button.visible:
		return
		
	button.pivot_offset = button.size / 2.0
	
	if _button_tweens.has(button):
		var old_tween = _button_tweens[button] as Tween
		if old_tween:
			old_tween.kill()
			
	var tween = create_tween().set_parallel(true)
	_button_tweens[button] = tween
	tween.tween_property(button, "scale", button_hover_scale, button_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var arrow = button.get_node_or_null("ArrowIndicator") as Label
	if arrow:
		tween.tween_property(arrow, "position:x", caret_hover_x, caret_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(arrow, "modulate:a", 1.0, caret_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_button_unhover(button: Button) -> void:
	if button == null or button.disabled or not button.visible:
		return
		
	button.pivot_offset = button.size / 2.0
	
	if _button_tweens.has(button):
		var old_tween = _button_tweens[button] as Tween
		if old_tween:
			old_tween.kill()
			
	var tween = create_tween().set_parallel(true)
	_button_tweens[button] = tween
	tween.tween_property(button, "scale", Vector2.ONE, button_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
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

func _kill_button_tweens() -> void:
	for button in _button_tweens:
		var tween = _button_tweens[button] as Tween
		if tween:
			tween.kill()
	_button_tweens.clear()

func _resolve_label(path: NodePath, fallback_name: String) -> Label:
	if path != NodePath(""):
		return get_node_or_null(path) as Label
	return find_child(fallback_name, true, false) as Label

func _resolve_button(path: NodePath, fallback_name: String) -> Button:
	if path != NodePath(""):
		return get_node_or_null(path) as Button
	var named := find_child(fallback_name, true, false) as Button
	if named != null:
		return named
	return null
