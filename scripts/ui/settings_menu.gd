extends CanvasLayer

const REBIND_LABELS: Dictionary = {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"move_up": "Jump",
	"move_down": "Move Down",
	"attack": "Fireball",
	"level_up": "Level Up",
	"toggle_settings": "Toggle Settings",
	"quit": "Back / Quit",
}

var gear_button: Button
var panel_root: Panel
var panel_body: VBoxContainer
var status_label: Label
var pending_rebind_action: StringName = &""
var key_button_map: Dictionary = {}
var block_game_input: bool = false
var show_gear_button: bool = true
var toggle_keycode: int = KEY_M
var reset_progress_dialog: ConfirmationDialog
var _previous_tree_paused: bool = false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_refresh_from_settings()
	if not show_gear_button and gear_button != null:
		gear_button.visible = false


func _input(event: InputEvent) -> void:
	if pending_rebind_action != &"":
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if panel_root != null and panel_root.visible and key_event.ctrl_pressed and key_event.shift_pressed and key_event.physical_keycode == KEY_DELETE:
				Utils.reset_everyone_progress()
				set_menu_open(false)
				get_viewport().set_input_as_handled()
				return
			var toggle_pressed: bool = key_event.physical_keycode == toggle_keycode
			if not toggle_pressed and InputMap.has_action("toggle_settings"):
				toggle_pressed = event.is_action_pressed("toggle_settings")
			if toggle_pressed:
				toggle_menu()
				get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if panel_root == null or panel_root.visible == false:
		return

	if pending_rebind_action != &"":
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.pressed and not key_event.echo:
				if key_event.physical_keycode == KEY_ESCAPE:
					pending_rebind_action = &""
					status_label.text = "Rebind canceled."
					return

				var rebound: bool = SettingsManager.rebind_action(pending_rebind_action, key_event.physical_keycode)
				pending_rebind_action = &""
				if rebound:
					status_label.text = "Key updated."
					_update_keybind_labels()
				else:
					status_label.text = "Could not rebind action."
				get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("quit"):
		set_menu_open(false)
		get_viewport().set_input_as_handled()


func set_menu_open(is_open: bool) -> void:
	if panel_root == null:
		return

	var scene_tree := get_tree()
	if scene_tree != null:
		if is_open:
			_previous_tree_paused = scene_tree.paused
			scene_tree.paused = true
		else:
			scene_tree.paused = _previous_tree_paused

	panel_root.visible = is_open
	if is_open:
		pending_rebind_action = &""
		_refresh_from_settings()
		status_label.text = ""
	if block_game_input:
		Game.input_blocked = is_open


func is_menu_open() -> bool:
	return panel_root != null and panel_root.visible


func toggle_menu() -> void:
	set_menu_open(not is_menu_open())


