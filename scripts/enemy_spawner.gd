extends Node2D
class_name EnemySpawner

@export var ENABLE_SPAWNING: bool = true
@export var WAVE_BASED: bool = true
@export var INITIAL_ENEMY_COUNT: int = 2
@export var spawn_interval: float = 0.35
@export var spawn_warning_time: float = 0.22
@export var spawn_zones: Array[Vector2] = []
@export var scene_boss_path: NodePath = NodePath("../BossDragon")

@export var frog_scene: PackedScene = preload("res://scenes/enemies/frog.tscn")
@export var slime_scene: PackedScene = preload("res://scenes/enemies/slime.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/enemies/boss_dragon.tscn")

@export var wave_delay: float = 1.5
@export var boss_wave_delay: float = 2.25
@export var respawn_delay: float = 5.0
@export var boss_spawn_height_offset: float = 72.0
@export var boss_spawn_player_distance: float = 140.0

const DEFAULT_SPAWN_RANGES := [
	{"y": 305, "x_min": 48, "x_max": 2248},
]
const MIN_FROG_CHANCE := 0.25
const MAX_FROG_CHANCE := 0.60
const FROG_CHANCE_PER_WAVE := 0.035
const MAX_TEST_WAVE: int = 30
const SPAWN_HEIGHT_BIAS: float = 10.0
const MIN_ENEMY_SPAWN_SPACING: float = 110.0
const BOSS_SPAWN_CLEARANCE: float = 240.0

var spawn_ranges: Array = []
var active_enemies: Array[EnemyBase] = []
var max_enemies: int = 18

signal wave_started(wave_number: int, total_enemies: int, wave_kind: StringName)
signal wave_completed(wave_number: int)
signal enemy_spawned(enemy: EnemyBase, alive_enemies: int, total_spawned: int)
signal enemy_defeated(enemy: EnemyBase, gold_amount: int, defeated_enemies: int, remaining_enemies: int)
signal wave_state_changed(defeated_enemies: int, total_enemies: int, alive_enemies: int)
signal all_enemies_defeated(wave_number: int)
signal boss_spawned(boss: BossDragon)
signal boss_health_changed(current_hits: int, max_hits: int)
signal boss_state_changed(boss_name: String, current_hits: int, max_hits: int)
signal boss_attack_used(boss_name: String, attack_name: String)

var wave_number: int = 0
var enemies_to_spawn: int = 0
var current_wave_spawned: int = 0
var current_wave_defeated: int = 0
var is_spawning_wave: bool = false
var is_waiting_for_next_wave: bool = false
var elite_wave_active: bool = false
var current_wave_kind: StringName = &"normal"
var current_boss: BossDragon = null
var current_boss_name: String = ""
var wave_sequence_id: int = 0
var scene_boss: BossDragon = null


func _ready() -> void:
	if spawn_zones.is_empty():
		_setup_default_spawn_zones()
	_cache_scene_boss()

	if ENABLE_SPAWNING:
		_start_wave()


func _cache_scene_boss() -> void:
	scene_boss = get_node_or_null(scene_boss_path) as BossDragon
	if scene_boss == null:
		return

	scene_boss.assign_spawner(self)
	if scene_boss.defeated.is_connected(_on_enemy_defeated) == false:
		scene_boss.defeated.connect(_on_enemy_defeated)
	var scene_boss_exited := _on_enemy_tree_exited.bind(scene_boss)
	if scene_boss.tree_exited.is_connected(scene_boss_exited) == false:
		scene_boss.tree_exited.connect(scene_boss_exited, CONNECT_ONE_SHOT)
	if scene_boss.health_changed.is_connected(_on_boss_health_changed) == false:
		scene_boss.health_changed.connect(_on_boss_health_changed)
	if scene_boss.has_signal("attack_used"):
		if scene_boss.attack_used.is_connected(_on_boss_attack_used) == false:
			scene_boss.attack_used.connect(_on_boss_attack_used)
	if scene_boss.has_method("deactivate_for_wave"):
		scene_boss.call_deferred("deactivate_for_wave")
	else:
		scene_boss.visible = false
		scene_boss.set_physics_process(false)


