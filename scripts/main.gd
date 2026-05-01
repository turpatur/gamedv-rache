extends Node2D

# ─────────────────────────────────────────
#  CONSTANTS
# ─────────────────────────────────────────
const ROOM_RECT    := Rect2(80, 70, 800, 470)
const PLAYER_SPEED := 230.0

# ─────────────────────────────────────────
#  ENUMS
# ─────────────────────────────────────────
enum GameState   { TITLE, PLAYING, VERDICT, ENDING }
enum LoopPhase   { EARLY, MID, LATE }
enum MemoryState { UNKNOWN, HAZY, CLEAR }

# ─────────────────────────────────────────
#  SOURCE OF TRUTH STATE
# ─────────────────────────────────────────
var game_state : int  = GameState.TITLE
var loop_count : int  = 1
var ng_plus    : bool = false
var has_died   : bool = false

# Score: R, A, C, H, SELF — clamped 0..10
var score : Dictionary = { "R": 0, "A": 0, "C": 0, "H": 0, "SELF": 0 }

# Route flags — single source of truth
var route : Dictionary = {
	"has_valid_death"    : false,
	"good_R_seen"        : false,
	"poison_death_spent" : false,
	"door_death_spent"   : false,
	"watch_death_spent"  : false,
	"poison_after_body"  : false,
	"door_after_rache"   : false,
	"watch_after_deaths" : false,
}

# Clue memory states
var clue_state : Dictionary = {
	"table" : MemoryState.UNKNOWN,
	"body"  : MemoryState.UNKNOWN,
	"door"  : MemoryState.UNKNOWN,
	"rache" : MemoryState.UNKNOWN,
	"photo" : MemoryState.UNKNOWN,
	"watch" : MemoryState.UNKNOWN,
}

# Dependency map
const CLUE_DEPS : Dictionary = {
	"table" : "",
	"body"  : "table",
	"door"  : "body",
	"rache" : "door",
	"photo" : "rache",
	"watch" : "",
}

# Seen dialog options per object
var seen_dialogs : Dictionary = {
	"table" : [],
	"body"  : [],
	"door"  : [],
	"rache" : [],
	"photo" : [],
	"watch" : [],
}

# ─────────────────────────────────────────
#  RUNTIME STATE (not saved)
# ─────────────────────────────────────────
var player_pos           : Vector2 = Vector2(460, 420)
var movement_locked      : bool    = false
var dying                : bool    = false
var load_flash           : float   = 0.0
var input_disorientation : float   = 0.0
var prompt_notice        : String  = ""
var prompt_notice_timer  : float   = 0.0
var nearest_id           : String  = ""
var was_near_door        : bool    = false
var pending_death        : bool    = false
var pending_death_reason : String  = ""
var pending_ending_id    : String  = ""
var verdict_active       : bool    = false
var verdict_choice       : String  = ""
var current_object       : String  = ""
var awaiting_choice      : bool    = false
var choice_options       : Array   = []
var dialogue_lines       : Array   = []
var dialogue_index       : int     = 0
var door_rach_index      : int     = 0
var door_approach_count  : int     = 0

# ─────────────────────────────────────────
#  DOOR RACH AMBIENT POOL
# ─────────────────────────────────────────
var door_rach_pool : Array = [
	[
		"Voices outside the door.",
		"Voice 1: 'It's done.'",
		"Flat voice: 'Clean enough?'",
		"Voice 1: 'It'll hold.'",
	],
	[
		"Footsteps outside. They stop for a long time.",
		"Low voice: 'Check the lock again.'",
		"Low voice: 'No witnesses.'",
	],
	[
		"A shaking voice: 'Was there another way?'",
		"Flat voice: 'The other ways took too long.'",
	],
	[
		"Flat voice: 'The timeline moved. Messy.'",
		"Flat voice: 'But the outcome is the same.'",
	],
]

# ─────────────────────────────────────────
#  UI NODES
# ─────────────────────────────────────────
var prompt_label       : Label
var help_label         : Label
var clue_label         : Label
var lead_label         : Label
var dialogue_panel     : PanelContainer
var dialogue_text      : Label
var choice_buttons     : Array = []
var death_overlay      : ColorRect
var death_text         : Label
var verdict_panel      : PanelContainer
var verdict_title      : Label
var verdict_buttons    : Array = []
var title_overlay      : ColorRect
var end_overlay        : ColorRect
var end_title          : Label
var end_body           : Label
var end_restart_button : Button

var interactables : Array = []

# ═════════════════════════════════════════
#  READY
# ═════════════════════════════════════════
func _ready() -> void:
	_build_interactables()
	_build_ui()
	_reset_run_state()
	_show_title()

# ═════════════════════════════════════════
#  PROCESS
# ═════════════════════════════════════════
func _process(delta: float) -> void:
	if game_state == GameState.PLAYING:
		_update_movement(delta)
		_update_nearest()
		_update_hud()
	load_flash           = max(load_flash - delta * 1.8, 0.0)
	prompt_notice_timer  = max(prompt_notice_timer - delta, 0.0)
	input_disorientation = max(input_disorientation - delta, 0.0)
	queue_redraw()

# ═════════════════════════════════════════
#  INPUT
# ═════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if input_disorientation > 0.0:
		return
	match game_state:
		GameState.TITLE:
			if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
				_start_game()
		GameState.ENDING:
			if event.keycode in [KEY_R, KEY_ENTER, KEY_SPACE]:
				_on_restart_pressed()
			elif event.keycode == KEY_ESCAPE:
				get_tree().quit()
		GameState.VERDICT:
			pass
		GameState.PLAYING:
			if verdict_active:
				return
			if awaiting_choice:
				if event.keycode >= KEY_1 and event.keycode <= KEY_4:
					var idx : int = int(event.keycode) - int(KEY_1)
					if idx < choice_options.size():
						_pick_choice(idx)
				return
			if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
				if dialogue_panel.visible:
					_advance_dialogue()
				else:
					_interact()

# ═════════════════════════════════════════
#  DRAW
# ═════════════════════════════════════════
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.035, 0.038, 0.046))
	draw_rect(ROOM_RECT.grow(24), Color(0.13, 0.12, 0.11))
	draw_rect(ROOM_RECT, Color(0.22, 0.205, 0.18))
	for x in range(int(ROOM_RECT.position.x), int(ROOM_RECT.end.x), 48):
		draw_line(Vector2(x, ROOM_RECT.position.y), Vector2(x, ROOM_RECT.end.y),
				  Color(0.17, 0.16, 0.145), 1.0)
	for y in range(int(ROOM_RECT.position.y), int(ROOM_RECT.end.y), 48):
		draw_line(Vector2(ROOM_RECT.position.x, y), Vector2(ROOM_RECT.end.x, y),
				  Color(0.17, 0.16, 0.145), 1.0)
	_draw_prop("body",  Rect2(205, 325, 120, 34),  Color(0.25, 0.05, 0.055))
	_draw_prop("rache", Rect2(660, 118, 150, 54),  Color(0.42, 0.03, 0.03))
	_draw_prop("table", Rect2(390, 205, 190, 105), Color(0.25, 0.18, 0.11))
	_draw_prop("door",  Rect2(450, 62,  95,  22),  Color(0.08, 0.055, 0.035))
	_draw_prop("photo", Rect2(160, 120, 70,  92),  Color(0.07, 0.09, 0.10))
	_draw_prop("watch", Rect2(725, 398, 70,  70),  Color(0.54, 0.44, 0.22))
	draw_circle(Vector2(485, 235), 18, Color(0.72, 0.82, 0.86))
	draw_circle(Vector2(538, 238), 14, Color(0.95, 0.58, 0.19))
	draw_circle(player_pos, 18, Color(0.03, 0.025, 0.025))
	draw_circle(player_pos, 15, Color(0.83, 0.80, 0.68))
	draw_circle(player_pos + Vector2(5, -4), 3, Color(0.08, 0.07, 0.06))
	if load_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size),
				  Color(0.72, 0.82, 0.86, load_flash * 0.22))

