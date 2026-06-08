extends Control
class_name TitleScreen

signal start_requested

@export var start_button_path: NodePath

@export_group("Hover Caret Settings")
@export var caret_hidden_x: float = 12.0
@export var caret_hover_x: float = 24.0
@export var caret_transition_duration: float = 0.2
@export var caret_fade_duration: float = 0.15

@export_group("Button Polish Settings")
@export var button_hover_scale: Vector2 = Vector2(1.03, 1.03)
@export var button_transition_duration: float = 0.12

@onready var start_button: Button = _resolve_button(start_button_path, "StartButton")
@onready var button_caret: Label = find_child("ButtonCaret", true, false) as Label
@onready var button_panel: PanelContainer = find_child("ButtonPanel", true, false) as PanelContainer

var _button_tween: Tween
var _input_locked: bool = false

func _ready() -> void:
	if start_button != null:
		start_button.pressed.connect(func():
			if _input_locked:
				return
			start_button.disabled = true
			if _button_tween:
				_button_tween.kill()
			if button_panel != null:
				button_panel.pivot_offset = button_panel.size / 2.0
				var fade_tween = create_tween().set_parallel(true)
				fade_tween.tween_property(button_panel, "scale", Vector2.ONE * 0.95, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				fade_tween.tween_property(button_panel, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				fade_tween.chain().tween_callback(func():
					start_requested.emit()
				)
		)
		_setup_button_events(start_button)
		_setup_caret()
	hide_screen()

func show_screen() -> void:
	visible = true
	_input_locked = true
	get_tree().create_timer(0.5).timeout.connect(func():
		_input_locked = false
	)
	if start_button != null:
		start_button.disabled = false
		start_button.grab_focus()
	if button_panel != null:
		button_panel.scale = Vector2.ONE
		button_panel.modulate.a = 1.0
	if button_caret != null:
		button_caret.position.x = caret_hidden_x
		button_caret.modulate.a = 0.0

func hide_screen() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _input_locked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
			if start_button != null and not start_button.disabled:
				start_button.pressed.emit()

func _setup_button_events(button: Button) -> void:
	button.mouse_entered.connect(func(): _on_button_hover(button))
	button.mouse_exited.connect(func(): _on_button_unhover(button))
	button.focus_entered.connect(func(): _on_button_hover(button))
	button.focus_exited.connect(func(): _on_button_unhover(button))

func _setup_caret() -> void:
	if button_caret != null:
		button_caret.anchor_left = 0.0
		button_caret.anchor_right = 0.0
		button_caret.anchor_top = 0.0
		button_caret.anchor_bottom = 1.0
		button_caret.grow_vertical = Control.GROW_DIRECTION_BOTH
		button_caret.position.x = caret_hidden_x
		button_caret.modulate.a = 0.0
		button_caret.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _on_button_hover(button: Button) -> void:
	if button == null or button.disabled or not button.visible:
		return
		
	if button_panel != null:
		button_panel.pivot_offset = button_panel.size / 2.0
		
		if _button_tween:
			_button_tween.kill()
			
		_button_tween = create_tween().set_parallel(true)
		_button_tween.tween_property(button_panel, "scale", button_hover_scale, button_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		if button_caret != null:
			_button_tween.tween_property(button_caret, "position:x", caret_hover_x, caret_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_button_tween.tween_property(button_caret, "modulate:a", 1.0, caret_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_button_unhover(button: Button) -> void:
	if button == null or button.disabled or not button.visible:
		return
		
	if button_panel != null:
		button_panel.pivot_offset = button_panel.size / 2.0
		
		if _button_tween:
			_button_tween.kill()
			
		_button_tween = create_tween().set_parallel(true)
		_button_tween.tween_property(button_panel, "scale", Vector2.ONE, button_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		if button_caret != null:
			_button_tween.tween_property(button_caret, "position:x", caret_hidden_x, caret_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_button_tween.tween_property(button_caret, "modulate:a", 0.0, caret_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _resolve_button(path: NodePath, fallback_name: String) -> Button:
	if path != NodePath(""):
		return get_node_or_null(path) as Button
	var named := find_child(fallback_name, true, false) as Button
	if named != null:
		return named
	return _find_first_button(self)

func _find_first_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button:
			return child
		var found := _find_first_button(child)
		if found != null:
			return found
	return null
