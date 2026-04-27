extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION_GAMEPLAY: String = "gameplay"
const SECTION_AUDIO: String = "audio"
const SECTION_SAVE: String = "save"
const SECTION_BINDINGS: String = "bindings"

const MIN_AUTOSAVE_SECONDS: int = 5
const MAX_AUTOSAVE_SECONDS: int = 300

const REBINDABLE_ACTIONS: PackedStringArray = [
	"move_left",
	"move_right",
	"move_up",
	"move_down",
	"attack",
	"level_up",
	"toggle_settings",
	"quit",
]

const DEFAULT_BINDINGS: Dictionary = {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
	"attack": KEY_F,
	"level_up": KEY_R,
	"toggle_settings": KEY_M,
	"quit": KEY_ESCAPE,
}

signal settings_changed
signal keybind_changed(action_name: StringName)

var auto_level_enabled: bool = true
var tutorial_disabled: bool = false
var fullscreen_enabled: bool = false

var master_volume_scale: float = 1.0
var sound_volume_scale: float = 1.0
var music_volume_scale: float = 0.8
var sfx_volume_scale: float = 1.0

var autosave_interval_seconds: int = 12


func _ready() -> void:
	_load_settings()
	_apply_all_settings()


func apply_and_save() -> void:
	_apply_all_settings()
	_save_settings()
	settings_changed.emit()


func get_rebind_actions() -> PackedStringArray:
	return REBINDABLE_ACTIONS


func get_primary_keycode(action_name: StringName) -> int:
	var action_text: String = String(action_name)
	var event := _get_primary_key_event(action_text)
	if event != null:
		return int(event.physical_keycode)
	return int(DEFAULT_BINDINGS.get(action_text, KEY_NONE))


func rebind_action(action_name: StringName, physical_keycode: int) -> bool:
	var action_text: String = String(action_name)
	if REBINDABLE_ACTIONS.has(action_text) == false:
		return false
	if physical_keycode == KEY_NONE:
		return false

	if InputMap.has_action(action_text) == false:
		return false

	for input_event in InputMap.action_get_events(action_text):
		if input_event is InputEventKey:
			InputMap.action_erase_event(action_text, input_event)

	var key_event := InputEventKey.new()
	key_event.physical_keycode = physical_keycode as Key
	InputMap.action_add_event(action_text, key_event)
	_save_settings()
	keybind_changed.emit(action_name)
	settings_changed.emit()
	return true


func reset_to_defaults() -> void:
	auto_level_enabled = true
	tutorial_disabled = false
	fullscreen_enabled = false
	master_volume_scale = 1.0
	sound_volume_scale = 1.0
	music_volume_scale = 0.8
	sfx_volume_scale = 1.0
	autosave_interval_seconds = 12

	for action_name in REBINDABLE_ACTIONS:
		rebind_action(StringName(action_name), int(DEFAULT_BINDINGS.get(action_name, KEY_NONE)))

	apply_and_save()


func _apply_all_settings() -> void:
	_apply_audio_settings()
	_apply_window_settings()
	_apply_autosave_settings()


func _apply_audio_settings() -> void:
	_set_bus_volume_by_scale(&"Master", master_volume_scale)
	_set_bus_volume_by_scale(&"Music", sound_volume_scale * music_volume_scale)
	_set_bus_volume_by_scale(&"SFX", sound_volume_scale * sfx_volume_scale)


func _apply_window_settings() -> void:
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_autosave_settings() -> void:
	autosave_interval_seconds = clampi(autosave_interval_seconds, MIN_AUTOSAVE_SECONDS, MAX_AUTOSAVE_SECONDS)
	if Utils != null and Utils.has_method("set_autosave_delay_seconds"):
		Utils.set_autosave_delay_seconds(float(autosave_interval_seconds))


func _set_bus_volume_by_scale(bus_name: StringName, scale_value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return

	var safe_scale: float = clampf(scale_value, 0.0, 1.0)
	var db_value: float = -80.0 if safe_scale <= 0.001 else linear_to_db(safe_scale)
	AudioServer.set_bus_volume_db(bus_index, db_value)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	auto_level_enabled = bool(config.get_value(SECTION_GAMEPLAY, "auto_level_enabled", auto_level_enabled))
	tutorial_disabled = bool(config.get_value(SECTION_GAMEPLAY, "tutorial_disabled", tutorial_disabled))
	fullscreen_enabled = bool(config.get_value(SECTION_GAMEPLAY, "fullscreen_enabled", fullscreen_enabled))

	master_volume_scale = clampf(float(config.get_value(SECTION_AUDIO, "master_volume_scale", master_volume_scale)), 0.0, 1.0)
	sound_volume_scale = clampf(float(config.get_value(SECTION_AUDIO, "sound_volume_scale", sound_volume_scale)), 0.0, 1.0)
	music_volume_scale = clampf(float(config.get_value(SECTION_AUDIO, "music_volume_scale", music_volume_scale)), 0.0, 1.0)
	sfx_volume_scale = clampf(float(config.get_value(SECTION_AUDIO, "sfx_volume_scale", sfx_volume_scale)), 0.0, 1.0)

	autosave_interval_seconds = clampi(int(config.get_value(SECTION_SAVE, "autosave_interval_seconds", autosave_interval_seconds)), MIN_AUTOSAVE_SECONDS, MAX_AUTOSAVE_SECONDS)

	for action_name in REBINDABLE_ACTIONS:
		var keycode: int = int(config.get_value(SECTION_BINDINGS, action_name, int(DEFAULT_BINDINGS.get(action_name, KEY_NONE))))
		rebind_action(StringName(action_name), keycode)


func _save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value(SECTION_GAMEPLAY, "auto_level_enabled", auto_level_enabled)
	config.set_value(SECTION_GAMEPLAY, "tutorial_disabled", tutorial_disabled)
	config.set_value(SECTION_GAMEPLAY, "fullscreen_enabled", fullscreen_enabled)

	config.set_value(SECTION_AUDIO, "master_volume_scale", master_volume_scale)
	config.set_value(SECTION_AUDIO, "sound_volume_scale", sound_volume_scale)
	config.set_value(SECTION_AUDIO, "music_volume_scale", music_volume_scale)
	config.set_value(SECTION_AUDIO, "sfx_volume_scale", sfx_volume_scale)

	config.set_value(SECTION_SAVE, "autosave_interval_seconds", autosave_interval_seconds)

	for action_name in REBINDABLE_ACTIONS:
		config.set_value(SECTION_BINDINGS, action_name, get_primary_keycode(StringName(action_name)))

	config.save(SETTINGS_PATH)


func _get_primary_key_event(action_name: String) -> InputEventKey:
	if InputMap.has_action(action_name) == false:
		return null

	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventKey:
			return input_event as InputEventKey

	return null