func _create_fallback_scene_boss() -> void:
	if boss_scene == null:
		return
	if get_node_or_null(scene_boss_path) != null:
		return

	var fallback_boss := boss_scene.instantiate() as BossDragon
	if fallback_boss == null:
		return

	fallback_boss.name = "BossDragon"
	var boss_parent: Node = get_parent()
	if boss_parent == null:
		return
	boss_parent.add_child(fallback_boss)
	fallback_boss.owner = get_tree().current_scene


func _setup_default_spawn_zones() -> void:
	spawn_ranges = DEFAULT_SPAWN_RANGES.duplicate(true)


func _start_wave() -> void:
	if not ENABLE_SPAWNING:
		return
	if wave_number >= MAX_TEST_WAVE:
		wave_number = MAX_TEST_WAVE
		is_spawning_wave = false
		is_waiting_for_next_wave = false
		return

	wave_sequence_id += 1
	var sequence_id: int = wave_sequence_id
	wave_number += 1
	var boss_wave: bool = _is_boss_wave(wave_number)
	elite_wave_active = wave_number % 5 == 0 and not boss_wave
	current_wave_kind = &"boss" if boss_wave else (&"elite" if elite_wave_active else &"normal")
	enemies_to_spawn = 1 if boss_wave else _get_wave_enemy_count()
	current_wave_spawned = 0
	current_wave_defeated = 0
	is_spawning_wave = true
	current_boss = null
	current_boss_name = ""

	wave_started.emit(wave_number, enemies_to_spawn, current_wave_kind)
	wave_state_changed.emit(current_wave_defeated, enemies_to_spawn, active_enemies.size())
	if boss_wave:
		_spawn_boss_wave(sequence_id)
	else:
		_spawn_wave_async(sequence_id)


func _spawn_boss_wave(sequence_id: int) -> void:
	if not ENABLE_SPAWNING or sequence_id != wave_sequence_id:
		return

	if scene_boss == null:
		_create_fallback_scene_boss()
		_cache_scene_boss()
	if scene_boss == null:
		push_warning("Boss wave requested but no scene boss could be created.")
		is_spawning_wave = false
		current_wave_defeated = enemies_to_spawn
		_check_wave_completion()
		return

	if scene_boss.has_method("activate_for_wave"):
		var boss_spawn_position: Vector2 = _get_boss_spawn_position()
		print("boss spawn pos: ", boss_spawn_position)
		scene_boss.global_position = boss_spawn_position
		scene_boss.activate_for_wave(wave_number)
	else:
		var fallback_boss_spawn_position: Vector2 = _get_boss_spawn_position()
		scene_boss.global_position = fallback_boss_spawn_position
		scene_boss.set_wave_scaling(wave_number, false)
		scene_boss.visible = true
		scene_boss.set_physics_process(true)
	current_boss = scene_boss
	current_boss_name = scene_boss.get_boss_name()
	if active_enemies.has(scene_boss) == false:
		active_enemies.append(scene_boss)

	current_wave_spawned = 1
	enemy_spawned.emit(scene_boss, active_enemies.size(), current_wave_spawned)
	boss_spawned.emit(scene_boss)
	boss_health_changed.emit(scene_boss.get_hits_remaining(), scene_boss.get_max_hits())
	boss_state_changed.emit(current_boss_name, scene_boss.get_hits_remaining(), scene_boss.get_max_hits())
	wave_state_changed.emit(current_wave_defeated, enemies_to_spawn, active_enemies.size())
	is_spawning_wave = false
	_check_wave_completion()


func _spawn_wave_async(sequence_id: int) -> void:
	for spawn_index in range(enemies_to_spawn):
		if not ENABLE_SPAWNING or sequence_id != wave_sequence_id:
			break

		var spawn_position := _get_spawn_position()
		var telegraph := _show_spawn_telegraph(spawn_position, current_wave_kind)
		await get_tree().create_timer(spawn_warning_time).timeout

		if is_instance_valid(telegraph):
			telegraph.queue_free()
		if not ENABLE_SPAWNING or sequence_id != wave_sequence_id:
			break

		_spawn_enemy(spawn_index, spawn_position)

		if spawn_index < enemies_to_spawn - 1:
			await get_tree().create_timer(spawn_interval).timeout

	is_spawning_wave = false
	_check_wave_completion()