func _build_ui() -> void:
	var gear_margin := MarginContainer.new()
	gear_margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gear_margin.offset_left = -72.0
	gear_margin.offset_top = 12.0
	gear_margin.offset_right = -12.0
	gear_margin.offset_bottom = 72.0
	add_child(gear_margin)

	gear_button = Button.new()
	gear_button.text = "[gear]"
	gear_button.custom_minimum_size = Vector2(60, 52)
	gear_button.tooltip_text = "Open settings"
	gear_button.add_theme_font_size_override("font_size", 22)
	gear_margin.add_child(gear_button)
	gear_button.pressed.connect(_on_gear_pressed)

	var panel_margin := MarginContainer.new()
	panel_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_margin.offset_left = 0.0
	panel_margin.offset_top = 0.0
	panel_margin.offset_right = 0.0
	panel_margin.offset_bottom = 0.0
	panel_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_margin)

	panel_root = Panel.new()
	panel_root.visible = false
	panel_root.custom_minimum_size = Vector2(620, 560)
	panel_root.set_anchors_preset(Control.PRESET_CENTER)
	panel_root.offset_left = -310.0
	panel_root.offset_top = -280.0
	panel_root.offset_right = 310.0
	panel_root.offset_bottom = 280.0
	panel_margin.add_child(panel_root)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.16, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.32, 0.78, 0.64, 0.9)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	panel_root.add_theme_stylebox_override("panel", style)

	var content_margin := MarginContainer.new()
	content_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_margin.offset_left = 18
	content_margin.offset_top = 18
	content_margin.offset_right = -18
	content_margin.offset_bottom = -18
	panel_root.add_child(content_margin)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_margin.add_child(scroll)

	panel_body = VBoxContainer.new()
	panel_body.add_theme_constant_override("separation", 10)
	panel_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_body.custom_minimum_size = Vector2(0, 760)
	scroll.add_child(panel_body)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 30)
	title.modulate = Color(0.92, 0.98, 0.97, 1.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_body.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Tune gameplay, controls, and audio"
	subtitle.modulate = Color(0.68, 0.85, 0.82, 1.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_body.add_child(subtitle)

	panel_body.add_child(_add_toggle_row("Auto Levelling", "Automatically spend gold on level ups.", "auto_level_enabled"))
	panel_body.add_child(_add_toggle_row("Disable Tutorial", "Hide tutorial hints in HUD.", "tutorial_disabled"))

	panel_body.add_child(_add_slider_row("Master Volume", "master_volume_scale"))
	panel_body.add_child(_add_slider_row("Sound Scale", "sound_volume_scale"))
	panel_body.add_child(_add_slider_row("Music Volume", "music_volume_scale"))
	panel_body.add_child(_add_slider_row("SFX Volume", "sfx_volume_scale"))

	panel_body.add_child(_add_autosave_row())
	panel_body.add_child(_add_keybind_section())
	panel_body.add_child(_add_actions_row())

	status_label = Label.new()
	status_label.modulate = Color(0.84, 0.93, 0.66, 1.0)
	status_label.text = ""
	panel_body.add_child(status_label)

	reset_progress_dialog = ConfirmationDialog.new()
	reset_progress_dialog.title = "Reset Progress?"
	reset_progress_dialog.dialog_text = "This will reset level, gold, wins, and tutorial progress. Continue?"
	reset_progress_dialog.ok_button_text = "Reset"
	reset_progress_dialog.cancel_button_text = "Cancel"
	reset_progress_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	var danger_style := StyleBoxFlat.new()
	danger_style.bg_color = Color(0.27, 0.07, 0.09, 0.96)
	danger_style.border_width_left = 2
	danger_style.border_width_top = 2
	danger_style.border_width_right = 2
	danger_style.border_width_bottom = 2
	danger_style.border_color = Color(0.95, 0.22, 0.31, 0.98)
	danger_style.corner_radius_top_left = 12
	danger_style.corner_radius_top_right = 12
	danger_style.corner_radius_bottom_left = 12
	danger_style.corner_radius_bottom_right = 12
	reset_progress_dialog.add_theme_stylebox_override("panel", danger_style)
	reset_progress_dialog.add_theme_color_override("title_color", Color(1.0, 0.84, 0.84, 1.0))
	reset_progress_dialog.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9, 1.0))
	reset_progress_dialog.confirmed.connect(_on_reset_progress_confirmed)
	panel_root.add_child(reset_progress_dialog)


func _add_toggle_row(title_text: String, help_text: String, setting_key: String) -> Control:
	var container := VBoxContainer.new()
	var help_label := Label.new()
	help_label.text = help_text
	help_label.modulate = Color(0.73, 0.76, 0.84, 0.95)
	container.add_child(help_label)

	var check := CheckBox.new()
	check.text = title_text
	check.set_meta("setting_key", setting_key)
	check.toggled.connect(_on_toggle_changed.bind(check))
	container.add_child(check)
	return container


