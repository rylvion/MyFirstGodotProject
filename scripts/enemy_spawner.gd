extends Node2D
class_name EnemySpawner

@export var ENABLE_SPAWNING: bool = true
@export var WAVE_BASED: bool = true 
@export var INITIAL_ENEMY_COUNT: int = 2

@export var spawn_zones: Array[Vector2] = [] 

# default ranged spawn zones (x_min/x_max + y) for dynamic placement
const DEFAULT_SPAWN_RANGES := [
	{"y": 300, "x_min": 0, "x_max": 276},
	{"y": 300, "x_min": 312, "x_max": 352},
	{"y": 300, "x_min": 568, "x_max": 800},
	{"y": 425, "x_min": 832, "x_max": 1136},
	{"y": 300, "x_min": 1176, "x_max": 2284},
]

var spawn_ranges: Array = []

@export var frog_scene: PackedScene = preload("res://scenes/enemies/frog.tscn")
@export var slime_scene: PackedScene = preload("res://scenes/enemies/slime.tscn")

@export var wave_delay: float = 8.0 
@export var respawn_delay: float = 5.0  

# difficulty scaling
var current_level: int = 1
var active_enemies: Array[EnemyBase] = []
var enemy_count_base: int = 2
var max_enemies: int = 10

# signals
signal wave_started(wave_number: int)
signal wave_completed
signal enemy_spawned(enemy: EnemyBase)
signal all_enemies_defeated

# private state
var wave_number: int = 0
var enemies_to_spawn: int = 0
var current_player: Node2D = null
var is_spawning_wave: bool = false 

func _ready() -> void:
	current_player = get_tree().root.get_child(0).find_child("player", true, false)
	current_level = Game.level
	
	if Game.has_signal("level_changed"):
		Game.connect("level_changed", Callable(self, "_on_level_changed"))
	
	if spawn_zones.is_empty():
		_setup_default_spawn_zones()
	
	if ENABLE_SPAWNING:
		_start_wave()


func _physics_process(delta: float) -> void:
	active_enemies = active_enemies.filter(func(enemy): return is_instance_valid(enemy))
	
	if active_enemies.is_empty() and ENABLE_SPAWNING and WAVE_BASED and not is_spawning_wave:
		all_enemies_defeated.emit()
		is_spawning_wave = true
		await get_tree().create_timer(wave_delay).timeout
		_start_wave()
		is_spawning_wave = false


func _setup_default_spawn_zones() -> void:
	spawn_ranges = DEFAULT_SPAWN_RANGES.duplicate(true)


func _start_wave() -> void:
	wave_number += 1
	
	var wave_increase = int((wave_number - 1) * 0.5)  # Increase by 1 every 2 waves
	enemies_to_spawn = min(
		enemy_count_base + wave_increase,
		max_enemies
	)

	var available_slots := spawn_ranges.size() if spawn_zones.is_empty() else spawn_zones.size()
	enemies_to_spawn = min(enemies_to_spawn, available_slots)
	
	wave_started.emit(wave_number)
	
	for i in range(enemies_to_spawn):
		await get_tree().create_timer(1.0).timeout
		_spawn_enemy(i)


func _spawn_enemy(_spawn_index: int) -> void:
	if spawn_zones.is_empty() and spawn_ranges.is_empty():
		return
	
	var spawn_zone = _get_spawn_position()
	var enemy: EnemyBase
	
	var enemy_type_roll = randf()
	var frog_chance = min(0.3 + (current_level * 0.1), 0.8) 
	
	if enemy_type_roll < frog_chance:
		enemy = frog_scene.instantiate() as Frog
	else:
		enemy = slime_scene.instantiate() as Slime
	
	enemy.global_position = spawn_zone
	
	enemy.set_difficulty_scaling(current_level)
	
	enemy.enemy_died.connect(_on_enemy_died.bindv([enemy]))
	
	add_child(enemy)
	active_enemies.append(enemy)
	
	enemy_spawned.emit(enemy)


func _get_spawn_position() -> Vector2:
	var spawn_position: Vector2 = Vector2.ZERO
	var attempts := 0

	while attempts < 5:
		if not spawn_zones.is_empty():
			spawn_position = spawn_zones[randi() % spawn_zones.size()]
		else:
			var spawn_range: Dictionary = spawn_ranges[randi() % spawn_ranges.size()]
			spawn_position = Vector2(
				randf_range(spawn_range["x_min"], spawn_range["x_max"]),
				spawn_range["y"]
			)

		var overlaps := false
		for enemy in active_enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(spawn_position) < 24.0:
				overlaps = true
				break

		if not overlaps:
			return spawn_position

		attempts += 1

	return spawn_position


func _on_enemy_died(_gold: int, enemy: EnemyBase) -> void:
	if enemy in active_enemies:
		active_enemies.erase(enemy)
	
	if not WAVE_BASED:
		await get_tree().create_timer(respawn_delay).timeout
		_spawn_enemy(active_enemies.size() % spawn_zones.size())


func _on_level_changed(new_level: int) -> void:
	current_level = new_level
	
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.set_difficulty_scaling(current_level)
	
	var new_max = min(enemy_count_base + (current_level - 1) * 2, max_enemies)
	if active_enemies.size() < new_max and not WAVE_BASED:
		_spawn_enemy(active_enemies.size() % spawn_zones.size())


func update_spawn_zones(zones: Array[Vector2]) -> void:
	spawn_zones = zones


func get_active_enemies_count() -> int:
	active_enemies = active_enemies.filter(func(enemy): return is_instance_valid(enemy))
	return active_enemies.size()


func get_active_enemies() -> Array[EnemyBase]:
	active_enemies = active_enemies.filter(func(enemy): return is_instance_valid(enemy))
	return active_enemies


func pause_spawning() -> void:
	ENABLE_SPAWNING = false


func resume_spawning() -> void:
	ENABLE_SPAWNING = true
	if active_enemies.is_empty():
		_start_wave()


func clear_all_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()


func get_stats() -> Dictionary:
	return {
		"wave": wave_number,
		"active_enemies": get_active_enemies_count(),
		"current_level": current_level,
		"spawn_zones": spawn_zones.size(),
		"enabled": ENABLE_SPAWNING
	}
