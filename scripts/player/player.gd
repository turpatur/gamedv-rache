extends CharacterBody2D
class_name RachePlayer

signal interact_pressed

@export var speed: float = 220.0

var _bounds: Rect2 = Rect2()
var _has_bounds: bool = false
var movement_locked: bool = false
var facing_direction: Vector2 = Vector2.DOWN

@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
	_play_animation("idle_down")
	visual.play()

func configure(bounds: Rect2, p_speed: float) -> void:
	speed = p_speed
	_bounds = bounds
	_has_bounds = true

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if not movement_locked:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction != Vector2.ZERO:
		facing_direction = _dominant_axis(direction)

	velocity = direction * speed
	move_and_slide()
	
	if _has_bounds:
		global_position.x = clamp(global_position.x, _bounds.position.x, _bounds.end.x)
		global_position.y = clamp(global_position.y, _bounds.position.y, _bounds.end.y)
		
	_update_animation(direction)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not movement_locked:
		interact_pressed.emit()

func set_movement_locked(value: bool) -> void:
	movement_locked = value
	if movement_locked:
		velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO)

func set_player_position(value: Vector2) -> void:
	global_position = value
	velocity = Vector2.ZERO
	facing_direction = Vector2.DOWN
	_update_animation(Vector2.ZERO)

func _update_animation(direction: Vector2) -> void:
	var prefix := "walk" if direction != Vector2.ZERO else "idle"
	_play_animation("%s_%s" % [prefix, _direction_name(facing_direction)])

func _play_animation(animation_name: String) -> void:
	if visual.sprite_frames == null or not visual.sprite_frames.has_animation(animation_name):
		return

	visual.flip_h = animation_name == "idle_left"
	if visual.animation != animation_name:
		visual.play(animation_name)
	elif not visual.is_playing():
		visual.play()

func _dominant_axis(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP

func _direction_name(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "up"
	if direction == Vector2.LEFT:
		return "left"
	if direction == Vector2.RIGHT:
		return "right"
	return "down"