func _spawn_enemy(_spawn_index: int, spawn_position: Vector2) -> void:
	if spawn_zones.is_empty() and spawn_ranges.is_empty():
		return

	var enemy: EnemyBase
	if current_wave_kind == &"boss":
		return
	else:
		var enemy_type_roll: float = randf()
		var frog_chance: float = clamp(0.30 + (FROG_CHANCE_PER_WAVE * float(wave_number - 1)), 0.30, 0.65)

		if enemy_type_roll < frog_chance:
			enemy = frog_scene.instantiate() as Frog
		else:
			enemy = slime_scene.instantiate() as Slime

		enemy.set_spawn_intro_enabled(false)
		enemy.set_wave_scaling(wave_number, elite_wave_active)

	enemy.global_position = spawn_position
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy), CONNECT_ONE_SHOT)

	add_child(enemy)
	active_enemies.append(enemy)
	current_wave_spawned += 1
	enemy_spawned.emit(enemy, active_enemies.size(), current_wave_spawned)
	wave_state_changed.emit(current_wave_defeated, enemies_to_spawn, active_enemies.size())


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
				float(spawn_range["y"]) - SPAWN_HEIGHT_BIAS
			)

		if not _is_spawn_overlapping(spawn_position, MIN_ENEMY_SPAWN_SPACING):
			return _snap_spawn_y_to_lane(spawn_position)

		attempts += 1

	return _snap_spawn_y_to_lane(_push_spawn_away_from_active_enemies(spawn_position, MIN_ENEMY_SPAWN_SPACING, 8))


func _is_spawn_overlapping(spawn_position: Vector2, min_distance: float) -> bool:
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			continue
		var required_distance: float = min_distance
		if enemy == current_boss:
			required_distance = maxf(required_distance, BOSS_SPAWN_CLEARANCE)
		if enemy.global_position.distance_to(spawn_position) < required_distance:
			return true
	return false


func _push_spawn_away_from_active_enemies(spawn_position: Vector2, min_distance: float, max_iterations: int) -> Vector2:
	var adjusted_position: Vector2 = spawn_position
	for _iteration in range(max_iterations):
		var adjusted: bool = false
		for enemy in active_enemies:
			if not is_instance_valid(enemy):
				continue
			var required_distance: float = min_distance
			if enemy == current_boss:
				required_distance = maxf(required_distance, BOSS_SPAWN_CLEARANCE)
			var delta: Vector2 = adjusted_position - enemy.global_position
			var distance: float = delta.length()
			if distance >= required_distance:
				continue
			var push_dir: Vector2 = Vector2.RIGHT if delta.length_squared() < 0.0001 else delta.normalized()
			adjusted_position = enemy.global_position + (push_dir * required_distance)
			adjusted = true
		if not adjusted:
			break

	if not spawn_ranges.is_empty():
		var min_x: float = float(spawn_ranges[0]["x_min"])
		var max_x: float = float(spawn_ranges[0]["x_max"])
		for spawn_range in spawn_ranges:
			min_x = minf(min_x, float(spawn_range["x_min"]))
			max_x = maxf(max_x, float(spawn_range["x_max"]))
		adjusted_position.x = clampf(adjusted_position.x, min_x, max_x)

	return _snap_spawn_y_to_lane(adjusted_position)


func _get_boss_spawn_position() -> Vector2:
	var base_spawn_position: Vector2 = _get_spawn_position()
	var spawn_y: float = base_spawn_position.y - boss_spawn_height_offset

	if spawn_zones.is_empty() and spawn_ranges.is_empty():
		return Vector2(base_spawn_position.x, spawn_y)

	var player_node: Node2D = get_node_or_null("../Player/player") as Node2D
	if player_node == null:
		return Vector2(base_spawn_position.x, spawn_y)

	var candidate_x: float = player_node.global_position.x + randf_range(-boss_spawn_player_distance, boss_spawn_player_distance)

	if not spawn_zones.is_empty():
		var nearest_zone: Vector2 = spawn_zones[0]
		var nearest_distance: float = absf(nearest_zone.x - candidate_x)
		for zone in spawn_zones:
			var distance: float = absf(zone.x - candidate_x)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_zone = zone
		return Vector2(nearest_zone.x, nearest_zone.y - boss_spawn_height_offset)

	var min_x: float = float(spawn_ranges[0]["x_min"])
	var max_x: float = float(spawn_ranges[0]["x_max"])
	for spawn_range in spawn_ranges:
		min_x = minf(min_x, float(spawn_range["x_min"]))
		max_x = maxf(max_x, float(spawn_range["x_max"]))

	return Vector2(clampf(candidate_x, min_x, max_x), spawn_y)


