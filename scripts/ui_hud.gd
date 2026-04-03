extends CanvasLayer

@onready var hp_label: Label = $hp
@onready var gold_label: Label = $Gold
@onready var death_label: Label = $death
@onready var level_label: Label = $level
@onready var max_hp_label: Label = $hp2
@onready var wave_label: Label = $WaveLabel
@onready var enemy_count_label: Label = $EnemyCountLabel
@onready var level_up_button: Button = $Button
@onready var wave_banner: ColorRect = $WaveBanner
@onready var wave_banner_label: Label = $WaveBanner/BannerLabel
@onready var cooldown_bar: ProgressBar = $CooldownBar

var spawner: EnemySpawner
var current_wave: int = 0
var total_enemies_spawned: int = 0  
var tracked_enemies: Dictionary = {}
var player: CharacterBody2D

func _ready() -> void:
	spawner = get_parent().get_node_or_null("EnemySpawner")
	if spawner:
		spawner.wave_started.connect(_on_wave_started)
		spawner.enemy_spawned.connect(_on_enemy_spawned)
	wave_banner.visible = false
	wave_banner.modulate.a = 0.0
	player = get_parent().find_child("player", true, false)
	cooldown_bar.min_value = 0.0
	cooldown_bar.value = 0.0
	_update_wave_labels()
	_update_stats()

func _process(_delta: float) -> void:
	_update_stats()
	if spawner:
		var total_alive = 0
		for enemy in tracked_enemies.keys():
			if is_instance_valid(enemy):
				total_alive += 1
		var total_defeated = total_enemies_spawned - total_alive
		_update_wave_labels(total_defeated)
	if player:
		var remaining_cooldown = maxf(0.0, player.attack_timer)
		var max_cooldown = player._get_attack_cooldown()
		cooldown_bar.max_value = max_cooldown
		cooldown_bar.value = remaining_cooldown

func _on_wave_started(wave_number: int) -> void:
	current_wave = wave_number
	_show_wave_banner(wave_number)

func _on_enemy_spawned(enemy: EnemyBase) -> void:
	total_enemies_spawned += 1
	tracked_enemies[enemy] = true

func _on_enemy_exited(enemy: EnemyBase) -> void:
	if tracked_enemies.has(enemy):
		tracked_enemies.erase(enemy)

func _on_all_enemies_defeated() -> void:
	pass  # Count is handled in _process

func _update_wave_labels(defeated: int = 0) -> void:
	wave_label.text = "Wave %d" % max(current_wave, 1)
	enemy_count_label.text = "Enemies %d/%d" % [defeated, total_enemies_spawned]

func _show_wave_banner(wave_number: int) -> void:
	wave_banner_label.text = "Wave %d" % wave_number
	wave_banner.visible = true
	wave_banner.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(wave_banner, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.8)
	t.tween_property(wave_banner, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished
	wave_banner.visible = false

func _update_stats() -> void:
	hp_label.text = "HP: %d" % Game.playerHP
	gold_label.text = "Gold: %d" % int(Game.gold)
	death_label.text = "Deaths: %d" % Game.deaths
	level_label.text = "Level: %d" % Game.level
	max_hp_label.text = "Max HP: %d" % Game.maxHP
