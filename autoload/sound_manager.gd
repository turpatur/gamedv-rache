extends Node

## SoundManager Autoload
## Automatically attaches a click sound to all BaseButton nodes in the scene tree.

@export var click_sound: AudioStream = preload("res://assets/audio/button-click.mp3")
@export var default_sfx_bus: String = "Master"
@export var default_bgm_bus: String = "Master"

var audio_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var current_bgm_path: String = ""
var _cooldowns: Dictionary = {}

func _ready():
	# Setup AudioStreamPlayer for SFX
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = click_sound
	audio_player.bus = default_sfx_bus
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(audio_player)
	
	# Setup AudioStreamPlayer for BGM
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = default_bgm_bus
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player)
	
	# Connect to existing buttons in the tree
	_connect_buttons_recursive(get_tree().root)
	
	# Listen for new buttons being added to the tree
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	if node is BaseButton:
		_connect_button(node)

func _connect_buttons_recursive(root: Node):
	if root is BaseButton:
		_connect_button(root)
	for child in root.get_children():
		_connect_buttons_recursive(child)

func _connect_button(button: BaseButton):
	# Use CONNECT_REFERENCE_COUNTED to avoid duplicate connections if already connected
	# Or just check manually.
	if not button.pressed.is_connected(_play_click_sound):
		button.pressed.connect(_play_click_sound)

func _play_click_sound():
	if audio_player:
		audio_player.play()

func play_bgm(path: String, stop_others: bool = true):
	if current_bgm_path == path and bgm_player.playing:
		return
	
	if stop_others:
		stop_bgm()
		
	var stream = load(path)
	if stream:
		bgm_player.stream = stream
		bgm_player.play()
		current_bgm_path = path

func stop_bgm():
	if bgm_player:
		bgm_player.stop()
		current_bgm_path = ""

func stop_all_audio():
	stop_bgm()
	if audio_player:
		audio_player.stop()

func play_sfx(path: String, cooldown: float = 0.1):
	var now = Time.get_ticks_msec() / 1000.0
	if _cooldowns.has(path) and now < _cooldowns[path] + cooldown:
		return
	
	_cooldowns[path] = now
	
	var sfx = load(path)
	if sfx:
		var p = AudioStreamPlayer.new()
		p.stream = sfx
		p.bus = default_sfx_bus
		add_child(p)
		p.play()
		p.finished.connect(func(): p.queue_free())
