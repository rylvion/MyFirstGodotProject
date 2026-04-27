extends CanvasLayer

@onready var wave_label: Label = $WaveLabel
@onready var enemy_count_label: Label = $EnemyCountLabel
@onready var level_up_button: Button = $Button
@onready var wave_banner: ColorRect = $WaveBanner
@onready var wave_banner_label: Label = $WaveBanner/BannerLabel
@onready var cooldown_bar: ProgressBar = $CooldownBar
@onready var status_bars: Control = $StatusBars
@onready var combat_feed_label: Label = $CombatFeedLabel
@onready var tutorial_label: Label = $TutorialLabel
@onready var boss_header: Control = $BossHeader
@onready var boss_name_label: Label = $BossHeader/BossNameLabel
@onready var boss_health_bar: ProgressBar = $BossHeader/BossHealthBar
@onready var boss_health_text: Label = $BossHeader/BossHealthText
@onready var boss_action_label: Label = $BossHeader/BossActionLabel
@onready var startup_time_label: Label = $StartupTimeLabel

var spawner: EnemySpawner
var current_wave: int = 0
var total_enemies_in_wave: int = 0
var defeated_enemies_in_wave: int = 0
var elite_wave_active: bool = false
var current_wave_kind: StringName = &"normal"
var boss_name: String = ""
var boss_hits_remaining: int = 0
var boss_max_hits: int = 0
var player
var combat_feed_tween: Tween
var combat_feed_token: int = 0
var boss_action_tween: Tween
var boss_action_token: int = 0

func _ready() -> void:
	spawner = get_parent().get_node_or_null("EnemySpawner")
	if spawner:
		spawner.wave_started.connect(_on_wave_started)
		spawner.enemy_spawned.connect(_on_enemy_spawned)
		spawner.enemy_defeated.connect(_on_enemy_defeated_feedback)
		spawner.wave_state_changed.connect(_on_wave_state_changed)
		spawner.boss_spawned.connect(_on_boss_spawned)
		spawner.boss_health_changed.connect(_on_boss_health_changed)
		spawner.boss_state_changed.connect(_on_boss_state_changed)
		spawner.boss_attack_used.connect(_on_boss_attack_used)
	wave_banner.visible = false
	wave_banner.modulate.a = 0.0
	player = get_parent().find_child("player", true, false)
	if player != null:
		if player.has_signal("burn_applied") and player.burn_applied.is_connected(_on_player_burn_applied) == false:
			player.burn_applied.connect(_on_player_burn_applied)
		if player.has_signal("burn_ticked") and player.burn_ticked.is_connected(_on_player_burn_ticked) == false:
			player.burn_ticked.connect(_on_player_burn_ticked)
		if player.has_signal("burn_ended") and player.burn_ended.is_connected(_on_player_burn_ended) == false:
			player.burn_ended.connect(_on_player_burn_ended)
	cooldown_bar.min_value = 0.0
	cooldown_bar.value = 0.0
	combat_feed_label.visible = false
	combat_feed_label.modulate.a = 0.0
	tutorial_label.visible = false
	tutorial_label.modulate.a = 1.0
	boss_header.visible = false
	boss_action_label.visible = false
	boss_action_label.modulate.a = 0.0
	boss_health_bar.min_value = 0.0
	boss_health_bar.value = 0.0
	startup_time_label.visible = false
	if Game.hp_changed.is_connected(_on_hp_changed) == false:
		Game.hp_changed.connect(_on_hp_changed)
	if Game.max_hp_changed.is_connected(_on_max_hp_changed) == false:
		Game.max_hp_changed.connect(_on_max_hp_changed)
	if Game.gold_changed.is_connected(_on_gold_changed) == false:
		Game.gold_changed.connect(_on_gold_changed)
	if Game.level_changed.is_connected(_on_level_changed) == false:
		Game.level_changed.connect(_on_level_changed)
	if Game.tutorial_progress_changed.is_connected(_on_tutorial_progress_changed) == false:
		Game.tutorial_progress_changed.connect(_on_tutorial_progress_changed)
	if SettingsManager != null and SettingsManager.settings_changed.is_connected(_on_settings_changed) == false:
		SettingsManager.settings_changed.connect(_on_settings_changed)
	_sync_from_spawner()
	_update_wave_labels()
	_update_boss_header()
	_refresh_status_bars()
	_update_tutorial_label()


