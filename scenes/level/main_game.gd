extends Node3D

var fadein_time = 0.8
var timer = 0.0
var fadeout_timer = 0.0

func _ready() -> void:
	$CanvasLayer/Fadeout.color.a = 1.0
	_late_ready.call_deferred()
	GameState.new_door_unlocked.connect(show_ending)
	GameState.is_ending = false

func _late_ready() -> void:
	var has_loaded = false
	if GameState.load_game_at_start:
		has_loaded = load_game()
	if !has_loaded:
		show_intro()
	
func load_game() -> bool:
	return SaveGame.load_from_file()
	
func save_game() -> void:
	SaveGame.save_to_file()
	#Settings.save_current_window_size()
	
func _process(delta: float) -> void:
	if timer < fadein_time and not GameState.is_ending:
		timer += delta
		$CanvasLayer/Fadeout.color.a = lerp(1.0, 0.0, timer / fadein_time)
	if GameState.is_ending:
		fadeout_timer += delta
		$CanvasLayer/Fadeout.color.a = lerp(0.0, 1.0, fadeout_timer / fadein_time)

func show_intro() -> void:
	await get_tree().create_timer(2.0).timeout
	GameState.ui.show_text(tr("dialogue.intro.1"))


func show_ending(_numdoors: int, room_type:GameState.RoomType) -> void:
	if room_type == GameState.RoomType.LIBRARY:
		await get_tree().create_timer(3.0).timeout
		GameState.ui.show_text(tr("dialogue.ending.1"))
