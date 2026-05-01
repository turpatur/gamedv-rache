extends Node2D
class_name RacheInteractable

signal focused_changed(is_focused: bool)
signal interaction_requested(object_id: String)

@export var object_id: String = ""
@export var display_name: String = ""
@export var interaction_radius: float = 72.0
@export var highlight_target_path: NodePath

var is_focused: bool = false

func _ready() -> void:
	add_to_group("interactable")

func get_interaction_position() -> Vector2:
	return global_position

func set_highlighted(value: bool) -> void:
	if is_focused == value:
		return
	is_focused = value
	focused_changed.emit(value)
	var target_node := get_node_or_null(highlight_target_path) if highlight_target_path != NodePath("") else self
	var canvas_item := target_node as CanvasItem
	if canvas_item != null:
		canvas_item.modulate = Color(1.18, 1.18, 1.18, 1.0) if value else Color(1, 1, 1, 1)

func request_interaction() -> void:
	interaction_requested.emit(object_id)