func _snap_spawn_y_to_lane(spawn_position: Vector2) -> Vector2:
	if not spawn_zones.is_empty():
		var nearest_zone: Vector2 = _get_nearest_spawn_zone_position(spawn_position)
		return Vector2(spawn_position.x, nearest_zone.y)

	if not spawn_ranges.is_empty():
		var nearest_y: float = float(spawn_ranges[0]["y"]) - SPAWN_HEIGHT_BIAS
		var nearest_distance: float = absf(spawn_position.y - nearest_y)
		for spawn_range in spawn_ranges:
			var lane_y: float = float(spawn_range["y"]) - SPAWN_HEIGHT_BIAS
			var lane_distance: float = absf(spawn_position.y - lane_y)
			if lane_distance < nearest_distance:
				nearest_distance = lane_distance
				nearest_y = lane_y
		return Vector2(spawn_position.x, nearest_y)

	return spawn_position
func _on_enemy_defeated(gold_amount: int, enemy: EnemyBase) -> void:
	if enemy in active_enemies:
		active_enemies.erase(enemy)

	var should_count_for_progress: bool = current_wave_kind != &"boss" or enemy == current_boss
	if should_count_for_progress:
		current_wave_defeated = min(current_wave_defeated + 1, enemies_to_spawn)
	enemy_defeated.emit(enemy, gold_amount, current_wave_defeated, active_enemies.size())
	if enemy == current_boss:
		var defeated_boss: BossDragon = enemy as BossDragon
		print("boss defeated on wave ", wave_number)
		boss_state_changed.emit(current_boss_name, 0, defeated_boss.get_max_hits())
		current_boss = null
		current_boss_name = ""
		call_deferred("_finish_boss_wave_after_boss_death", defeated_boss)
	wave_state_changed.emit(current_wave_defeated, enemies_to_spawn, active_enemies.size())

	if not WAVE_BASED:
		await get_tree().create_timer(respawn_delay).timeout
		if ENABLE_SPAWNING:
			var spawn_position := _get_spawn_position()
			var telegraph := _show_spawn_telegraph(spawn_position, &"normal")
			await get_tree().create_timer(spawn_warning_time).timeout
			if is_instance_valid(telegraph):
				telegraph.queue_free()
			_spawn_enemy(active_enemies.size(), spawn_position)
		return

	_check_wave_completion()


func _on_enemy_tree_exited(enemy: EnemyBase) -> void:
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		if enemy == current_boss:
			current_boss_name = ""
			current_boss = null
		wave_state_changed.emit(current_wave_defeated, enemies_to_spawn, active_enemies.size())
		_check_wave_completion()


func _on_boss_health_changed(current_hits: int, max_hits: int) -> void:
	if current_boss == null:
		return
	boss_health_changed.emit(current_hits, max_hits)
	boss_state_changed.emit(current_boss_name, current_hits, max_hits)


func _on_boss_attack_used(attack_name: String) -> void:
	if current_boss == null:
		return
	boss_attack_used.emit(current_boss_name, attack_name)


func _check_wave_completion() -> void:
	if not WAVE_BASED:
		return
	if is_spawning_wave or is_waiting_for_next_wave:
		return
	if current_wave_defeated < enemies_to_spawn:
		return
	if not active_enemies.is_empty():
		return

	wave_completed.emit(wave_number)
	all_enemies_defeated.emit(wave_number)
	_schedule_next_wave()


func _schedule_next_wave() -> void:
	if wave_number >= MAX_TEST_WAVE:
		is_waiting_for_next_wave = false
		return
	is_waiting_for_next_wave = true
	var scheduled_sequence_id: int = wave_sequence_id
	await get_tree().create_timer(_get_next_wave_delay()).timeout
	if scheduled_sequence_id != wave_sequence_id:
		is_waiting_for_next_wave = false
		return
	is_waiting_for_next_wave = false

	if ENABLE_SPAWNING:
		_start_wave()


func _get_wave_enemy_count() -> int:
	var available_spawn_slots: int = max_enemies if spawn_zones.is_empty() else max(spawn_zones.size(), 1)
	var scaled_count: int = 4 + int(floor((wave_number - 1) * 1.0))
	return min(min(scaled_count, max_enemies), available_spawn_slots)


