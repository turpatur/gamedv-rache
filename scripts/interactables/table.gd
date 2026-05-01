extends "res://scripts/interactables/interactable.gd"

func _ready() -> void:
	object_id = "table"
	display_name = "Table"
	interaction_radius = 95.0
	super._ready()