func _draw_prop(id: String, rect: Rect2, color: Color) -> void:
	var highlight := (id == nearest_id
		and not dialogue_panel.visible
		and not awaiting_choice
		and not verdict_active)
	draw_rect(rect, color.lightened(0.18) if highlight else color)
	draw_rect(rect, Color(0.015, 0.012, 0.010), false, 2.0)

# ═════════════════════════════════════════
#  BUILD
# ═════════════════════════════════════════
func _build_interactables() -> void:
	interactables = [
		{"id": "body",  "name": "Body",         "pos": Vector2(265, 342), "radius": 85.0},
		{"id": "rache", "name": "RACHE",         "pos": Vector2(735, 150), "radius": 92.0},
		{"id": "table", "name": "Table",         "pos": Vector2(485, 255), "radius": 95.0},
		{"id": "door",  "name": "Door",          "pos": Vector2(498, 93),  "radius": 86.0},
		{"id": "photo", "name": "Photograph",    "pos": Vector2(195, 165), "radius": 65.0},
		{"id": "watch", "name": "Pocket Watch",  "pos": Vector2(760, 432), "radius": 72.0},
	]

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# Title
	title_overlay = ColorRect.new()
	title_overlay.color = Color(0.015, 0.012, 0.011, 0.92)
	title_overlay.size  = Vector2(960, 620)
	canvas.add_child(title_overlay)
	var tp := PanelContainer.new()
	tp.position = Vector2(260, 140); tp.size = Vector2(440, 330)
	title_overlay.add_child(tp)
	var tbox := VBoxContainer.new()
	tbox.custom_minimum_size = Vector2(400, 290)
	tbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tp.add_child(tbox)
	var ttitle := Label.new()
	ttitle.text = "RACHE"
	ttitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttitle.add_theme_font_size_override("font_size", 54)
	ttitle.add_theme_color_override("font_color", Color(0.82, 0.08, 0.07))
	tbox.add_child(ttitle)
	var tsub := Label.new()
	tsub.text = "Death is not failure. Death is investigation."
	tsub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tsub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tsub.add_theme_color_override("font_color", Color(0.82, 0.78, 0.66))
	tbox.add_child(tsub)
	var tstart := Button.new()
	tstart.text = "Begin Investigation"
	tstart.custom_minimum_size = Vector2(330, 48)
	tstart.pressed.connect(_start_game)
	tbox.add_child(tstart)
	var thint := Label.new()
	thint.text = "Press Enter / Space / E"
	thint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thint.add_theme_color_override("font_color", Color(0.56, 0.54, 0.48))
	tbox.add_child(thint)

	# HUD
	prompt_label = Label.new()
	prompt_label.position = Vector2(24, 22)
	prompt_label.size = Vector2(520, 34)
	prompt_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(prompt_label)

	help_label = Label.new()
	help_label.position = Vector2(24, 570)
	help_label.size = Vector2(640, 28)
	help_label.text = "WASD move   E interact/advance   1-4 choose"
	help_label.add_theme_font_size_override("font_size", 13)
	help_label.add_theme_color_override("font_color", Color(0.73, 0.70, 0.62))
	canvas.add_child(help_label)

	clue_label = Label.new()
	clue_label.position = Vector2(690, 46)
	clue_label.size = Vector2(230, 28)
	clue_label.add_theme_font_size_override("font_size", 14)
	clue_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.79))
	canvas.add_child(clue_label)

	lead_label = Label.new()
	lead_label.position = Vector2(690, 78)
	lead_label.size = Vector2(230, 110)
	lead_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead_label.add_theme_font_size_override("font_size", 13)
	lead_label.add_theme_color_override("font_color", Color(0.86, 0.78, 0.58))
	canvas.add_child(lead_label)

	# Dialogue
	dialogue_panel = PanelContainer.new()
	dialogue_panel.position = Vector2(90, 390)
	dialogue_panel.size     = Vector2(780, 160)
	dialogue_panel.visible  = false
	canvas.add_child(dialogue_panel)
	var dbox := VBoxContainer.new()
	dialogue_panel.add_child(dbox)
	dialogue_text = Label.new()
	dialogue_text.custom_minimum_size = Vector2(730, 80)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size", 20)
	dbox.add_child(dialogue_text)
	var cbox := VBoxContainer.new()
	dbox.add_child(cbox)
	for i in range(4):
		var btn := Button.new()
		btn.visible = false
		btn.pressed.connect(_pick_choice.bind(i))
		cbox.add_child(btn)
		choice_buttons.append(btn)

	# Death overlay
	death_overlay = ColorRect.new()
	death_overlay.color   = Color(0.6, 0.0, 0.0, 0.0)
	death_overlay.size    = Vector2(960, 620)
	death_overlay.visible = false
	canvas.add_child(death_overlay)
	death_text = Label.new()
	death_text.position  = Vector2(310, 250)
	death_text.size      = Vector2(360, 100)
	death_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_text.add_theme_font_size_override("font_size", 26)
	death_text.add_theme_color_override("font_color", Color(1, 0.88, 0.78))
	death_overlay.add_child(death_text)

	# Verdict
	verdict_panel = PanelContainer.new()
	verdict_panel.position = Vector2(220, 100)
	verdict_panel.size     = Vector2(520, 420)
	verdict_panel.visible  = false
	canvas.add_child(verdict_panel)
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(480, 380)
	verdict_panel.add_child(vbox)
	verdict_title = Label.new()
	verdict_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	verdict_title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(verdict_title)
	const VERDICT_KEYS : Array = ["R", "A", "C", "H", "self", "back"]
	for i in range(VERDICT_KEYS.size()):
		var vbtn := Button.new()
		vbtn.custom_minimum_size = Vector2(440, 40)
		var k : String = VERDICT_KEYS[i]
		vbtn.pressed.connect(_submit_verdict.bind(k))
		vbox.add_child(vbtn)
		verdict_buttons.append(vbtn)

	# End overlay
	end_overlay = ColorRect.new()
	end_overlay.color   = Color(0.01, 0.008, 0.007, 0.95)
	end_overlay.size    = Vector2(960, 620)
	end_overlay.visible = false
	canvas.add_child(end_overlay)
	var ep := PanelContainer.new()
	ep.position = Vector2(190, 54); ep.size = Vector2(580, 520)
	end_overlay.add_child(ep)
	var ebox := VBoxContainer.new()
	ebox.custom_minimum_size = Vector2(540, 480)
	ebox.alignment = BoxContainer.ALIGNMENT_CENTER
	ep.add_child(ebox)
	end_title = Label.new()
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 30)
	ebox.add_child(end_title)
	end_body = Label.new()
	end_body.custom_minimum_size = Vector2(520, 330)
	end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_body.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_body.add_theme_font_size_override("font_size", 15)
	end_body.add_theme_color_override("font_color", Color(0.82, 0.78, 0.66))
	ebox.add_child(end_body)
	end_restart_button = Button.new()
	end_restart_button.text = "Return to Title"
	end_restart_button.custom_minimum_size = Vector2(280, 38)
	end_restart_button.pressed.connect(_on_restart_pressed)
	ebox.add_child(end_restart_button)
	var equit := Button.new()
	equit.text = "Quit"
	equit.custom_minimum_size = Vector2(280, 38)
	equit.pressed.connect(func(): get_tree().quit())
	ebox.add_child(equit)

