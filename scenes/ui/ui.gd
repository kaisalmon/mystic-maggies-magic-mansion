class_name UI
extends CanvasLayer

var default_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED

signal current_text_finished

@export_category("internal nodes")
@export var pause_overlay: PauseMenuUI
@export var magic_value_label: Label
@export var magic_label_text: Label

@export var magic_value_label_cozy: Label
@export var magic_value_label_hollow: Label
@export var magic_value_label_vivid: Label
@export var magic_value_label_windy: Label

@export var textbox_container: MarginContainer
@export var text_start: Label
@export var text_main: Label 
@export var text_end: Label

@export var debug_mode_ui: DebugModeUI

@export var autosave_label: Label
@export var autosave_timer: Timer
@export var magic_view: MarginContainer

var music_fade_tween: Tween = null
var music_mono_tween: Tween = null

var text_animate_tween: Tween = null

var is_debug_mode_active: bool = false
var is_on_pause_screen: bool = false
var autosave_available: bool = true
var in_cutscene: bool = false

var magic_view_invisible_y_pos: float = -30
var magic_view_visible_y_pos: float = 0
var magic_fade_tween: Tween
var current_interactable: Interactable = null
var is_magic_visible: bool = false

func _ready() -> void:
	translate_label()
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	GameState.ui = self
	set_pause_screen_active(false)
	hide_textbox()
	set_debug_mode_active(false, false)
	autosave_label.modulate.a = 0.0
	Settings.locale_changed.connect(translate_label)
	
	for type: Recipe.MagicType in Recipe.MagicType.values():
		set_magic_amount(type, 0)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_pause_screen_active(!is_on_pause_screen)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else default_mouse_mode
		
	if event.is_action_pressed("text_accept"):
		hide_textbox()
		
	if event.is_action_pressed("debug_mode"):
		set_debug_mode_active(!is_debug_mode_active)
		
		
func set_debug_mode_active(is_debug_mode_active_new: bool, change_paused: bool = true) -> void:
	is_debug_mode_active = is_debug_mode_active_new
	if change_paused:
		set_paused(is_debug_mode_active_new || is_on_pause_screen)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else default_mouse_mode

	if is_debug_mode_active_new && !Settings.is_debug_mode_available:
		return

	debug_mode_ui.visible = is_debug_mode_active_new
	if is_debug_mode_active:
		debug_mode_ui.show_only_main_debug_view()
		
func set_pause_screen_active(is_paused_new: bool) -> void:
	Util.set_paused_audio_effect(is_paused_new, self)

	is_on_pause_screen = is_paused_new
	set_paused(is_paused_new|| is_debug_mode_active)
	pause_overlay.visible = is_paused_new
	pause_overlay.show_pause_menu()
	
	if is_paused_new && autosave_available:
		do_autosave()


func set_paused(is_paused_new: bool) -> void:
	get_tree().paused = is_paused_new
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else default_mouse_mode

func set_magic_amount(type: Recipe.MagicType, magic_amount_new: int) -> void:
	get_label_by_type(type).text = str(magic_amount_new)

func get_label_by_type(magic_type: Recipe.MagicType) -> Label:
	match magic_type:
		Recipe.MagicType.COZY:
			return magic_value_label_cozy
		Recipe.MagicType.HOLLOW:
			return magic_value_label_hollow
		Recipe.MagicType.VIVID:
			return magic_value_label_vivid
		Recipe.MagicType.WINDY:
			return magic_value_label_windy	
	push_warning("no implementation found for UI.get_label_by_type() with type: ", Recipe.MagicType.keys()[magic_type])
	return null

func hide_textbox() -> void:
	text_start.text = ""
	text_main.text = ""
	text_end.text = ""
	textbox_container.hide()
	text_main.visible_ratio = 0
	current_text_finished.emit()

func show_textbox() -> void:
	text_start.text = ""
	textbox_container.show()
	
