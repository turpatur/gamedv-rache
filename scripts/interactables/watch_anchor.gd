extends "res://scripts/interactables/interactable.gd"

func _ready() -> void:
	object_id = "watch"
	display_name = "Pocket Watch"
	interaction_radius = 72.0
	super._ready()