# ═════════════════════════════════════════
#  SAVE / LOAD
# ═════════════════════════════════════════
func _save_checkpoint() -> void:
	var file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file == null:
		return
	var data := {
		"loop_count"  : loop_count,
		"ng_plus"     : ng_plus,
		"has_died"    : has_died,
		"score"       : score,
		"route"       : route,
		"clue_state"  : clue_state,
		"seen_dialogs": seen_dialogs,
	}
	file.store_string(JSON.stringify(data))
	file.close()

func _delete_checkpoint() -> void:
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute("user://savegame.json")

# ═════════════════════════════════════════
#  RESET / TITLE / START
# ═════════════════════════════════════════
func _reset_run_state() -> void:
	player_pos           = Vector2(460, 420)
	movement_locked      = false
	dying                = false
	load_flash           = 0.0
	input_disorientation = 0.0
	prompt_notice        = ""
	prompt_notice_timer  = 0.0
	nearest_id           = ""
	was_near_door        = false
	pending_death        = false
	pending_death_reason = ""
	pending_ending_id    = ""
	verdict_active       = false
	verdict_choice       = ""
	current_object       = ""
	awaiting_choice      = false
	choice_options       = []
	dialogue_lines       = []
	dialogue_index       = 0
	door_rach_index      = 0
	door_approach_count  = 0
	loop_count           = 1
	has_died             = false
	ng_plus              = false
	for k in score.keys():       score[k]       = 0
	for k in route.keys():       route[k]       = false
	for k in clue_state.keys():  clue_state[k]  = MemoryState.UNKNOWN
	for k in seen_dialogs.keys(): seen_dialogs[k] = []
	if dialogue_panel != null:
		dialogue_panel.visible = false
		death_overlay.visible  = false
		verdict_panel.visible  = false
		end_overlay.visible    = false
		for btn in choice_buttons:
			btn.visible = false

func _show_title() -> void:
	_reset_run_state()
	game_state            = GameState.TITLE
	title_overlay.visible = true
	end_overlay.visible   = false
	movement_locked       = true

func _start_game() -> void:
	# New Game only — no checkpoint load
	_delete_checkpoint()
	_reset_run_state()
	game_state            = GameState.PLAYING
	title_overlay.visible = false
	end_overlay.visible   = false
	movement_locked       = false
	_show_dialogue(RacheIntroDialogue.OPENING)
	_save_checkpoint()

func _restart_ng_plus() -> void:
	# Start NG+ from a clean run, but preserve the fact that R ending was seen.
	_reset_run_state()
	ng_plus              = true
	has_died             = true
	loop_count           = 5
	route["good_R_seen"] = true
	game_state            = GameState.PLAYING
	end_overlay.visible   = false
	title_overlay.visible = false
	movement_locked       = false
	_save_checkpoint()
	_show_dialogue(RacheIntroDialogue.NG_PLUS_OPENING)

func _on_restart_pressed() -> void:
	if ng_plus and game_state == GameState.ENDING:
		_restart_ng_plus()
	else:
		_show_title()

# ═════════════════════════════════════════
#  SCORE HELPERS
# ═════════════════════════════════════════
func _score_key(id: String) -> String:
	var up := id.to_upper()
	return "SELF" if (up == "SELF" or id.to_lower() == "self") else up

func add_score(id: String, amount: int) -> void:
	var key := _score_key(id)
	if not score.has(key):
		return
	score[key] = clampi(int(score[key]) + amount, 0, 10)

func reduce_score(id: String, amount: int) -> void:
	add_score(id, -amount)

func clear_count() -> int:
	var n := 0
	for k in clue_state.keys():
		if clue_state[k] == MemoryState.CLEAR:
			n += 1
	return n

func core_clues_seen() -> bool:
	for k in ["table", "body", "door", "rache", "photo"]:
		if clue_state[k] == MemoryState.UNKNOWN:
			return false
	return true

func can_open_verdict() -> bool:
	return bool(route["has_valid_death"]) and core_clues_seen()

func can_true_end() -> bool:
	return (
		ng_plus
		and bool(route["good_R_seen"])
		and bool(route["poison_after_body"])
		and bool(route["door_after_rache"])
		and bool(route["watch_after_deaths"])
		and int(score["SELF"]) >= 5
	)

func resolve_ending(verdict: String) -> String:
	if ng_plus:
		return resolve_ng_ending(verdict)
	return resolve_game1_ending(verdict)

func resolve_game1_ending(verdict: String) -> String:
	match verdict:
		"R":
			if int(score["R"]) >= 3 and clear_count() >= 5 and bool(route["has_valid_death"]):
				return "good_end_1"
			return "bad_end_weak"
		"A":
			return "bad_end_A" if int(score["A"]) >= 3 else "bad_end_weak"
		"C":
			return "bad_end_C" if int(score["C"]) >= 3 else "bad_end_weak"
		"H":
			return "bad_end_H" if int(score["H"]) >= 3 else "bad_end_weak"
		"self":
			return "bad_end_scapegoat" if int(score["SELF"]) >= 2 else "bad_end_weak"
	return "bad_end_weak"

func resolve_ng_ending(verdict: String) -> String:
	match verdict:
		"self":
			return "true_end" if can_true_end() else "bad_end_scapegoat"
		"R":
			return "r_repeat"
		"A":
			return "bad_end_A"
		"C":
			return "bad_end_C"
		"H":
			return "bad_end_H"
	return "bad_end_weak"

func _case_strength(id: String) -> String:
	var v : int = int(score[_score_key(id)])
	if v >= 4: return "Strong case"
	if v >= 2: return "Plausible case"
	return "Weak case"

func _highest_bias() -> String:
	var best := ""; var best_v := -1
	for k in score.keys():
		var v : int = int(score[k])
		if v > best_v:
			best_v = v; best = k
	return "" if best_v <= 0 else best

# ═════════════════════════════════════════
#  MOVEMENT & NEAREST
# ═════════════════════════════════════════
func _update_movement(delta: float) -> void:
	if movement_locked or dialogue_panel.visible or awaiting_choice or verdict_active or dying:
		return
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1
	if dir != Vector2.ZERO:
		player_pos += dir.normalized() * PLAYER_SPEED * delta
		player_pos.x = clamp(player_pos.x, ROOM_RECT.position.x + 15, ROOM_RECT.end.x - 15)
		player_pos.y = clamp(player_pos.y, ROOM_RECT.position.y + 15, ROOM_RECT.end.y - 15)

func _update_nearest() -> void:
	nearest_id = ""
	var best := INF
	for item in interactables:
		var d : float = player_pos.distance_to(item["pos"])
		if d <= float(item["radius"]) and d < best:
			best = d; nearest_id = item["id"]
	var near_door := nearest_id == "door"
	if near_door and not was_near_door and not movement_locked and not dialogue_panel.visible and not awaiting_choice and not verdict_active:
		_try_door_rach_ambient()
	was_near_door = near_door

