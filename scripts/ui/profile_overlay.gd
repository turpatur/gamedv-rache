extends Control
class_name ProfileOverlay

@export var dim_overlay_path: NodePath
@export var profile_sprite_path: NodePath

@onready var dim_overlay: ColorRect = _resolve(dim_overlay_path, "DimOverlay") as ColorRect
@onready var profile_sprite: TextureRect = _resolve(profile_sprite_path, "ProfileSprite") as TextureRect

const PROFILE_PATHS: Dictionary = {
	"r": "res://assets/sprites/ui/profile_r.png",
	"a": "res://assets/sprites/ui/profile_a.png",
	"c": "res://assets/sprites/ui/profile_c.png",
	"h": "res://assets/sprites/ui/profile_h.png",
	"e": "res://assets/sprites/ui/profile_e.png",
}

func _ready() -> void:
	hide_profile()

func show_profile(letter: String) -> void:
	var key: String = letter.to_lower()
	var path: String = String(PROFILE_PATHS.get(key, ""))
	if profile_sprite != null:
		if ResourceLoader.exists(path):
			profile_sprite.texture = load(path) as Texture2D
		else:
			profile_sprite.texture = null
	visible = true
	if dim_overlay != null:
		dim_overlay.visible = true
	if profile_sprite != null:
		profile_sprite.visible = true

func hide_profile() -> void:
	if profile_sprite != null:
		profile_sprite.visible = false
	if dim_overlay != null:
		dim_overlay.visible = false
	visible = false

func _resolve(path: NodePath, fallback_name: String) -> Node:
	if path != NodePath(""):
		return get_node_or_null(path)
	return find_child(fallback_name, true, false)