func show_text(next_text_to_show: String) -> void:
	var text_show_duration: float = clamp(next_text_to_show.length() * 0.04, 1.5, 3.0)
	text_main.text = next_text_to_show
	show_textbox()
	text_animate_tween = create_tween()
	text_animate_tween.tween_property(text_main, "visible_ratio", 1, text_show_duration)
	await text_animate_tween.finished
	await get_tree().create_timer(1.0).timeout

	hide_textbox()
	

func do_autosave() -> void:
	SaveGame.save_to_file()
	#Settings.save_current_window_size()
	autosave_available = false
	autosave_timer.start()
	
	var autosave_start_y_pos: float = autosave_label.position.y
	autosave_label.modulate.a = 0.0

	var autosave_tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CIRC)
	autosave_tween.tween_property(autosave_label, "position:y", autosave_start_y_pos - 20, 0.4)
	autosave_tween.tween_property(autosave_label, "modulate:a", 1.0, 0.6)
	
	await autosave_tween.finished
	await get_tree().create_timer(2.0).timeout
	autosave_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CIRC)
	autosave_tween.tween_property(autosave_label, "position:y", autosave_start_y_pos, 0.5)
	autosave_tween.tween_property(autosave_label, "modulate:a", 0.0, 0.4)
	
func _on_pause_overlay_unpause_requested() -> void:
	set_pause_screen_active(false)

func _on_autosave_timer_timeout() -> void:
	autosave_available = true

func show_dialogue_by_door(room_type: GameState.RoomType) -> void:
	if room_type == GameState.RoomType.LIBRARY || room_type == GameState.RoomType.NONE || room_type == GameState.RoomType.MAIN_ROOM:
		return
	
	await get_tree().create_timer(1.0).timeout
	show_text(tr("dialogue.unlock_room."+(GameState.RoomType.keys()[room_type] as String).to_lower()))
	
func _process(delta: float) -> void:
	if not in_cutscene:
		return
	$CutsceneBars/TopBar.position.y = lerp($CutsceneBars/TopBar.position.y, 0.0, delta * 2)
	$CutsceneBars/BottomBar.position.y = lerp($CutsceneBars/BottomBar.position.y, 192.0 - 42.0, delta * 2)

func translate_label() -> void:
	magic_label_text.text = tr("ui.magic")

func set_magic_ui_fade_in(is_fade_in: bool) -> void:
	if(is_instance_valid(magic_fade_tween)):
		magic_fade_tween.kill()
		
	var target_y_pos: float = magic_view_visible_y_pos if is_fade_in else magic_view_invisible_y_pos
	var target_alpha: float = 1.0 if is_fade_in else 0.0
	
	var subtween: Tween = create_tween().set_parallel()
	subtween.tween_property(magic_view, "position:y", target_y_pos, 0.5)
	subtween.tween_property(magic_view, "modulate:a", target_alpha, 0.4)
		
	magic_fade_tween = create_tween().set_trans(Tween.TRANS_QUAD)
	magic_fade_tween.tween_interval(0.2 if is_fade_in else 0.8)
	magic_fade_tween.tween_subtween(subtween)
	
func set_interactable_highlighted(interactable: Interactable, is_highlighted_new: bool) -> void:
	if !(interactable is ItemConsumer || interactable is RoomExpander):
		return

	if !is_highlighted_new && interactable != null && current_interactable != interactable:
		return
	
	if !is_highlighted_new:
		current_interactable = null
	else:
		current_interactable = interactable
	
	validate_magic_visible()	

func validate_magic_visible() -> void:
	var is_magic_visible_new: bool = false
	if current_interactable != null || GameState.num_orbs_in_world > 0:
		is_magic_visible_new = true	
		
	if is_magic_visible == is_magic_visible_new:
		return
	is_magic_visible = is_magic_visible_new
	set_magic_ui_fade_in(is_magic_visible_new)