# ═════════════════════════════════════════
#  HUD
# ═════════════════════════════════════════
func _update_hud() -> void:
	var nc := clear_count()
	var nh := 0
	for k in clue_state.keys():
		if clue_state[k] == MemoryState.HAZY: nh += 1
	clue_label.text = "Clear: %d   Hazy: %d" % [nc, nh]
	var lead_text := _current_lead().strip_edges()
	var prompt_text := ""
	if prompt_notice_timer > 0.0:
		prompt_text = prompt_notice.strip_edges()
	elif not dialogue_panel.visible and not awaiting_choice and not verdict_active and nearest_id != "":
		if nearest_id == "watch" and can_open_verdict():
			prompt_text = "[E] Examine watch / verdict"
		else:
			prompt_text = "[E] Examine %s" % nearest_id.capitalize()
	prompt_label.visible = prompt_text != ""
	prompt_label.text = prompt_text
	lead_label.visible = lead_text != ""
	lead_label.text = lead_text

func _show_prompt_notice(text: String) -> void:
	prompt_notice = text; prompt_notice_timer = 1.8

func _current_lead() -> String:
	if ng_plus:
		if clue_state["table"] == MemoryState.CLEAR and clue_state["body"] == MemoryState.CLEAR and not bool(route["poison_after_body"]):
			return "The glass still has something to teach my body."
		if clue_state["door"] == MemoryState.CLEAR and clue_state["rache"] == MemoryState.CLEAR and not bool(route["door_after_rache"]):
			return "The door sounds different now that the writing makes sense."
		if bool(route["poison_after_body"]) and bool(route["door_after_rache"]) and not bool(route["watch_after_deaths"]):
			return "The watch is waiting for the deaths to line up."
	if core_clues_seen() and not bool(route["has_valid_death"]):
		return "The room is solved. The watch is not."
	if can_open_verdict():
		return "The watch feels heavier than before."
	if clue_state["table"] == MemoryState.UNKNOWN:
		return "Find how the victim died."
	if clue_state["body"] == MemoryState.UNKNOWN:
		return "Why did the victim stay seated?"
	if clue_state["door"] == MemoryState.UNKNOWN:
		return "Why was the room sealed?"
	if clue_state["rache"] == MemoryState.UNKNOWN or clue_state["rache"] == MemoryState.HAZY:
		return "Something about the writing is off."
	if clue_state["photo"] == MemoryState.UNKNOWN:
		return "The photograph has a hierarchy."
	if clue_state["watch"] == MemoryState.UNKNOWN:
		return "The watch is not done with me."
	return "The watch keeps time with something I cannot hear."

func _after_clue_hint() -> String:
	if can_open_verdict(): return "The watch ticks once."
	if has_died: return "A detail refuses to stay buried."
	return "The room has not finished speaking."

# ═════════════════════════════════════════
#  LOOP PHASE
# ═════════════════════════════════════════
func _phase() -> int:
	if loop_count <= 2: return LoopPhase.EARLY
	if loop_count <= 4: return LoopPhase.MID
	return LoopPhase.LATE

# ═════════════════════════════════════════
#  DEATH SYSTEM
# ═════════════════════════════════════════
func _apply_death_bias_shift(cause: String) -> void:
	route["has_valid_death"] = true
	match cause:
		"poison":
			route["poison_death_spent"] = true
			add_score("C", 1)
		"door":
			route["door_death_spent"] = true
			add_score("H", 1)
			add_score("SELF", 1)
			reduce_score("C", 1)
		"watch":
			route["watch_death_spent"] = true
			add_score("SELF", 2)
			reduce_score("R", 1)
			reduce_score("A", 1)
			reduce_score("C", 1)
			reduce_score("H", 1)

func _queue_death(cause: String, reason: String) -> void:
	pending_death_reason = reason
	pending_death        = true
	_apply_death_bias_shift(cause)

func _die(reason: String) -> void:
	if dying:
		return
	dying        = true
	has_died     = true
	movement_locked      = true
	death_overlay.visible = true
	death_overlay.color   = Color(0.6, 0.0, 0.0, 0.55)
	death_text.text = reason + "\n\n..."
	await get_tree().create_timer(1.2).timeout
	loop_count          += 1
	door_approach_count  = 0
	_save_checkpoint()
	player_pos           = Vector2(460, 420)
	load_flash           = 1.0
	input_disorientation = 0.4
	death_overlay.visible = false
	dying = false
	await get_tree().create_timer(0.35).timeout
	_show_dialogue(_death_return_lines())

func _death_return_lines() -> Array:
	return LoopManager.new().get_death_return_lines()

# ═════════════════════════════════════════
#  INTERACT DISPATCHER
# ═════════════════════════════════════════
func _interact() -> void:
	if nearest_id == "":
		return
	match nearest_id:
		"table" : _inspect_table()
		"body"  : _inspect_body()
		"door"  : _inspect_door()
		"rache" : _inspect_rache()
		"photo" : _inspect_photo()
		"watch" : _inspect_watch()

func _try_door_rach_ambient() -> void:
	door_approach_count += 1
	if door_rach_index < door_rach_pool.size() and door_approach_count % 2 == 1:
		var lines : Array = door_rach_pool[door_rach_index].duplicate()
		door_rach_index += 1
		_show_dialogue(lines)

func _dep_met(object_id: String) -> bool:
	var dep : String = CLUE_DEPS.get(object_id, "")
	if dep == "": return true
	return clue_state[dep] == MemoryState.CLEAR

# ═════════════════════════════════════════
#  TABLE
# ═════════════════════════════════════════
func _inspect_table() -> void:
	if clue_state["table"] == MemoryState.CLEAR:
		# NG+ gate 1: revisit glass after body clear
		if ng_plus and clue_state["body"] == MemoryState.CLEAR and not bool(route["poison_after_body"]):
			_present_object_choice("table",
				_table_revisit() + ["The residue is still there."],
				[
					{"label": "A) Follow the scent.", "key": "taste"},
					{"label": "B) Leave it.", "key": "leave"},
				]
			)
			return
		_show_dialogue(_table_revisit())
		return
	_present_object_choice("table", _table_intro(), [
		{"label": "A) Examine the glass.", "key": "glass"},
		{"label": "B) Smell the residue.", "key": "smell"},
		{"label": "C) Leave it.",          "key": "leave"},
	])

func _table_intro() -> Array:
	match _phase():
		LoopPhase.EARLY:
			return [
				"A table. One glass, contents partially consumed.",
				"Residue along the rim.",
				"Not wine.",
			]
		LoopPhase.MID:
			return [
				"Same glass. Same residue.",
				"I already know what I'll find.",
				"The question is who had the patience",
				"to sit across from someone and watch them drink it.",
			]
		_:
			return [
				"The table. The glass.",
				"I keep coming back here like the answer's going to change.",
				"It won't.",
				"But something else might.",
			]

func _table_revisit() -> Array:
	match _phase():
		LoopPhase.EARLY:
			return [
				"Residue on the rim. Bitter almond. Metallic after-scent.",
				"Measured dose. Whoever did this knew exactly how much.",
			]
		LoopPhase.MID:
			return ["Same conclusion.", "Measured. Deliberate. Patient."]
		_:
			return [
				"Same read, every time.",
				"Someone who made peace with this before they walked in.",
			]

