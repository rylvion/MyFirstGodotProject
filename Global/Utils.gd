extends Node

const SAVE_PATH := "user://savegame.bin"
const DEFAULT_AUTOSAVE_DELAY_SECONDS := 12.0

var _autosave_dirty: bool = false
var _is_loading: bool = false
var _autosave_timer: Timer
var _autosave_delay_seconds: float = DEFAULT_AUTOSAVE_DELAY_SECONDS


func _ready() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.one_shot = true
	_autosave_timer.wait_time = _autosave_delay_seconds
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)
	_connect_game_signals()


func set_autosave_delay_seconds(delay_seconds: float) -> void:
	_autosave_delay_seconds = clampf(delay_seconds, 5.0, 300.0)
	if _autosave_timer == null:
		return

	_autosave_timer.wait_time = _autosave_delay_seconds
	if _autosave_dirty and _autosave_timer.is_stopped():
		_autosave_timer.start()


func get_autosave_delay_seconds() -> float:
	return _autosave_delay_seconds


func saveGame() -> void:
	if _autosave_timer != null and not _autosave_timer.is_stopped():
		_autosave_timer.stop()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing")
		return

	var data: Dictionary = {
		"game_version": Game.GAME_VERSION,
		"save_schema": Game.SAVE_SCHEMA_VERSION,
		"playerHP": Game.playerHP,
		"gold": Game.gold,
		"level": Game.level,
		"maxHP": Game.maxHP,
		"wins": Game.wins,
		"last_victory_wave": Game.last_victory_wave,
		"tutorial_progress": Game.get_tutorial_progress_data(),
		"tutorial_attack_done": Game.tutorial_attack_done,
		"tutorial_stomp_done": Game.tutorial_stomp_done,
		"tutorial_level_done": Game.tutorial_level_done
	}

	file.store_string(JSON.stringify(data))
	file.close()
	_autosave_dirty = false


func loadGame() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading")
		return

	var text := file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(text)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		push_error("Save file corrupted")
		return

	_is_loading = true

	var loaded_level: int = max(int(data.get("level", 1)), 1)
	Game.level = loaded_level
	Game.gold = float(data.get("gold", 0.0))
	Game.playerHP = int(data.get("playerHP", Game.maxHP))
	Game.wins = max(int(data.get("wins", 0)), 0)
	Game.last_victory_wave = max(int(data.get("last_victory_wave", 0)), 0)
	if typeof(data.get("tutorial_progress", null)) == TYPE_DICTIONARY:
		Game.load_tutorial_progress(data.get("tutorial_progress", {}))
	else:
		Game.load_legacy_tutorial_progress(
			bool(data.get("tutorial_attack_done", false)),
			bool(data.get("tutorial_stomp_done", false)),
			bool(data.get("tutorial_level_done", false))
		)

	_is_loading = false
	_autosave_dirty = false
	if _autosave_timer != null and not _autosave_timer.is_stopped():
		_autosave_timer.stop()


func queue_autosave() -> void:
	if _is_loading:
		return

	_autosave_dirty = true
	if _autosave_timer != null and _autosave_timer.is_stopped():
		_autosave_timer.start()


func _connect_game_signals() -> void:
	if not Game.gold_changed.is_connected(_on_gold_changed):
		Game.gold_changed.connect(_on_gold_changed)
	if not Game.hp_changed.is_connected(_on_hp_changed):
		Game.hp_changed.connect(_on_hp_changed)
	if not Game.max_hp_changed.is_connected(_on_max_hp_changed):
		Game.max_hp_changed.connect(_on_max_hp_changed)
	if not Game.level_changed.is_connected(_on_level_changed):
		Game.level_changed.connect(_on_level_changed)
	if not Game.tutorial_progress_changed.is_connected(_on_tutorial_progress_changed):
		Game.tutorial_progress_changed.connect(_on_tutorial_progress_changed)


func _on_gold_changed(_new_gold: float) -> void:
	queue_autosave()


func _on_hp_changed(_new_hp: int) -> void:
	queue_autosave()


func _on_max_hp_changed(_new_max_hp: int) -> void:
	queue_autosave()


func _on_level_changed(_new_level: int) -> void:
	queue_autosave()


func _on_tutorial_progress_changed() -> void:
	queue_autosave()


func _on_autosave_timeout() -> void:
	if _autosave_dirty:
		saveGame()
