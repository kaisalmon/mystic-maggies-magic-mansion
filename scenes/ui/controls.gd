class_name ControlsUI
extends MarginContainer

signal back_pressed

@onready var move_up_button: Button = $VBoxContainer/HBoxContainer/MoveUpButton
@onready var move_down_button: Button = $VBoxContainer/HBoxContainer2/MoveDownButton
@onready var move_left_button: Button = $VBoxContainer/HBoxContainer3/MoveLeftButton
@onready var move_right_button: Button = $VBoxContainer/HBoxContainer4/MoveRightButton
@onready var interact_button: Button = $VBoxContainer/HBoxContainer5/InteractButton
@onready var drop_button: Button = $VBoxContainer/HBoxContainer6/DropButton
@onready var unstuck_button: Button = $VBoxContainer/HBoxContainer7/UnstuckButton

var waiting_for_reassignment: bool = false
var reassign_button: Button = null
var input_reassignment_key: String = "move_up"

func _ready() -> void:
	update_input_names()
	
func update_input_names() -> void:
	update_button(move_up_button, get_first_input_for("move_up"))
	update_button(move_down_button, get_first_input_for("move_down"))
	update_button(move_left_button, get_first_input_for("move_left"))
	update_button(move_right_button, get_first_input_for("move_right"))
	update_button(interact_button, get_first_input_for("interact"))
	update_button(unstuck_button, get_first_input_for("unstuck"))
	update_button(drop_button, get_first_input_for("drop_item"))

func _on_move_up_button_pressed() -> void:
	start_reassignment("move_up", move_up_button)

func _on_move_down_button_pressed() -> void:
	start_reassignment("move_down", move_down_button)

func _on_move_left_button_pressed() -> void:
	start_reassignment("move_left", move_left_button)

func _on_move_right_button_pressed() -> void:
	start_reassignment("move_right", move_right_button)

func _on_interact_button_pressed() -> void:
	start_reassignment("interact", interact_button)

func _on_unstuck_button_pressed() -> void:
	start_reassignment("unstuck", unstuck_button)

func _on_drop_button_pressed() -> void:
	start_reassignment("drop_item", drop_button)

func start_reassignment(input_key: String, button: Button) -> void:
	waiting_for_reassignment = true
	input_reassignment_key = input_key
	reassign_button = button
	reassign_button.text = "press a button"
	
func stop_reassignment() -> void:
	waiting_for_reassignment = false

func _input(in_event: InputEvent) -> void:
	if !waiting_for_reassignment:
		return
	
	get_viewport().set_input_as_handled()
	
	if in_event is InputEventKey && (in_event as InputEventKey).pressed && (in_event as InputEventKey).keycode == KEY_ESCAPE:
		stop_reassignment()
		return
		
	if in_event is InputEventMouseMotion:
		return
		
	if in_event is InputEventJoypadMotion:
		return
		
		#var in_joy_motion_event: InputEventJoypadMotion = in_event as InputEventJoypadMotion
		#if in_joy_motion_event.axis_value < 0.3:
		#	return

	update_input_map(input_reassignment_key, in_event)
	update_button(reassign_button, in_event)
	#get_viewport().set_input_as_handled() # needed?
	stop_reassignment()

func update_button(button: Button, new_key_event: InputEvent) -> void:
	if new_key_event == null:
		stop_reassignment()
		return
	
	if new_key_event is InputEventMouseButton:
		new_key_event.double_click = false
		button.text = (new_key_event as InputEventMouseButton).as_text()
	elif new_key_event is InputEventKey:
		var iek: InputEventKey = (new_key_event as InputEventKey)
		var keycode: int = iek.keycode
		if keycode == 0:
			keycode = DisplayServer.keyboard_get_keycode_from_physical(iek.physical_keycode)
		button.text = OS.get_keycode_string(keycode) #
	else:
		button.text = new_key_event.as_text_key_label()
		
func reset_inputs() -> void:
	InputMap.load_from_project_settings();
	update_input_names()


static func get_first_input_for(input_name: String) -> InputEvent:
	var input_events: Array[InputEvent] = InputMap.action_get_events(input_name);
	if input_events.size() == 0:
		return null
	
	return input_events[0];
	
static func update_input_map(input_key: String, input_event: InputEvent) -> void:
	var input_events: Array[InputEvent] = InputMap.action_get_events(input_key);
	if input_events.size() == 0:
		InputMap.action_add_event(input_key, input_event);
		return
		
	InputMap.action_erase_events(input_key)
	InputMap.action_add_event(input_key, input_event);
	for i: int in input_events.size():
		if i == 0:
			continue
		InputMap.action_add_event(input_key, input_events[i]);

func _on_reset_button_pressed() -> void:
	reset_inputs()

func _on_back_button_pressed() -> void:
	back_pressed.emit()