func _on_table_choice(key: String) -> void:
	match key:
		"glass":
			if _dep_met("table"):
				clue_state["table"] = MemoryState.CLEAR
				add_score("C", 2)
				match _phase():
					LoopPhase.EARLY:
						_show_dialogue([
							"Residue on the rim. Bitter almond. Metallic after-scent.",
							"Not wine. Not anything you'd drink by choice.",
							"Whoever put this here knew what they were doing.",
							"And they knew how long it would take.",
						])
					LoopPhase.MID:
						_show_dialogue([
							"Same residue. Same profile.",
							"Planned. Patient.",
							"Someone who waited for the right moment",
							"and never second-guessed it.",
						])
					_:
						_show_dialogue([
							"Measured. Deliberate.",
							"Someone who made peace with this",
							"before they ever walked into the room.",
						])
			else:
				clue_state["table"] = MemoryState.HAZY
				_show_dialogue(["Residue on the rim. Something wrong.", "I need more context before I can say what."])

		"smell":
			clue_state["table"] = max(int(clue_state["table"]), int(MemoryState.HAZY))
			add_score("C", 1)
			match _phase():
				LoopPhase.EARLY:
					_show_dialogue([
						"Bitter almond. Faint metallic note underneath.",
						"Not wine.",
						"Not anything that belongs in a drink.",
					])
				_:
					_show_dialogue([
						"The same scent.",
						"I don't need to smell it again to know what it means.",
						"But here I am.",
					])

		"taste":
			# NG+ Gate 1: reinterpret the glass as memory echo, not a repeatable death.
			if ng_plus and clue_state["table"] == MemoryState.CLEAR and clue_state["body"] == MemoryState.CLEAR and not bool(route["poison_after_body"]):
				route["poison_after_body"] = true
				route["poison_death_spent"] = true
				add_score("SELF", 1)
				reduce_score("C", 1)
				_show_dialogue([
					"I don't need to taste it.",
					"The smell is enough.",
					"My throat remembers the rest.",
					"The glass isn't only evidence.",
					"It's a rehearsal.",
				])
				return
			# Anti-abuse: block repeat.
			if bool(route["poison_death_spent"]):
				_show_dialogue([
					"I already know how this ends.",
					"Repeating it would not make me smarter.",
				])
				return
			_queue_death("poison", "Sweet almond. Warm glass. Then the floor rises too fast.")
			_show_dialogue([
				"I touch the residue to my tongue.",
				"Stupid.",
				"Useful.",
			])

		"leave":
			clue_state["table"] = max(int(clue_state["table"]), int(MemoryState.HAZY))
			_show_dialogue(["Not everything needs to be touched."])

# ═════════════════════════════════════════
#  BODY
# ═════════════════════════════════════════
func _inspect_body() -> void:
	if clue_state["body"] == MemoryState.CLEAR:
		_show_dialogue(_body_revisit())
		return
	_present_object_choice("body", _body_intro(), [
		{"label": "A) Examine the position.",     "key": "position"},
		{"label": "B) Examine the second glass.", "key": "glass2"},
		{"label": "C) Leave it.",                 "key": "leave"},
	])

func _body_intro() -> Array:
	match _phase():
		LoopPhase.EARLY:
			return [
				"Victim. Seated. No signs of struggle —",
				"no overturned furniture, no defensive wounds.",
				"They didn't run.",
				"Either they couldn't, or they didn't think they needed to.",
			]
		LoopPhase.MID:
			return [
				"Still here. Obviously.",
				"They came to this room willingly.",
				"Whoever they were meeting,",
				"they had no reason to be afraid of them.",
			]
		_:
			return [
				"I keep looking at the position of the body",
				"like it's going to tell me something new.",
				"It won't.",
				"They sat down. They trusted someone.",
				"That's almost the whole story.",
			]

func _body_revisit() -> Array:
	match _phase():
		LoopPhase.EARLY:
			return [
				"No defensive wounds.",
				"They were invited here by someone they had no reason to fear.",
			]
		_:
			return [
				"Someone close. Someone trusted.",
				"The kind of trust that takes years to build",
				"and about thirty minutes to use.",
			]

func _on_body_choice(key: String) -> void:
	match key:
		"position":
			if _dep_met("body"):
				clue_state["body"] = MemoryState.CLEAR
				add_score("R", 2)
				match _phase():
					LoopPhase.EARLY:
						_show_dialogue([
							"Chair pulled in, body relaxed.",
							"They sat here like they were having a meeting.",
							"Which means whoever invited them",
							"was someone they had meetings with. Regularly. Comfortably.",
							"Not a stranger. Not an enemy. Someone close.",
						])
					_:
						_show_dialogue([
							"Same read.",
							"Someone close. Someone trusted.",
							"The kind of trust that takes years to build",
							"and about thirty minutes to exploit.",
						])
			else:
				clue_state["body"] = max(int(clue_state["body"]), int(MemoryState.HAZY))
				add_score("R", 1)
				_show_dialogue([
					"They trusted someone. That's clear.",
					"But I'm missing something about why they came here at all.",
				])

		"glass2":
			add_score("R", 1)
			add_score("A", 1)
			match _phase():
				LoopPhase.EARLY:
					_show_dialogue([
						"Second glass. Clean. Untouched.",
						"Whoever sat across from them didn't drink.",
						"Interesting choice —",
						"to pour yourself a glass and not touch it.",
						"Like the gesture was the point, not the drink.",
					])
				_:
					_show_dialogue([
						"Clean glass. Again.",
						"You sit across from someone,",
						"pour yourself a drink, watch them die.",
						"And you don't spill a drop.",
						"That's not nerves.",
						"That's someone who's been cleaning up messes",
						"for so long they don't make them anymore.",
					])

		"leave":
			clue_state["body"] = max(int(clue_state["body"]), int(MemoryState.HAZY))
			_show_dialogue(["Some things are better left where they fell."])

# ═════════════════════════════════════════
#  DOOR
# ═════════════════════════════════════════
func _inspect_door() -> void:
	if clue_state["door"] == MemoryState.CLEAR:
		# NG+ gate 2: revisit force after rache clear
		if ng_plus and clue_state["rache"] == MemoryState.CLEAR and not bool(route["door_after_rache"]):
			_present_object_choice("door",
				_door_revisit() + ["The handle waits like a dare."],
				[
					{"label": "A) Force it again.", "key": "force"},
					{"label": "B) Step back.",      "key": "frame"},
				]
			)
			return
		_show_dialogue(_door_revisit())
		return
	_present_object_choice("door", _door_intro(), [
		{"label": "A) Examine the mechanism.", "key": "mechanism"},
		{"label": "B) Examine the frame.",     "key": "frame"},
		{"label": "C) Try to open it.",        "key": "force"},
	])

func _door_intro() -> Array:
	match _phase():
		LoopPhase.EARLY:
			return [
				"Locked. From the outside.",
				"Mechanism's been modified — not broken, modified.",
				"Built to punish whoever opened it.",
			]
		LoopPhase.MID:
			return [
				"Still locked.",
				"The mechanism's the same.",
				"Whoever built this built it to hold once and hold well.",
			]
		_:
			return [
				"The door.",
				"I've stood here enough times to know",
				"it's not going to open on its own.",
				"But I keep checking anyway.",
			]

func _door_revisit() -> Array:
	if _phase() == LoopPhase.EARLY:
		return [
			"Trap. Precision work.",
			"It reacts exactly how an investigator would test a locked room.",
		]
	if ng_plus and bool(route["door_after_rache"]):
		return [
			"Same trap. Same precision.",
			"Not someone like me.",
			"Me.",
		]
	return [
		"Same trap. Same precision.",
		"Built for someone who tests doors like I do.",
	]

