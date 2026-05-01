extends Control
class_name HUDView

@export var prompt_label_path: NodePath
@export var clue_label_path: NodePath
@export var lead_label_path: NodePath

@export_group("Labels")
@export var clue_format: String = "CLEAR %d  HAZY %d"

@onready var prompt_label: Label = _resolve_label(prompt_label_path, "PromptLabel")
@onready var clue_label: Label = _resolve_label(clue_label_path, "ClueLabel")
@onready var lead_label: Label = _resolve_label(lead_label_path, "LeadLabel")

func update_hud(prompt: String, _loop_count: int, clear_count: int, hazy_count: int, lead: String, _has_died: bool = false) -> void:
	var prompt_text := prompt.strip_edges()
	var lead_text := lead.strip_edges()
	if prompt_label != null:
		prompt_label.visible = prompt_text != ""
		prompt_label.text = prompt_text
	if clue_label != null:
		clue_label.text = clue_format % [clear_count, hazy_count]
	if lead_label != null:
		lead_label.visible = lead_text != ""
		lead_label.text = lead_text

func _resolve_label(path: NodePath, fallback_name: String) -> Label:
	if path != NodePath(""):
		return get_node_or_null(path) as Label
	return find_child(fallback_name, true, false) as Label
