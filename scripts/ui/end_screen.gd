extends Control
class_name EndScreen

signal restart_requested
signal quit_requested

@export var title_label_path: NodePath
@export var body_label_path: NodePath
@export var restart_button_path: NodePath
@export var quit_button_path: NodePath

@onready var title_label: Label = _resolve_label(title_label_path, "EndTitle")
@onready var body_label: Label = _resolve_label(body_label_path, "EndBody")
@onready var restart_button: Button = _resolve_button(restart_button_path, "RestartButton")
@onready var quit_button: Button = _resolve_button(quit_button_path, "QuitButton")

func _ready() -> void:
	if restart_button != null:
		restart_button.pressed.connect(func(): restart_requested.emit())
	if quit_button != null:
		quit_button.pressed.connect(func(): quit_requested.emit())
	hide_screen()

func show_ending(title: String, body: String, button_text: String) -> void:
	visible = true
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = body
	if restart_button != null:
		restart_button.text = button_text
		restart_button.grab_focus()

func hide_screen() -> void:
	visible = false

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
