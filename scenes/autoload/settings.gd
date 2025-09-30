extends Node

const DEFAULT_WINDOW_RES: int = 192
const RESIZE_WAIT_DELAY: float = 1.5

const SAVE_PATH: String = "user://settings.save"
const FULLSCREEN_IS_BORDERLESS: bool = true

const MASTER_BUS_NAME: String = "Master"
const SFX_BUS_NAME: String = "SFX"
const MUSIC_BUS_NAME: String = "Music"
const AMBIENCE_BUS_NAME: String = "Ambience"

signal locale_changed

var locale: StringName = &"en"
var master_volume_linear: float = 0.75
var music_volume_linear: float = 0.75
var sfx_volume_linear: float = 0.75
var ambience_volume_linear: float = 0.75
var sensitivity: float = 1.0
var fullscreen_active: bool = false
var is_debug_mode_available: bool
var window_size: Vector2i = Vector2i(DEFAULT_WINDOW_RES * 4, DEFAULT_WINDOW_RES * 4)

var viewport_size_dirty: bool = false
var timer: Timer = null

func _ready() -> void:
	is_debug_mode_available = Util.is_debug_mode_allowed()
	load_from_file()
	apply_values()

func reset_to_defaults(do_save: bool = true) -> void:
	set_locale(&"en", false)
	set_master_volume(0.75, false)
	set_music_volume(0.75, false)
	set_sfx_volume(0.75, false)
	set_ambience_volume(0.75, false)
	set_fullscreen_active(false, false)
	set_mouse_sensitivity(1.0, false)
	set_debug_mode_available(Util.is_debug_mode_allowed(), false)
	update_window_size(Vector2i(DEFAULT_WINDOW_RES * 4, DEFAULT_WINDOW_RES * 4))
	
	apply_values()
	if do_save:
		save_to_file()

func apply_values() -> void:
	TranslationServer.set_locale(locale)
	get_window().size = window_size
	
	Util.set_bus_volume(MASTER_BUS_NAME, master_volume_linear)
	Util.set_bus_volume(SFX_BUS_NAME, music_volume_linear)
	Util.set_bus_volume(MUSIC_BUS_NAME, sfx_volume_linear)
	Util.set_bus_volume(AMBIENCE_BUS_NAME, ambience_volume_linear)
	Util.set_fullscreen(fullscreen_active)
		
func save_to_file() -> void:
	var settings_file_access: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var save_dict: Dictionary = {
		"master_volume": master_volume_linear,
		"music_volume": music_volume_linear,
		"sfx_volume": sfx_volume_linear,
		"ambience_volume": ambience_volume_linear,
		"locale": locale,
		"fullscreen_active": fullscreen_active,
		#"window_size": var_to_str(window_size),
		"is_debug_mode_available": is_debug_mode_available
	}
	
	var json_string: String = JSON.stringify(save_dict)
	settings_file_access.store_line(json_string)
	

func load_from_file() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var save_game: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string: String = save_game.get_line()
		var json: JSON = JSON.new()
		var parseResult: Error = json.parse(json_string)
		if not parseResult == OK:
			push_warning("Preferences: JSON Parse Error: '" + json.get_error_message() + "'  at line " + str(json.get_error_line()))
			continue
		var save_dict: Dictionary = json.get_data()
##
		if save_dict.has("master_volume"):
			master_volume_linear = save_dict["master_volume"]
		if save_dict.has("music_volume"):
			music_volume_linear = save_dict["music_volume"]
		if save_dict.has("sfx_volume"):
			sfx_volume_linear = save_dict["sfx_volume"]
		if save_dict.has("ambience_volume"):
			ambience_volume_linear = save_dict["ambience_volume"]
		if save_dict.has("locale"):
			locale = save_dict["locale"]
		if save_dict.has("fullscreen_active"):
			fullscreen_active = save_dict["fullscreen_active"]
		#if save_dict.has("window_size"):
		#	window_size = str_to_var(save_dict["window_size"])
		if save_dict.has("is_debug_mode_available"):
			is_debug_mode_available = is_debug_mode_available || save_dict["is_debug_mode_available"]
			
func set_locale(locale_new: StringName, do_save: bool = true) -> void:
	locale = locale_new
	locale_changed.emit()

	if do_save:
		save_to_file()

		
func set_master_volume(volume_linear_new: float, do_save: bool = true) -> void:
	master_volume_linear = volume_linear_new

	if do_save:
		save_to_file()
		
func set_music_volume(volume_linear_new: float, do_save: bool = true) -> void:
	music_volume_linear = volume_linear_new
	
	if do_save:
		save_to_file()
		
func set_sfx_volume(volume_linear_new: float, do_save: bool = true) -> void:
	sfx_volume_linear = volume_linear_new
	
	if do_save:
		save_to_file()
		
func set_ambience_volume(volume_linear_new: float, do_save: bool = true) -> void:
	ambience_volume_linear = volume_linear_new
	
	if do_save:
		save_to_file()
		
func set_fullscreen_active(fs_active_new: bool, do_save: bool = true) -> void:
	fullscreen_active = fs_active_new
	
	if do_save:
		save_to_file()

func set_debug_mode_available(is_debug_mode_available_new: bool, do_save: bool = true) -> void:
	is_debug_mode_available = is_debug_mode_available_new
	
	if do_save:
		save_to_file()

func set_mouse_sensitivity(sensitivity_new: float, do_save: bool = true) -> void:
	sensitivity = sensitivity_new
	
	if do_save:
		save_to_file()

func update_window_size(window_size_new: Vector2i, do_save: bool = true) -> void:
	window_size = window_size_new
	
	if do_save:
		save_to_file()
#
#func save_current_window() -> void:
	#update_window_size(get_window().size, true)
