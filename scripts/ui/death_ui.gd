extends Control
class_name DeathUI

@export_group("Node Paths")
@export var death_label_path: NodePath
@export var red_overlay_path: NodePath
@export var black_overlay_path: NodePath
@export var eyelid_top_path: NodePath
@export var eyelid_bottom_path: NodePath

@export_group("Timing")
@export var red_fade_seconds: float = 0.9
@export var death_hold_seconds: float = 2.8
@export var black_fade_seconds: float = 0.8
@export var reawake_hold_seconds: float = 0.12
@export var black_release_seconds: float = 0.12
@export var eye_open_seconds: float = 0.88

@export_group("Overlay Targets")
@export_range(0.0, 1.0, 0.01) var red_target_alpha: float = 1.0

@onready var death_label: Label = _resolve_label(death_label_path, "DeathText")
@onready var red_overlay: ColorRect = _resolve_control(red_overlay_path, "RedOverlay") as ColorRect
@onready var black_overlay: ColorRect = _resolve_control(black_overlay_path, "BlackOverlay") as ColorRect
@onready var eyelid_top: ColorRect = _resolve_control(eyelid_top_path, "EyelidTop") as ColorRect
@onready var eyelid_bottom: ColorRect = _resolve_control(eyelid_bottom_path, "EyelidBottom") as ColorRect

@export_group("Audio")
@export var death_sound: AudioStream = preload("res://assets/audio/death.mp3")
@export_file("*.mp3") var gameplay_bgm_path: String = "res://assets/audio/gameplay.mp3"
@export var audio_bus: String = "Master"

@export_group("Colors")
@export var red_start_color_default: Color = Color(0.42, 0.0, 0.0, 0.48)
@export var red_target_color_default: Color = Color(0.42, 0.0, 0.0, 1.0)
@export var black_solid_color_default: Color = Color.BLACK

var _active_tween: Tween
var _red_start_color: Color
var _red_target_color: Color
var _black_solid_color: Color


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if red_overlay != null:
		_red_start_color = red_start_color_default
		_red_target_color = Color(
			red_target_color_default.r,
			red_target_color_default.g,
			red_target_color_default.b,
			red_target_alpha
		)
		red_overlay.visible = false

	if black_overlay != null:
		_black_solid_color = black_solid_color_default
		black_overlay.visible = false

	if eyelid_top != null:
		eyelid_top.visible = false

	if eyelid_bottom != null:
		eyelid_bottom.visible = false

	if death_label != null:
		death_label.visible = false


func show_death(reason: String, fast_mode: bool = false) -> void:
	_kill_tween()

	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	if red_overlay != null:
		red_overlay.visible = true
		red_overlay.color = _red_start_color

	if black_overlay != null:
		black_overlay.visible = true
		black_overlay.color = _with_alpha(_black_solid_color, 0.0)

	_setup_closed_eyelids(false)

	if death_label != null:
		death_label.visible = true
		death_label.modulate.a = 1.0
		death_label.text = reason

	# Play death sound and adjust hold time
	SoundManager.stop_all_audio()
	var sfx_player: AudioStreamPlayer = null
	if death_sound:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.stream = death_sound
		sfx_player.bus = audio_bus
		add_child(sfx_player)
		sfx_player.play()
		death_hold_seconds = death_sound.get_length()
		sfx_player.finished.connect(func(): sfx_player.queue_free())

	if fast_mode:
		death_hold_seconds = 1.5

	_active_tween = create_tween()

	if red_overlay != null:
		_active_tween.tween_property(
			red_overlay,
			"color",
			_red_target_color,
			red_fade_seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Audio fade out for fast_mode
	if fast_mode and sfx_player != null:
		_active_tween.parallel().tween_property(sfx_player, "volume_db", -40.0, death_hold_seconds)

	_active_tween.tween_interval(death_hold_seconds)

	if black_overlay != null:
		_active_tween.tween_property(
			black_overlay,
			"color",
			_black_solid_color,
			black_fade_seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if death_label != null:
		_active_tween.parallel().tween_property(
			death_label,
			"modulate:a",
			0.0,
			black_fade_seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func play_return_transition() -> void:
	_kill_tween()

	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	if red_overlay != null:
		red_overlay.visible = false

	if death_label != null:
		death_label.visible = false

	if black_overlay != null:
		black_overlay.visible = true
		black_overlay.color = _black_solid_color

	_setup_closed_eyelids(true)

	_active_tween = create_tween()
	_active_tween.tween_interval(reawake_hold_seconds)

	if black_overlay != null:
		_active_tween.tween_property(
			black_overlay,
			"color:a",
			0.0,
			black_release_seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if eyelid_top != null:
		_active_tween.parallel().tween_property(
			eyelid_top,
			"size:y",
			0.0,
			eye_open_seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if eyelid_bottom != null:
		_active_tween.parallel().tween_property(
			eyelid_bottom,
			"size:y",
			0.0,
			eye_open_seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		_active_tween.parallel().tween_property(
			eyelid_bottom,
			"position:y",
			size.y,
			eye_open_seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await _active_tween.finished
	
	# Resume gameplay music when eye is open
	SoundManager.play_bgm(gameplay_bgm_path)


func hide_death() -> void:
	_kill_tween()

	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if death_label != null:
		death_label.visible = false
		death_label.text = ""
		death_label.modulate.a = 1.0

	if red_overlay != null:
		red_overlay.visible = false
		red_overlay.color = _red_start_color

	if black_overlay != null:
		black_overlay.visible = false
		black_overlay.color = _black_solid_color

	_setup_closed_eyelids(false)


func _setup_closed_eyelids(should_show: bool) -> void:
	var half_height: float = size.y * 0.5

	if eyelid_top != null:
		eyelid_top.visible = should_show
		eyelid_top.position = Vector2.ZERO
		eyelid_top.size = Vector2(size.x, half_height)

	if eyelid_bottom != null:
		eyelid_bottom.visible = should_show
		eyelid_bottom.position = Vector2(0.0, half_height)
		eyelid_bottom.size = Vector2(size.x, half_height)


func _kill_tween() -> void:
	if _active_tween != null:
		_active_tween.kill()
		_active_tween = null


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


func _resolve_label(path: NodePath, fallback_name: String) -> Label:
	if path != NodePath():
		var node: Node = get_node_or_null(path)
		if node is Label:
			return node as Label

	var found: Node = find_child(fallback_name, true, false)
	if found is Label:
		return found as Label

	return null


func _resolve_control(path: NodePath, fallback_name: String) -> Control:
	if path != NodePath():
		var node: Node = get_node_or_null(path)
		if node is Control:
			return node as Control

	var found: Node = find_child(fallback_name, true, false)
	if found is Control:
		return found as Control

	return null