func show_startup_time(startup_msec: int) -> void:
	if startup_time_label == null:
		return

	startup_time_label.text = "Loaded in %d ms" % max(startup_msec, 0)
	startup_time_label.visible = true

func _process(_delta: float) -> void:
	if player:
		var remaining_cooldown = maxf(0.0, player.attack_timer)
		var max_cooldown = player.get_attack_cooldown()
		cooldown_bar.max_value = max_cooldown
		cooldown_bar.value = remaining_cooldown

func _on_wave_started(wave_number: int, total_enemies: int, wave_kind: StringName) -> void:
	current_wave = wave_number
	total_enemies_in_wave = total_enemies
	defeated_enemies_in_wave = 0
	current_wave_kind = wave_kind
	elite_wave_active = wave_kind == &"elite"
	if wave_kind == &"elite":
		Game.mark_tutorial_step(&"elite_wave")
	elif wave_kind == &"boss":
		Game.mark_tutorial_step(&"boss_wave")
	boss_name = ""
	boss_hits_remaining = 0
	boss_max_hits = 0
	_update_wave_labels()
	_update_boss_header()
	_show_wave_banner(wave_number, wave_kind)

func _on_enemy_spawned(enemy: EnemyBase, _alive_enemies: int, _total_spawned: int) -> void:
	if enemy.has_signal("player_damaged"):
		var damage_callable: Callable = _on_player_damaged_feedback.bind(enemy)
		if enemy.player_damaged.is_connected(damage_callable) == false:
			enemy.player_damaged.connect(damage_callable)

func _on_wave_state_changed(defeated: int, total_enemies: int, _alive_enemies: int) -> void:
	defeated_enemies_in_wave = defeated
	total_enemies_in_wave = total_enemies
	_update_wave_labels()

func _on_boss_spawned(boss: BossDragon) -> void:
	if boss == null:
		return

	if spawner != null:
		current_wave = max(current_wave, spawner.wave_number)
	boss_name = boss.get_boss_name()
	boss_hits_remaining = boss.get_hits_remaining()
	boss_max_hits = boss.get_max_hits()
	current_wave_kind = &"boss"
	_update_wave_labels()
	_update_boss_header()

func _on_boss_health_changed(current_hits: int, max_hits: int) -> void:
	if current_hits <= 0 or max_hits <= 0:
		if boss_name == "":
			boss_name = "Dragon"
		boss_hits_remaining = 0
		boss_max_hits = 0
		current_wave_kind = &"boss"
		_update_wave_labels()
		_update_boss_header()
		return
	if spawner == null or is_instance_valid(spawner.current_boss) == false:
		return
	boss_hits_remaining = current_hits
	boss_max_hits = max_hits
	current_wave_kind = &"boss"
	_update_wave_labels()
	_update_boss_header()

func _on_boss_state_changed(next_boss_name: String, current_hits: int, max_hits: int) -> void:
	if next_boss_name == "" or current_hits <= 0 or max_hits <= 0:
		if boss_name == "":
			boss_name = "Dragon"
		boss_hits_remaining = 0
		boss_max_hits = 0
		current_wave_kind = &"boss"
		_update_wave_labels()
		_update_boss_header()
		return
	if spawner == null or is_instance_valid(spawner.current_boss) == false:
		return
	boss_name = next_boss_name
	boss_hits_remaining = current_hits
	boss_max_hits = max_hits
	if boss_name != "":
		current_wave_kind = &"boss"
	_update_wave_labels()
	_update_boss_header()


func _on_boss_attack_used(next_boss_name: String, attack_name: String) -> void:
	var shown_name: String = next_boss_name if next_boss_name != "" else "Dragon"
	_show_boss_action("%s used %s" % [shown_name, attack_name])

