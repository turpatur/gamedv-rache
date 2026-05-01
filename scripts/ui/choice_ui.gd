extends Control
class_name ChoiceUI

signal option_selected(index: int)

@export var options_container_path: NodePath

var options_container: VBoxContainer
var buttons: Array[Button] = []


func _ready() -> void:
	visible = false

	if options_container_path != NodePath():
		options_container = get_node_or_null(options_container_path) as VBoxContainer

	if options_container == null:
		options_container = find_child("OptionsContainer", true, false) as VBoxContainer

	if options_container == null:
		push_error("ChoiceUI needs a VBoxContainer named OptionsContainer.")
		return

	buttons.clear()

	for child in options_container.get_children():
		if child is Button:
			var button := child as Button
			var index := buttons.size()
			button.visible = false
			button.pressed.connect(_on_button_pressed.bind(index))
			buttons.append(button)


func show_choices(options: Array) -> void:
	visible = true
	_ensure_button_count(options.size())

	for i in range(buttons.size()):
		if i < options.size():
			var option: Dictionary = options[i] as Dictionary
			buttons[i].text = String(option.get("label", ""))
			buttons[i].visible = true
			buttons[i].disabled = false
		else:
			buttons[i].visible = false


func hide_choices() -> void:
	visible = false

	for button in buttons:
		button.visible = false


func _on_button_pressed(index: int) -> void:
	hide_choices()
	option_selected.emit(index)


func _ensure_button_count(count: int) -> void:
	if options_container == null:
		return
	while buttons.size() < count:
		var source := buttons[buttons.size() - 1] if not buttons.is_empty() else Button.new()
		var button := source.duplicate(0) as Button
		var index := buttons.size()
		button.visible = false
		button.pressed.connect(_on_button_pressed.bind(index))
		options_container.add_child(button)
		buttons.append(button)
