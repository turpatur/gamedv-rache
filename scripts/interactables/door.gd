extends "res://scripts/interactables/interactable.gd"

func _ready() -> void:
	object_id = "door"
	display_name = "Door"
	interaction_radius = 86.0
	super._ready()