func _get_next_wave_delay() -> float:
	if wave_number > 0 and wave_number % 10 == 0:
		return boss_wave_delay

	var reduced_delay: float = wave_delay - (0.08 * float(max(wave_number - 1, 0)))
	return clampf(reduced_delay, 1.0, wave_delay)


func spawn_elite_pack(count: int, origin_position: Vector2) -> void:
	if count <= 0:
		return

	call_deferred("_spawn_elite_pack_async", count, origin_position)


func _spawn_elite_pack_async(count: int, origin_position: Vector2) -> void:
	var summon_count: int = min(count, max(max_enemies - active_enemies.size(), 0))
	if summon_count <= 0:
		return

	for summon_index in range(summon_count):
		var spawn_position: Vector2 = _get_support_spawn_position(origin_position, summon_index, summon_count)
		var telegraph := _show_spawn_telegraph(spawn_position, &"boss")
		await get_tree().create_timer(max(0.3, spawn_warning_time * 1.45)).timeout
		if is_instance_valid(telegraph):
			telegraph.queue_free()

		var enemy_type_roll: float = randf()
		var enemy: EnemyBase
		if enemy_type_roll < 0.5:
			enemy = frog_scene.instantiate() as Frog
		else:
			enemy = slime_scene.instantiate() as Slime
		enemy.set_spawn_intro_enabled(true)
		enemy.set_wave_scaling(wave_number, true)
		enemy.global_position = spawn_position
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy), CONNECT_ONE_SHOT)
		add_child(enemy)
		active_enemies.append(enemy)
		enemy_spawned.emit(enemy, active_enemies.size(), current_wave_spawned)
		wave_state_changed.emit(current_wave_defeated, enemies_to_spawn, active_enemies.size())
		if summon_index < summon_count - 1:
			await get_tree().create_timer(0.24).timeout


func _get_support_spawn_position(origin_position: Vector2, summon_index: int, summon_count: int) -> Vector2:
	var spacing: float = 150.0
	var total_width: float = float(max(summon_count - 1, 0)) * spacing
	var offset_x: float = (float(summon_index) * spacing) - (total_width * 0.5)
	var desired_position: Vector2 = origin_position + Vector2(offset_x, 0.0)
	if not spawn_zones.is_empty():
		var zone_position: Vector2 = _get_nearest_spawn_zone_position(desired_position)
		return _snap_spawn_y_to_lane(_push_spawn_away_from_active_enemies(zone_position, MIN_ENEMY_SPAWN_SPACING + 16.0, 8))

	var clamped_position: Vector2 = desired_position
	if not spawn_ranges.is_empty():
		var best_range: Dictionary = spawn_ranges[0]
		var best_distance: float = INF
		for spawn_range in spawn_ranges:
			var range_min_x: float = float(spawn_range["x_min"])
			var range_max_x: float = float(spawn_range["x_max"])
			var clamped_x: float = clampf(desired_position.x, range_min_x, range_max_x)
			var distance: float = absf(desired_position.x - clamped_x)
			if distance < best_distance:
				best_distance = distance
				best_range = spawn_range
		clamped_position.x = clampf(desired_position.x, float(best_range["x_min"]), float(best_range["x_max"]))
		clamped_position.y = float(best_range["y"]) - SPAWN_HEIGHT_BIAS
	return _snap_spawn_y_to_lane(_push_spawn_away_from_active_enemies(clamped_position, MIN_ENEMY_SPAWN_SPACING + 16.0, 8))


func _get_nearest_spawn_zone_position(desired_position: Vector2) -> Vector2:
	var nearest_position: Vector2 = spawn_zones[0]
	var nearest_distance: float = desired_position.distance_squared_to(nearest_position)
	for spawn_zone in spawn_zones:
		var distance: float = desired_position.distance_squared_to(spawn_zone)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_position = spawn_zone
	return nearest_position