func _on_enemy_defeated_feedback(enemy: EnemyBase, gold_amount: int, _defeated_enemies: int, _remaining_enemies: int) -> void:
	if gold_amount > 0:
		_show_combat_feed("+%d Gold" % gold_amount, Color(1.0, 0.86, 0.2, 1.0), enemy)
	if enemy is BossDragon:
		boss_hits_remaining = 0
		_update_boss_header()

func _on_player_damaged_feedback(damage_amount: float, enemy: EnemyBase) -> void:
	_show_combat_feed("-%d HP" % int(damage_amount), Color(1.0, 0.35, 0.35, 1.0), enemy)

func _show_combat_feed(text_value: String, color_value: Color, target_node: Node2D) -> void:
	combat_feed_token += 1
	var feed_token: int = combat_feed_token

	if combat_feed_tween:
		combat_feed_tween.kill()
		_reset_combat_feed()

	var screen_pos := _enemy_to_screen(target_node)
	combat_feed_label.offset_left = screen_pos.x - 90.0
	combat_feed_label.offset_top = screen_pos.y - 18.0
	combat_feed_label.offset_right = screen_pos.x + 90.0
	combat_feed_label.offset_bottom = screen_pos.y + 18.0

	combat_feed_label.text = text_value
	combat_feed_label.modulate = color_value
	combat_feed_label.modulate.a = 1.0
	combat_feed_label.visible = true

	combat_feed_tween = create_tween()
	combat_feed_tween.tween_property(combat_feed_label, "offset_top", combat_feed_label.offset_top - 18.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	combat_feed_tween.parallel().tween_property(combat_feed_label, "offset_bottom", combat_feed_label.offset_bottom - 18.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	combat_feed_tween.parallel().tween_property(combat_feed_label, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	combat_feed_tween.tween_callback(Callable(self, "_finish_combat_feed").bind(feed_token))

func _enemy_to_screen(target_node: Node2D) -> Vector2:
	if is_instance_valid(target_node):
		var vertical_offset: float = -10.0 if target_node == player else -28.0
		return target_node.get_global_transform_with_canvas().origin + Vector2(0, vertical_offset)

	var world_pos := Vector2.ZERO
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return world_pos

	var viewport_size := get_viewport().get_visible_rect().size
	return ((world_pos - camera.get_screen_center_position()) / camera.zoom) + (viewport_size * 0.5)

func _update_wave_labels(defeated: int = -1) -> void:
	var shown_defeated := defeated if defeated >= 0 else defeated_enemies_in_wave
	wave_label.text = _get_wave_label_text()

	if current_wave_kind == &"boss" and boss_max_hits > 0:
		enemy_count_label.text = "Boss HP: %d/%d" % [boss_hits_remaining, boss_max_hits]
	elif current_wave_kind == &"boss" and boss_hits_remaining <= 0:
		enemy_count_label.text = "Boss defeated"
	else:
		enemy_count_label.text = "Enemies %d/%d" % [shown_defeated, total_enemies_in_wave]

func _show_wave_banner(wave_number: int, wave_kind: StringName) -> void:
	wave_banner_label.text = _get_wave_banner_text(wave_number, wave_kind)
	wave_banner.visible = true
	wave_banner.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(wave_banner, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.8)
	t.tween_property(wave_banner, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished
	wave_banner.visible = false

func _refresh_status_bars() -> void:
	if status_bars and status_bars.has_method("set_health") and status_bars.has_method("set_gold_progress"):
		status_bars.call("set_health", Game.playerHP, Game.maxHP)
		status_bars.call("set_gold_progress", Game.gold, Game.get_hp_upgrade_cost(Game.level))
		if status_bars.has_method("set_level"):
			status_bars.call("set_level", Game.level)

func _update_tutorial_label() -> void:
	var hint := Game.get_next_tutorial_hint()
	tutorial_label.text = hint
	tutorial_label.visible = hint != ""
	if tutorial_label.visible:
		tutorial_label.modulate.a = 1.0

func _on_hp_changed(_new_hp: int) -> void:
	_refresh_status_bars()

func _on_max_hp_changed(_new_max_hp: int) -> void:
	_refresh_status_bars()

func _on_gold_changed(_new_gold: float) -> void:
	_refresh_status_bars()

func _on_level_changed(_new_level: int) -> void:
	_refresh_status_bars()

func _on_tutorial_progress_changed() -> void:
	_update_tutorial_label()


func _on_settings_changed() -> void:
	_update_tutorial_label()

func _sync_from_spawner() -> void:
	if spawner == null:
		return

	var stats: Dictionary = spawner.get_stats()
	current_wave = int(stats.get("wave", 0))
	total_enemies_in_wave = int(stats.get("enemies_to_spawn", 0))
	defeated_enemies_in_wave = int(stats.get("wave_defeated", 0))
	var wave_kind_value: String = str(stats.get("wave_kind", "normal"))
	current_wave_kind = StringName(wave_kind_value)
	elite_wave_active = bool(stats.get("elite_wave", false))
	boss_name = str(stats.get("boss_name", ""))

	if current_wave_kind == &"boss" and is_instance_valid(spawner.current_boss):
		boss_hits_remaining = spawner.current_boss.get_hits_remaining()
		boss_max_hits = spawner.current_boss.get_max_hits()
	elif current_wave < 10 and current_wave_kind == &"boss":
		current_wave_kind = &"normal"
		boss_name = ""
		boss_hits_remaining = 0
		boss_max_hits = 0

func _update_boss_header() -> void:
	var show_boss_header: bool = current_wave_kind == &"boss" and boss_name != "" and boss_max_hits > 0 and boss_hits_remaining > 0
	boss_header.visible = show_boss_header
	if show_boss_header == false:
		_clear_boss_action()
		return

	boss_name_label.text = boss_name
	boss_health_bar.max_value = float(boss_max_hits)
	boss_health_bar.value = float(boss_hits_remaining)
	boss_health_text.text = "%d / %d" % [boss_hits_remaining, boss_max_hits]

func _show_boss_action(text_value: String) -> void:
	boss_action_token += 1
	var action_token: int = boss_action_token

	if boss_action_tween:
		boss_action_tween.kill()
		_clear_boss_action()

	boss_action_label.text = text_value
	boss_action_label.modulate = Color(1.0, 0.98, 0.94, 1.0)
	boss_action_label.modulate.a = 1.0
	boss_action_label.visible = true

	boss_action_tween = create_tween()
	boss_action_tween.tween_interval(1.1)
	boss_action_tween.tween_property(boss_action_label, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	boss_action_tween.tween_callback(Callable(self, "_finish_boss_action").bind(action_token))


func _finish_boss_action(action_token: int) -> void:
	if action_token != boss_action_token:
		return
	_clear_boss_action()


func _clear_boss_action() -> void:
	boss_action_label.visible = false
	boss_action_label.modulate.a = 0.0


func _on_player_burn_applied(stacks: int) -> void:
	if player == null:
		return
	_show_combat_feed("Burn x%d" % stacks, Color(1.0, 0.56, 0.15, 1.0), player)


func _on_player_burn_ticked(damage_amount: int, stacks: int) -> void:
	if player == null:
		return
	_show_combat_feed("Burn -%d (x%d)" % [damage_amount, stacks], Color(1.0, 0.92, 0.75, 1.0), player)


func _on_player_burn_ended() -> void:
	if player == null:
		return
	_show_combat_feed("Burn faded", Color(1.0, 0.72, 0.35, 1.0), player)

func _reset_combat_feed() -> void:
	combat_feed_label.visible = false
	combat_feed_label.modulate.a = 0.0


func _finish_combat_feed(feed_token: int) -> void:
	if feed_token != combat_feed_token:
		return

	_reset_combat_feed()

func _get_wave_label_text() -> String:
	if current_wave_kind == &"boss" and current_wave >= 10:
		return "Boss Wave %d" % max(current_wave, 1)
	if current_wave_kind == &"elite":
		return "Elite Wave %d" % max(current_wave, 1)
	return "Wave %d" % max(current_wave, 1)

func _get_wave_banner_text(wave_number: int, wave_kind: StringName) -> String:
	if wave_kind == &"boss":
		return "Boss Wave %d" % wave_number
	if wave_kind == &"elite":
		return "Elite Wave %d" % wave_number
	return "Wave %d" % wave_number
