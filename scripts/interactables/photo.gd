extends "res://scripts/interactables/interactable.gd"

func _ready() -> void:
	object_id = "photo"
	display_name = "Bookshelf"
	interaction_radius = 100.0
	super._ready()
