extends Control
class_name DialogueUI

@export var dialogue_label_path: NodePath
@export var continue_hint: String = "[E] Continue"
@export var show_continue_hint: bool = true

@onready var dialogue_label: Label = _resolve_label()

@export var characters_per_second: float = 75.0
var is_typing: bool = false
var _active_tween: Tween
var _current_dialogue_text: String = ""
var _should_show_hint: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if dialogue_label == null:
		push_error("DialogueUI needs Dialogue Label Path assigned to DialoguePanel/MarginContainer/DialogueText.")


func show_line(text: String, with_hint: bool = true) -> void:
	if dialogue_label == null:
		return

	_kill_tween()

	var clean_text: String = text.strip_edges()
	if clean_text == "":
		clear()
		return

	_current_dialogue_text = clean_text
	_should_show_hint = with_hint and show_continue_hint

	dialogue_label.text = _current_dialogue_text
	dialogue_label.visible_ratio = 0.0
	visible = true
	is_typing = true

	var duration = _current_dialogue_text.length() / characters_per_second
	_active_tween = create_tween()
	_active_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	_active_tween.finished.connect(_on_typing_finished)


func _on_typing_finished() -> void:
	is_typing = false
	if _should_show_hint:
		dialogue_label.text = _current_dialogue_text + "\n\n" + continue_hint
		dialogue_label.visible_ratio = 1.0


func skip_typing() -> void:
	_kill_tween()
	_on_typing_finished()


func clear() -> void:
	_kill_tween()
	if dialogue_label != null:
		dialogue_label.text = ""
	visible = false
	is_typing = false


func _kill_tween() -> void:
	if _active_tween:
		_active_tween.kill()
		_active_tween = null


func _resolve_label() -> Label:
	if dialogue_label_path != NodePath():
		var node: Node = get_node_or_null(dialogue_label_path)
		if node is Label:
			return node as Label

	var found: Node = find_child("DialogueText", true, false)
	if found is Label:
		return found as Label

	return null