func _show_spawn_telegraph(spawn_position: Vector2, wave_kind: StringName) -> Line2D:
	var telegraph := Line2D.new()
	telegraph.closed = true
	telegraph.width = 5.0 if wave_kind == &"boss" else (3.0 if wave_kind == &"elite" else 2.0)
	telegraph.default_color = Color(1.0, 0.22, 0.22, 0.98) if wave_kind == &"boss" else (Color(1.0, 0.3, 0.3, 0.92) if wave_kind == &"elite" else Color(1.0, 0.82, 0.24, 0.88))
	telegraph.position = spawn_position + Vector2(0.0, 12.0)
	telegraph.points = _build_circle_points(48.0 if wave_kind == &"boss" else (20.0 if wave_kind == &"elite" else 16.0), 24)
	telegraph.modulate.a = 0.0
	telegraph.scale = Vector2.ONE * (0.8 if wave_kind == &"boss" else 0.65)
	telegraph.z_index = 50
	add_child(telegraph)

	var tween := create_tween()
	tween.tween_property(telegraph, "modulate:a", 1.0, spawn_warning_time * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(telegraph, "scale", Vector2.ONE, spawn_warning_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(telegraph, "modulate:a", 0.0, spawn_warning_time * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	return telegraph


func _finish_boss_wave_after_boss_death(defeated_boss: BossDragon = null) -> void:
	print("finishing boss wave: ", wave_number, " total target: ", enemies_to_spawn, " defeated: ", current_wave_defeated, " active: ", active_enemies.size())
	for enemy in active_enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if enemy == scene_boss:
			if scene_boss.has_method("deactivate_for_wave"):
				scene_boss.deactivate_for_wave()
			else:
				scene_boss.visible = false
				scene_boss.set_physics_process(false)
			continue
		enemy.queue_free()

	if defeated_boss != null and is_instance_valid(defeated_boss):
		if defeated_boss == scene_boss and scene_boss.has_method("deactivate_for_wave"):
			scene_boss.deactivate_for_wave()

	active_enemies.clear()
	current_wave_defeated = enemies_to_spawn
	wave_state_changed.emit(current_wave_defeated, enemies_to_spawn, active_enemies.size())
	boss_health_changed.emit(0, 0)
	boss_state_changed.emit("", 0, 0)
	print("boss wave cleaned up, moving to next wave")
	if is_waiting_for_next_wave:
		return
	is_spawning_wave = false
	wave_completed.emit(wave_number)
	all_enemies_defeated.emit(wave_number)
	_schedule_next_wave()


func _build_circle_points(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var angle := TAU * float(point_index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func update_spawn_zones(zones: Array[Vector2]) -> void:
	spawn_zones = zones


func get_active_enemies_count() -> int:
	return active_enemies.size()


func get_active_enemies() -> Array[EnemyBase]:
	return active_enemies


func pause_spawning() -> void:
	ENABLE_SPAWNING = false


func resume_spawning() -> void:
	ENABLE_SPAWNING = true
	if WAVE_BASED and active_enemies.is_empty() and not is_waiting_for_next_wave and not is_spawning_wave:
		_start_wave()


func clear_all_enemies() -> void:
	wave_sequence_id += 1
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			if enemy == scene_boss and scene_boss != null:
				if scene_boss.has_method("deactivate_for_wave"):
					scene_boss.deactivate_for_wave()
				else:
					scene_boss.visible = false
					scene_boss.set_physics_process(false)
			else:
				enemy.queue_free()
	active_enemies.clear()
	current_wave_spawned = 0
	current_wave_defeated = 0
	current_boss = null
	current_boss_name = ""


func force_wave(target_wave: int) -> void:
	var safe_wave: int = clampi(target_wave, 1, MAX_TEST_WAVE)
	ENABLE_SPAWNING = true
	is_spawning_wave = false
	is_waiting_for_next_wave = false
	clear_all_enemies()
	enemies_to_spawn = 0
	current_wave_kind = &"normal"
	elite_wave_active = false
	wave_number = safe_wave - 1
	wave_started.emit(wave_number, 0, current_wave_kind)
	wave_state_changed.emit(0, 0, 0)
	call_deferred("_start_wave")


func get_stats() -> Dictionary:
	return {
		"wave": wave_number,
		"active_enemies": get_active_enemies_count(),
		"enemies_to_spawn": enemies_to_spawn,
		"wave_defeated": current_wave_defeated,
		"wave_kind": current_wave_kind,
		"boss_active": is_instance_valid(current_boss),
		"boss_name": current_boss_name,
		"elite_wave": elite_wave_active,
		"spawn_zones": spawn_zones.size(),
		"max_wave": MAX_TEST_WAVE,
		"enabled": ENABLE_SPAWNING
	}


func _is_boss_wave(wave: int) -> bool:
	return wave >= 10 and wave % 10 == 0
