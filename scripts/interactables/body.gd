extends "res://scripts/interactables/interactable.gd"

func _ready() -> void:
	object_id = "body"
	display_name = "Body"
	interaction_radius = 85.0
	super._ready()
