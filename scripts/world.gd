extends Node2D

@onready var spawner: EnemySpawner = $EnemySpawner
@onready var quit_dialog: ConfirmationDialog = $UI/QuitDialog
@onready var victory_dialog: AcceptDialog = $UI/VictoryDialog
@onready var command_bar: ColorRect = $UI/CommandBar
@onready var command_input: LineEdit = $UI/CommandBar/CommandInput
@onready var command_feedback: Label = $UI/CommandFeedback

var _victory_shown: bool = false


func _ready() -> void:
	print("Tiny Quest ", Game.GAME_VERSION)
	quit_dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if quit_dialog.confirmed.is_connected(_on_quit_dialog_confirmed) == false:
		quit_dialog.confirmed.connect(_on_quit_dialog_confirmed)
	if quit_dialog.canceled.is_connected(_on_quit_dialog_canceled) == false:
		quit_dialog.canceled.connect(_on_quit_dialog_canceled)
	if quit_dialog.close_requested.is_connected(_on_quit_dialog_canceled) == false:
		quit_dialog.close_requested.connect(_on_quit_dialog_canceled)
	victory_dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if victory_dialog.confirmed.is_connected(_on_victory_dialog_confirmed) == false:
		victory_dialog.confirmed.connect(_on_victory_dialog_confirmed)
	if spawner != null and spawner.wave_completed.is_connected(_on_wave_completed) == false:
		spawner.wave_completed.connect(_on_wave_completed)
	command_bar.visible = false
	command_feedback.visible = false
	Game.input_blocked = false
	if command_input.text_submitted.is_connected(_on_command_submitted) == false:
		command_input.text_submitted.connect(_on_command_submitted)
	call_deferred("_show_startup_time_feedback")


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and (key_event.keycode == KEY_QUOTELEFT or key_event.keycode == KEY_F1):
			_toggle_command_bar()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if command_bar.visible:
		if event.is_action_pressed("quit"):
			_hide_command_bar()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("quit") == false:
		return

	get_viewport().set_input_as_handled()
	if quit_dialog.visible:
		return

	if spawner != null and spawner.wave_number >= 5:
		get_tree().paused = true
		quit_dialog.popup_centered()
		return

	_exit_to_main_menu()


func _on_quit_dialog_confirmed() -> void:
	_exit_to_main_menu()


func _on_quit_dialog_canceled() -> void:
	get_tree().paused = false


func _on_victory_dialog_confirmed() -> void:
	_exit_to_main_menu()


func _exit_to_main_menu() -> void:
	get_tree().paused = false
	Utils.saveGame()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _toggle_command_bar() -> void:
	if command_bar.visible:
		_hide_command_bar()
		return

	command_bar.visible = true
	Game.input_blocked = true
	command_input.clear()
	command_input.grab_focus()


func _hide_command_bar() -> void:
	command_bar.visible = false
	command_input.release_focus()
	call_deferred("_release_command_input_block")


func _on_command_submitted(command_text: String) -> void:
	get_viewport().set_input_as_handled()
	var trimmed_command: String = command_text.strip_edges()
	command_input.clear()
	_hide_command_bar()
	if trimmed_command.is_empty():
		return

	_execute_command(trimmed_command)


func _execute_command(command_text: String) -> void:
	var parts: PackedStringArray = command_text.split(" ", false)
	if parts.is_empty():
		return

	var command: String = parts[0].to_lower()
	match command:
		"wave":
			if parts.size() < 2 or parts[1].is_valid_int() == false:
				_show_command_feedback("Usage: wave <number>", true)
				return
			var target_wave: int = max(parts[1].to_int(), 1)
			spawner.force_wave(target_wave)
			_show_command_feedback("Jumped to wave %d" % target_wave)
		"boss":
			var target_boss_wave: int = 10
			if spawner != null and spawner.wave_number >= 10:
				target_boss_wave = int(ceil(float(spawner.wave_number + 1) / 10.0)) * 10
			spawner.force_wave(target_boss_wave)
			_show_command_feedback("Jumped to boss wave %d" % target_boss_wave)
		"gold":
			if parts.size() < 2 or parts[1].is_valid_float() == false:
				_show_command_feedback("Usage: gold <amount>", true)
				return
			Game.gold = parts[1].to_float()
			_show_command_feedback("Gold set to %d" % int(Game.gold))
		"level":
			if parts.size() < 2 or parts[1].is_valid_int() == false:
				_show_command_feedback("Usage: level <number>", true)
				return
			Game.level = max(parts[1].to_int(), 1)
			_show_command_feedback("Level set to %d" % Game.level)
		"heal":
			Game.playerHP = Game.maxHP
			_show_command_feedback("Player healed to full")
		"clear":
			spawner.clear_all_enemies()
			_show_command_feedback("Cleared active enemies")
		"help":
			_show_command_feedback("Commands: wave <n>, boss, gold <n>, level <n>, heal, clear")
		_:
			_show_command_feedback("Unknown command: %s" % command, true)


func _show_command_feedback(message: String, is_error: bool = false) -> void:
	command_feedback.text = message
	command_feedback.modulate = Color(1.0, 0.75, 0.75, 1.0) if is_error else Color(0.95, 1.0, 0.82, 1.0)
	command_feedback.visible = true
	var tween: Tween = create_tween()
	command_feedback.modulate.a = 1.0
	tween.tween_interval(1.8)
	tween.tween_property(command_feedback, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	command_feedback.visible = false


func _release_command_input_block() -> void:
	await get_tree().process_frame
	Game.input_blocked = false


func _on_wave_completed(completed_wave: int) -> void:
	if _victory_shown:
		return
	if spawner == null:
		return

	var healed_hp: int = Game.apply_wave_completion_heal(completed_wave)
	if healed_hp > 0:
		var heal_label: String = "Boss clear heal +%d HP" if completed_wave % 10 == 0 else "Wave clear heal +%d HP"
		_show_command_feedback(heal_label % healed_hp)

	var max_wave: int = int(spawner.get_stats().get("max_wave", 30))
	if completed_wave < max_wave:
		return

	_victory_shown = true
	Game.record_victory(completed_wave)
	Game.input_blocked = true
	get_tree().paused = true
	victory_dialog.dialog_text = "You beat the game by clearing Wave %d! Total wins: %d" % [completed_wave, Game.wins]
	victory_dialog.popup_centered()


func _show_startup_time_feedback() -> void:
	var startup_msec: int = Game.consume_startup_timer_msec()
	if startup_msec < 0:
		return
	print("Loaded in %d ms" % startup_msec)