func _on_door_choice(key: String) -> void:
	match key:
		"mechanism":
			if _dep_met("door"):
				clue_state["door"] = MemoryState.CLEAR
				add_score("H", 2)
				match _phase():
					LoopPhase.EARLY:
						_show_dialogue([
							"This isn't improvised.",
							"Whoever rigged this knew exactly how an investigator",
							"would approach a locked room.",
							"Built to punish whoever opened it.",
							"That's either very smart or very paranoid.",
							"Usually both.",
						])
					_:
						_show_dialogue([
							"Same rig. Same precision.",
							"Designed for the investigator.",
							"Designed for me, technically.",
							"...I really should have asked more questions",
							"before taking this job.",
						])
			else:
				clue_state["door"] = max(int(clue_state["door"]), int(MemoryState.HAZY))
				add_score("H", 1)
				_show_dialogue([
					"A trap. But I'm missing context.",
					"I don't have enough to say who this was built for.",
				])

		"frame":
			add_score("H", 1)
			add_score("A", 1)
			match _phase():
				LoopPhase.EARLY:
					_show_dialogue([
						"Markings on the frame. Small. Easy to miss.",
						"This was measured. Tested.",
						"Whoever did this works within systems.",
					])
				_:
					_show_dialogue([
						"The markings again.",
						"Precise. Almost bureaucratic.",
						"Whoever did this didn't think of it as violence.",
						"They thought of it as procedure.",
					])

		"force":
			# NG+ Gate 2: reinterpret the door before anti-abuse blocks old death routes.
			if ng_plus and clue_state["door"] == MemoryState.CLEAR and clue_state["rache"] == MemoryState.CLEAR and not bool(route["door_after_rache"]):
				route["door_after_rache"] = true
				route["door_death_spent"] = true
				add_score("SELF", 2)
				reduce_score("H", 1)
				_show_dialogue([
					"I don't need to open it.",
					"I know where the wire is.",
					"I know where my hand would go.",
					"The trap wasn't built for a body.",
					"It was built for a habit.",
				])
				return
			# Anti-abuse.
			if bool(route["door_death_spent"]):
				_show_dialogue([
					"I already know how this ends.",
					"Repeating it would not make me smarter.",
				])
				return
			clue_state["door"] = max(int(clue_state["door"]), int(MemoryState.HAZY))
			_queue_death("door", "The door mechanism snaps. Something tightens.")
			_show_dialogue([
				"Fine.",
				"Footsteps outside. They stop for a long time.",
				"Then they move on, slower.",
				"Locked. Still locked.",
			])

# ═════════════════════════════════════════
#  RACHE
# ═════════════════════════════════════════
func _inspect_rache() -> void:
	if clue_state["rache"] == MemoryState.CLEAR:
		_show_dialogue(_rache_revisit())
		return
	_present_object_choice("rache", _rache_intro(), [
		{"label": "A) Read it as a word.",     "key": "read"},
		{"label": "B) Look at the strokes.",   "key": "writing"},
		{"label": "C) Leave it.",              "key": "leave"},
	])

func _rache_intro() -> Array:
	match _phase():
		LoopPhase.EARLY:
			return [
				"Dying message. One word — or what looks like one word.",
				"RACHE.",
				"Revenge, in German. The obvious read.",
				"Real life tends to be less elegant.",
			]
		LoopPhase.MID:
			return [
				"RACHE. Again.",
				"I've been reading this as a word.",
				"What if it's not a word?",
			]
		_:
			return [
				"RACHE.",
				"Every time I come back, it's still the last thing they wrote.",
				"The letters keep separating in my head.",
				"Sequence. Pressure. Intention.",
			]

func _rache_revisit() -> Array:
	match _phase():
		LoopPhase.EARLY:
			return [
				"Not quite a word.",
				"Letters separated by a dying hand.",
			]
		_:
			return [
				"A sequence of responsibility.",
				"Written by someone with poison in their system",
				"and apparently better priorities than I do.",
			]

func _on_rache_choice(key: String) -> void:
	match key:
		"read":
			clue_state["rache"] = max(int(clue_state["rache"]), int(MemoryState.HAZY))
			add_score("C", 1)
			_show_dialogue([
				"RACHE.",
				"A word, if I force it to be one.",
				"That feels convenient.",
			])

		"writing":
			if _dep_met("rache"):
				clue_state["rache"] = MemoryState.CLEAR
				add_score("R", 1)
				add_score("A", 1)
			else:
				clue_state["rache"] = max(int(clue_state["rache"]), int(MemoryState.HAZY))
				add_score("A", 1)
			match _phase():
				LoopPhase.EARLY:
					_show_dialogue([
						"Shaking hands. Expected.",
						"But the structure — the way the letters are formed —",
						"that's not panic writing. That's trained writing.",
						"One at a time. Not a word.",
						"Something else.",
					])
				_:
					_show_dialogue([
						"Same handwriting. Same structure.",
						"They were dying and they still wrote",
						"the way someone else taught them to.",
						"The person who taught them that structure",
						"is the same person who designed the system that killed them.",
					])

		"leave":
			clue_state["rache"] = max(int(clue_state["rache"]), int(MemoryState.HAZY))
			_show_dialogue(["Dead men's last words are above my pay grade."])

# ═════════════════════════════════════════
#  PHOTO
# ═════════════════════════════════════════
func _inspect_photo() -> void:
	if clue_state["photo"] == MemoryState.CLEAR:
		_show_dialogue(_photo_revisit())
		return
	_present_object_choice("photo", _photo_intro(), [
		{"label": "A) Examine who's in it.",    "key": "who"},
		{"label": "B) Examine how they stand.", "key": "posture"},
		{"label": "C) Leave it.",               "key": "leave"},
	])

func _photo_intro() -> Array:
	match _phase():
		LoopPhase.EARLY:
			return [
				"Formal photograph. Four people. The victim at the center.",
				"Not family. Not casual.",
				"A hierarchy.",
			]
		LoopPhase.MID:
			return [
				"Four people arranged around the victim.",
				"Not affection. Position.",
			]
		_:
			return [
				"I keep coming back to this photograph.",
				"Four people who are not in this room.",
				"And me.",
				"...who also knew the victim. Professionally.",
			]

func _photo_revisit() -> Array:
	match _phase():
		LoopPhase.EARLY:
			return [
				"Four people. Inner circle.",
				"I'm not in this photograph.",
				"But the wall still makes room for something missing.",
			]
		_:
			return [
				"Four people who made a decision together.",
				"I wasn't in the room when they made it.",
				"I was just — adjacent. Helpful.",
				"That word's starting to bother me.",
			]

