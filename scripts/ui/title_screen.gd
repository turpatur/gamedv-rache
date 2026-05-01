extends Control
class_name TitleScreen

signal start_requested

@export var start_button_path: NodePath

@onready var start_button: Button = _resolve_button(start_button_path, "StartButton")

func _ready() -> void:
	if start_button != null:
		start_button.pressed.connect(func(): start_requested.emit())
	hide_screen()

func show_screen() -> void:
	visible = true
	if start_button != null:
		start_button.grab_focus()

func hide_screen() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
			start_requested.emit()

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