func _add_slider_row(title_text: String, setting_key: String) -> Control:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = title_text
	title.custom_minimum_size = Vector2(170, 30)
	container.add_child(title)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.set_meta("setting_key", setting_key)
	slider.value_changed.connect(_on_slider_changed.bind(slider))
	container.add_child(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(76, 30)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider.set_meta("value_label", value_label)
	container.add_child(value_label)

	return container


func _add_autosave_row() -> Control:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = "Auto-save Interval"
	title.custom_minimum_size = Vector2(170, 30)
	container.add_child(title)

	var spin := SpinBox.new()
	spin.min_value = SettingsManager.MIN_AUTOSAVE_SECONDS
	spin.max_value = SettingsManager.MAX_AUTOSAVE_SECONDS
	spin.step = 1.0
	spin.custom_minimum_size = Vector2(110, 30)
	spin.set_meta("setting_key", "autosave_interval_seconds")
	spin.value_changed.connect(_on_autosave_changed.bind(spin))
	container.add_child(spin)

	var unit := Label.new()
	unit.text = "seconds"
	container.add_child(unit)

	return container


func _add_keybind_section() -> Control:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "Key Rebinding"
	title.add_theme_font_size_override("font_size", 20)
	section.add_child(title)

	for action_name in SettingsManager.get_rebind_actions():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var action_label := Label.new()
		action_label.text = str(REBIND_LABELS.get(action_name, action_name))
		action_label.custom_minimum_size = Vector2(170, 28)
		row.add_child(action_label)

		var key_label := Label.new()
		key_label.custom_minimum_size = Vector2(130, 28)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(key_label)
		key_button_map[action_name] = key_label

		var rebind_button := Button.new()
		rebind_button.text = "Rebind"
		rebind_button.pressed.connect(_on_rebind_pressed.bind(StringName(action_name)))
		row.add_child(rebind_button)

		section.add_child(row)

	return section


func _add_actions_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var save_button := Button.new()
	save_button.text = "Save Now"
	save_button.pressed.connect(_on_manual_save_pressed)
	row.add_child(save_button)

	var defaults_button := Button.new()
	defaults_button.text = "Reset Defaults"
	defaults_button.pressed.connect(_on_defaults_pressed)
	row.add_child(defaults_button)

	var reset_progress_button := Button.new()
	reset_progress_button.text = "Reset Progress"
	reset_progress_button.pressed.connect(_on_reset_progress_pressed)
	row.add_child(reset_progress_button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_on_close_pressed)
	row.add_child(close_button)

	return row


func _refresh_from_settings() -> void:
	for node in panel_body.get_children():
		if node is VBoxContainer:
			for child in node.get_children():
				if child is CheckBox and child.has_meta("setting_key"):
					var key: String = str(child.get_meta("setting_key"))
					child.button_pressed = bool(SettingsManager.get(key))
		elif node is HBoxContainer:
			for child in node.get_children():
				if child is HSlider and child.has_meta("setting_key"):
					var slider_key: String = str(child.get_meta("setting_key"))
					child.value = float(SettingsManager.get(slider_key))
					_update_slider_label(child)
				elif child is SpinBox and child.has_meta("setting_key"):
					var spin_key: String = str(child.get_meta("setting_key"))
					child.value = float(SettingsManager.get(spin_key))

	_update_keybind_labels()


func _update_slider_label(slider: HSlider) -> void:
	if slider.has_meta("value_label") == false:
		return
	var value_label: Label = slider.get_meta("value_label") as Label
	if value_label == null:
		return
	value_label.text = "%d%%" % int(round(slider.value * 100.0))


func _update_keybind_labels() -> void:
	for action_name in key_button_map.keys():
		var key_label: Label = key_button_map[action_name] as Label
		if key_label == null:
			continue
		var keycode: int = SettingsManager.get_primary_keycode(StringName(action_name))
		key_label.text = _keycode_to_text(keycode)


func _keycode_to_text(keycode: int) -> String:
	if keycode == KEY_NONE:
		return "(none)"
	var key_text: String = OS.get_keycode_string(keycode)
	if key_text == "":
		return "Key %d" % keycode
	return key_text


func _on_gear_pressed() -> void:
	toggle_menu()


func _on_close_pressed() -> void:
	set_menu_open(false)


func _on_defaults_pressed() -> void:
	SettingsManager.reset_to_defaults()
	_refresh_from_settings()
	status_label.text = "Defaults restored."


func _on_manual_save_pressed() -> void:
	Utils.saveGame()
	status_label.text = "Saved."


func _on_reset_progress_pressed() -> void:
	if reset_progress_dialog != null:
		reset_progress_dialog.popup_centered()


func _on_reset_progress_confirmed() -> void:
	Game.playerHP = Game.maxHP
	Game.gold = 0.0
	Game.level = 1
	Game.wins = 0
	Game.last_victory_wave = 0
	Game.reset_tutorial_progress()
	Utils.saveGame()
	status_label.text = "Progress reset."
	var scene_tree := get_tree()
	if scene_tree != null:
		scene_tree.paused = false
		scene_tree.change_scene_to_file("res://scenes/main/main.tscn")


func _on_toggle_changed(new_value: bool, toggle: CheckBox) -> void:
	var key: String = str(toggle.get_meta("setting_key"))
	SettingsManager.set(key, new_value)
	SettingsManager.apply_and_save()
	status_label.text = "Updated %s." % key


func _on_slider_changed(new_value: float, slider: HSlider) -> void:
	var key: String = str(slider.get_meta("setting_key"))
	SettingsManager.set(key, clampf(new_value, 0.0, 1.0))
	_update_slider_label(slider)
	SettingsManager.apply_and_save()


func _on_autosave_changed(new_value: float, spin: SpinBox) -> void:
	var key: String = str(spin.get_meta("setting_key"))
	SettingsManager.set(key, int(round(new_value)))
	SettingsManager.apply_and_save()


func _on_rebind_pressed(action_name: StringName) -> void:
	pending_rebind_action = action_name
	status_label.text = "Press a key for %s (Esc to cancel)." % str(REBIND_LABELS.get(String(action_name), action_name))