func _on_photo_choice(key: String) -> void:
	match key:
		"who":
			if _dep_met("photo"):
				clue_state["photo"] = MemoryState.CLEAR
				add_score("R", 1); add_score("A", 1)
				add_score("C", 1); add_score("H", 1)
				if clue_state["rache"] >= MemoryState.HAZY:
					match _phase():
						LoopPhase.EARLY:
							_show_dialogue([
								"Four people.",
								"I'm not in this photograph.",
								"But the wall still makes room for something missing.",
								"...I'm going to need a minute with that.",
							])
						_:
							_show_dialogue([
								"Four people who made a decision together.",
								"I wasn't in the room when they made it.",
								"I was just — adjacent. Helpful.",
								"That word's starting to bother me.",
							])
				else:
					_show_dialogue([
						"Four people. A hierarchy.",
						"I'm not in this photograph.",
					])
			else:
				clue_state["photo"] = max(int(clue_state["photo"]), int(MemoryState.HAZY))
				_show_dialogue([
					"Four people.",
					"I don't have enough context yet to read what this means.",
				])

		"posture":
			add_score("A", 2); add_score("H", 1)
			match _phase():
				LoopPhase.EARLY:
					_show_dialogue([
						"Body language is honest when people forget the camera's running.",
						"The one closest to the victim — natural. Comfortable. Like family.",
						"The one at the edge — not participating, cataloguing.",
						"The one with face half-turned — knows what a photograph records.",
						"The one at the border — not a colleague. A perimeter.",
					])
				_:
					_show_dialogue([
						"I've memorized this photograph without meaning to.",
						"The one who stood closest — gave everything. Got nothing back.",
						"The one who stood apart — calculated from a distance. Called it logic.",
						"The one who looked away — had a reason that felt personal enough.",
						"The one at the edge — already in too deep before anyone asked.",
						"Four different ways to end up responsible for the same body.",
					])

		"leave":
			clue_state["photo"] = max(int(clue_state["photo"]), int(MemoryState.HAZY))
			_show_dialogue(["Some faces don't need names."])

# ═════════════════════════════════════════
#  WATCH
# ═════════════════════════════════════════
func _inspect_watch() -> void:
	# NG+ takes priority
	if ng_plus:
		var opts : Array = [{"label": "A) Hold it open.", "key": "hold"}]
		if can_open_verdict():
			opts.append({"label": "B) Open verdict.", "key": "verdict"})
		opts.append({"label": "%s) Not yet." % _next_key_label(opts.size()), "key": "notyet"})
		_present_object_choice("watch", [
			"This watch doesn't belong to me.",
			"But it feels like it does.",
			"It's been with me since — since before I can remember.",
		], opts)
		return

	# Forced watch death gate: core seen, no valid death yet
	if core_clues_seen() and not bool(route["has_valid_death"]) and not bool(route["watch_death_spent"]):
		clue_state["watch"] = max(int(clue_state["watch"]), int(MemoryState.HAZY))
		_queue_death("watch", "The watch opens inside my skull.")
		_show_dialogue([
			"The case is almost neat.",
			"The watch disagrees.",
			"It starts ticking under my skin.",
		])
		return

	if can_open_verdict():
		_open_verdict()
		return

	if not has_died:
		_present_object_choice("watch",
			["A watch. Stopped.", "Belongs to the victim.", "Stopped at time of death, or close enough."],
			[
				{"label": "A) Take it.", "key": "take"},
				{"label": "B) Leave it.", "key": "leave"},
			]
		)
	else:
		match _phase():
			LoopPhase.EARLY:
				_present_object_choice("watch",
					["The watch again.", "I knew it was here before I saw it.", "That should bother me more than it does."],
					[{"label": "A) Hold it.", "key": "hold"}, {"label": "B) Leave it.", "key": "leave"}]
				)
			LoopPhase.MID:
				_present_object_choice("watch",
					["Watch. Same place, every time.", "I keep thinking I should leave it alone.", "I keep not doing that."],
					[{"label": "A) Hold it.", "key": "hold"}, {"label": "B) Leave it.", "key": "leave"}]
				)
			_:
				_present_object_choice("watch",
					[
						"Still here.",
						"There's something in this watch",
						"that I'm either not ready to find",
						"or not ready to admit I've already found.",
						"...I hate this case.",
					],
					[{"label": "A) Hold it.", "key": "hold"}, {"label": "B) Leave it.", "key": "leave"}]
				)

func _next_key_label(count: int) -> String:
	const KEYS := ["A", "B", "C", "D"]
	return KEYS[clampi(count, 0, KEYS.size() - 1)]

func _on_watch_choice(key: String) -> void:
	match key:
		"take":
			clue_state["watch"] = max(int(clue_state["watch"]), int(MemoryState.HAZY))
			add_score("SELF", 1)
			_show_dialogue([
				"Heavier than it looks.",
				"Something's in here. Not literally — metaphorically.",
				"...I don't usually think in metaphors.",
				"Moving on.",
			])

		"hold":
			clue_state["watch"] = MemoryState.CLEAR
			add_score("SELF", 1)
			# NG+ gate 3
			if ng_plus and bool(route["poison_after_body"]) and bool(route["door_after_rache"]) and not bool(route["watch_after_deaths"]) and not bool(route["watch_death_spent"]):
				route["watch_after_deaths"] = true
				add_score("SELF", 3)
				reduce_score("R", 1); reduce_score("A", 1)
				reduce_score("C", 1); reduce_score("H", 1)
				_queue_death("watch", "The watch opens inside my skull.")
				_show_dialogue([
					"The lid gives under my thumb.",
					"There is no mechanism inside.",
					"Only a sound I recognize too late.",
				])
				return
			if ng_plus and not bool(route["watch_after_deaths"]):
				_show_dialogue([
					"The lid catches under my thumb.",
					"Something inside refuses to open.",
					"Not locked.",
					"Waiting.",
				])
				return
			match _phase():
				LoopPhase.MID:
					_show_dialogue([
						"...huh.",
						"That's — odd.",
						"Not a sound, not an image. Just — weight.",
						"Someone else's fear, sitting in my chest.",
						"Someone who really, really didn't want to be forgotten.",
					])
				_:
					_show_dialogue([
						"There it is again.",
						"Their fear. Their need to have someone know.",
						"Not justice, necessarily.",
						"Just — witness.",
						"They didn't want to disappear without someone knowing.",
						"...I understand that. More than I expected to.",
					])

		"leave":
			match _phase():
				LoopPhase.EARLY: _show_dialogue(["Not yet."])
				LoopPhase.MID:   _show_dialogue(["...still not yet."])
				_:
					_show_dialogue([
						"I keep saying not yet.",
						"At some point that stops being caution",
						"and starts being something else.",
					])

		"listen":
			pending_ending_id = "true_end"
			_show_dialogue([
				"Okay.",
				"[Beat.]",
				"Yeah, I — I know.",
				"I've known for a while, actually.",
				"Didn't want to look at it directly.",
				"[Beat.]",
				"You hired me. Or — someone hired me,",
				"and I didn't ask enough questions about why.",
				"Someone asked me about locked rooms.",
				"About what investigators look for.",
				"I answered. Thoroughly. Professionally.",
				"I felt something was off.",
				"[Beat.]",
				"I didn't ask.",
				"It was easier not to.",
				"[Beat.]",
				"RACHE.",
				"And the person who told them exactly how to get away with it.",
				"[Long beat.]",
				"I'm a good investigator.",
				"I found the killer.",
				"Took me longer to find myself in the list.",
				"[Beat.]",
				"...yeah. I know what I have to do.",
			])

		"verdict":
			_open_verdict()

		"notyet":
			_show_dialogue([
				"Right. Not yet.",
				"...",
				"I really need to stop saying that.",
			])

# ═════════════════════════════════════════
#  CHOICE PRESENTATION
# ═════════════════════════════════════════
func _present_object_choice(obj_id: String, intro_lines: Array, options: Array) -> void:
	current_object = obj_id
	var decorated : Array = []
	var has_seen  : bool  = seen_dialogs.has(obj_id) and not seen_dialogs[obj_id].is_empty()
	for option in options:
		var copy : Dictionary = option.duplicate()
		if has_seen and not seen_dialogs[obj_id].has(copy["key"]):
			copy["label"] = "[NEW] %s" % copy["label"]
		decorated.append(copy)
	dialogue_lines  = intro_lines.duplicate()
	dialogue_index  = 0
	choice_options  = decorated
	awaiting_choice = false
	dialogue_panel.visible = true
	movement_locked = true
	_render_dialogue_line()

