extends Control
class_name VerdictUI

signal verdict_selected(key: String)

const VERDICT_KEYS: Array[String] = ["R", "A", "C", "H", "self", "back"]

@export var title_label_path: NodePath
@export var button_paths: Array[NodePath] = []

@onready var title_label: Label = _resolve_label(title_label_path, "VerdictTitle")

var buttons: Array[Button] = []

func _ready() -> void:
	_collect_buttons()
	hide_verdict()

func show_verdict(title: String, labels: Array[String]) -> void:
	visible = true
	if title_label != null:
		title_label.text = title
	for i in range(buttons.size()):
		if i < labels.size():
			buttons[i].text = labels[i]
			buttons[i].visible = true
			buttons[i].disabled = false
		else:
			buttons[i].visible = false

func hide_verdict() -> void:
	visible = false

func _collect_buttons() -> void:
	buttons.clear()
	if not button_paths.is_empty():
		for path in button_paths:
			var button := get_node_or_null(path) as Button
			if button != null:
				buttons.append(button)
	else:
		_find_buttons_recursive(self)

	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_button_pressed.bind(i))

func _find_buttons_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			buttons.append(child)
		_find_buttons_recursive(child)

func _on_button_pressed(index: int) -> void:
	if index >= 0 and index < VERDICT_KEYS.size():
		verdict_selected.emit(VERDICT_KEYS[index])

func _resolve_label(path: NodePath, fallback_name: String) -> Label:
	if path != NodePath(""):
		return get_node_or_null(path) as Label
	return find_child(fallback_name, true, false) as Label