func _render_dialogue_line() -> void:
	if dialogue_index < dialogue_lines.size():
		dialogue_text.text = dialogue_lines[dialogue_index] + "\n\n[E] Continue"
		for btn in choice_buttons:
			btn.visible = false
	else:
		dialogue_text.text = ""
		awaiting_choice = true
		for i in range(choice_buttons.size()):
			if i < choice_options.size():
				choice_buttons[i].text    = choice_options[i]["label"]
				choice_buttons[i].visible = true
			else:
				choice_buttons[i].visible = false

func _pick_choice(idx: int) -> void:
	if not awaiting_choice: return
	if idx >= choice_options.size(): return
	awaiting_choice = false
	for btn in choice_buttons: btn.visible = false
	dialogue_panel.visible = false
	movement_locked = false
	var key : String = choice_options[idx]["key"]
	var obj : String = current_object
	if seen_dialogs.has(obj) and not seen_dialogs[obj].has(key):
		seen_dialogs[obj].append(key)
	choice_options = []
	current_object = ""
	_dispatch_choice(obj, key)

func _dispatch_choice(obj_id: String, key: String) -> void:
	match obj_id:
		"table" : _on_table_choice(key)
		"body"  : _on_body_choice(key)
		"door"  : _on_door_choice(key)
		"rache" : _on_rache_choice(key)
		"photo" : _on_photo_choice(key)
		"watch" : _on_watch_choice(key)

# ═════════════════════════════════════════
#  DIALOGUE
# ═════════════════════════════════════════
func _show_dialogue(lines: Array) -> void:
	dialogue_lines  = lines
	dialogue_index  = 0
	choice_options  = []
	awaiting_choice = false
	dialogue_panel.visible = true
	movement_locked = true
	for btn in choice_buttons: btn.visible = false
	_render_dialogue_line()

func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_render_dialogue_line()
		return
	if not choice_options.is_empty() and not awaiting_choice:
		_render_dialogue_line()
		return
	if awaiting_choice:
		_render_dialogue_line()
		return
	dialogue_panel.visible = false
	movement_locked = false
	for btn in choice_buttons: btn.visible = false
	if pending_death:
		pending_death = false
		var reason := pending_death_reason
		pending_death_reason = ""
		_die(reason)
		return
	if pending_ending_id != "":
		var eid := pending_ending_id
		pending_ending_id = ""
		_show_ending(eid)
		return
	_show_prompt_notice(_after_clue_hint())

# ═════════════════════════════════════════
#  VERDICT
# ═════════════════════════════════════════
func _open_verdict() -> void:
	verdict_active = true
	movement_locked = true
	dialogue_panel.visible = false
	var nc := clear_count()
	var intro : String
	if nc >= 6:
		intro = "Alright.\n\nWhat do I actually know versus what do I think I know.\nLet's not confuse the two.\n\nWho is responsible?"
	elif nc >= 3:
		intro = "Same room. Same question.\n\nWhat do I know. What can I prove.\nWhat's the difference.\n\nWho is responsible?"
	else:
		intro = "I don't know who did this.\n\nI know I'm here. I know they're not.\nI know I can't explain why I'm still in this room.\n\nWho is responsible?"
	match _highest_bias():
		"A":    intro += "\n\nThe plan keeps pointing at A."
		"C":    intro += "\n\nThe poison keeps pointing at C."
		"H":    intro += "\n\nThe door keeps pointing at H."
		"R":    intro += "\n\nTrust keeps pointing at R."
		"SELF": intro += "\n\nThe room keeps pointing back at me."
	verdict_title.text = intro
	var self_label : String
	if ng_plus and int(score["SELF"]) >= 5:
		self_label = "Myself — The missing piece"
	elif int(score["SELF"]) >= 2:
		self_label = "Myself — Unstable suspicion"
	else:
		self_label = "Myself — Weak case"
	var labels : Array = [
		"R — %s"    % _case_strength("R"),
		"A — %s"    % _case_strength("A"),
		"C — %s"    % _case_strength("C"),
		"H — %s"    % _case_strength("H"),
		self_label,
		"Back / Not yet",
	]
	for i in range(verdict_buttons.size()):
		verdict_buttons[i].text     = labels[i]
		verdict_buttons[i].disabled = false
	verdict_panel.visible = true

func _submit_verdict(key: String) -> void:
	if key == "back":
		verdict_active = false
		verdict_panel.visible = false
		movement_locked = false
		return
	verdict_active = false
	verdict_panel.visible = false
	movement_locked = false
	verdict_choice = key
	var resolved : String = resolve_ending(key)
	match key:
		"R":
			if resolved == "good_end_1":
				pending_ending_id = resolved
				_show_dialogue([
					"R.",
					"The one closest to the victim.",
					"The one who could invite them here",
					"without turning trust into alarm.",
					"The room points at R first.",
					"Maybe too cleanly.",
				])
			elif resolved == "r_repeat":
				pending_ending_id = resolved
				_show_dialogue([
					"R again.",
					"The room can still point there.",
					"Trust still begins the murder.",
					"But this time, that answer feels too small.",
				])
			else:
				pending_ending_id = resolved
				_show_dialogue([
					"I think it's R.",
					"I think.",
					"I don't have everything I need",
					"to say that like I mean it.",
					"...I hate saying things I don't mean.",
				])
		"A":
			pending_ending_id = resolved
			_show_dialogue([
				"A.",
				"The mind behind it all.",
				"The one who turned a grievance into a blueprint.",
				"But architects don't always lay the first stone.",
				"I'm missing something.",
			])
		"C":
			pending_ending_id = resolved
			_show_dialogue([
				"C.",
				"Poison in the glass. The most visible thread.",
				"Visible threads are usually there for a reason.",
				"I should know better.",
			])
		"H":
			pending_ending_id = resolved
			_show_dialogue([
				"H.",
				"The trap. The door.",
				"The trap at the door —",
				"who was it really built for?",
				"I'm letting it get personal.",
			])
		"self":
			pending_ending_id = resolved
			if resolved == "true_end":
				_show_dialogue([
					"Okay.",
					"R brought them here.",
					"A made the shape of it logical.",
					"C made the glass possible.",
					"H made the door final.",
					"And I gave them the language of investigation.",
					"What a locked room asks.",
					"What a detective ignores first.",
					"What looks like proof when fear needs a culprit.",
					"I came here to find a killer.",
					"I found a system.",
					"And my fingerprints on the instructions.",
				])
			else:
				_show_dialogue([
					"I don't know who did this.",
					"I know I'm here.",
					"I know they're not.",
					"I know I can't explain",
					"why I'm the one still in this room.",
					"...that's not nothing, actually.",
					"That might be the whole answer",
					"and I just don't like it.",
				])

# ═════════════════════════════════════════
#  ENDINGS
# ═════════════════════════════════════════
func _show_ending(ending_id: String) -> void:
	game_state = GameState.ENDING
	movement_locked        = true
	end_overlay.visible    = true
	dialogue_panel.visible = false
	verdict_panel.visible  = false
	
	if ending_id == "good_end_1":
		route["good_R_seen"] = true
		ng_plus = true
	
	var texts := EndingTexts.new().text_for(ending_id)
	end_title.text = texts["title"]
	end_body.text = texts["body"]
	end_restart_button.text = texts["button"]
	
	_save_checkpoint()
