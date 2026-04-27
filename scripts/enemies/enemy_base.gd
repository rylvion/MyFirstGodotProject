extends CharacterBody2D
class_name EnemyBase

const WORLD_COLLISION_LAYER: int = 1
const PLAYER_COLLISION_LAYER: int = 2
const ENEMY_COLLISION_LAYER: int = 4
const ENEMY_COLLISION_MASK: int = WORLD_COLLISION_LAYER | PLAYER_COLLISION_LAYER
const OUT_OF_BOUNDS_KILL_Y: float = 1200.0

@export var SPEED: float = 50.0
@export var DAMAGE: float = 3.0
@export var GOLD: int = 5
@export var DETECTION_RANGE: float = 104.0
@export var patrol_radius: float = 120.0
@export var patrol_pause_time: float = 0.2
@export var patrol_speed_multiplier: float = 0.72
@export var movement_sfx_key: StringName = &""
@export var movement_sfx_cooldown: float = 0.6
@export var movement_sfx_volume_db: float = -4.5

var base_speed: float = 0.0
var base_damage: float = 0.0
var base_gold: int = 0
var base_sprite_scale: Vector2 = Vector2.ONE

var player: CharacterBody2D = null
var chase: bool = false
var death: bool = false
var gravity: float = 980.0
var pending_wave: int = 1
var pending_elite: bool = false
var is_elite: bool = false
var _current_animation: StringName = &""
var patrol_origin_x: float = 0.0
var patrol_direction: float = 1.0
var patrol_pause_timer: float = 0.0
var spawn_intro_enabled: bool = false
var movement_sfx_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var body_collision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var detection_area: Area2D = get_node_or_null("PlayerDetection") as Area2D
@onready var death_area: Area2D = get_node_or_null("PlayerDeath") as Area2D
@onready var collision_area: Area2D = get_node_or_null("PlayerCollision") as Area2D

signal defeated(gold_amount: int, enemy: EnemyBase)
signal player_damaged(damage_amount: float)


func _ready() -> void:
	collision_layer = ENEMY_COLLISION_LAYER
	collision_mask = ENEMY_COLLISION_MASK
	_configure_area_masks()
	_capture_base_stats()
	_apply_detection_range()
	patrol_origin_x = global_position.x
	patrol_direction = -1.0 if randf() < 0.5 else 1.0
	patrol_pause_timer = randf_range(0.0, patrol_pause_time)
	_apply_wave_scaling()
	await _play_spawn_intro_if_available()
	_play_animation(&"idle")


func _play_spawn_intro_if_available() -> void:
	if spawn_intro_enabled == false:
		return
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(&"summon"):
		return

	_set_active_interactions(false)
	set_physics_process(false)
	# Force one-shot summon intro even if the scene animation is configured to loop.
	sprite.sprite_frames.set_animation_loop(&"summon", false)
	_current_animation = &"summon"
	sprite.play(&"summon")

	var summon_duration: float = _get_animation_duration(sprite.sprite_frames, &"summon")
	if summon_duration > 0.0:
		await get_tree().create_timer(summon_duration).timeout
	set_physics_process(true)
	_set_active_interactions(true)


func set_spawn_intro_enabled(enabled: bool) -> void:
	spawn_intro_enabled = enabled


func _get_animation_duration(frames: SpriteFrames, animation_name: StringName) -> float:
	if frames == null or not frames.has_animation(animation_name):
		return 0.0

	var frame_count: int = frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return 0.0

	var fps: float = maxf(frames.get_animation_speed(animation_name), 0.001)
	var duration: float = 0.0
	for frame_index in range(frame_count):
		duration += frames.get_frame_duration(animation_name, frame_index) / fps
	return duration


func _physics_process(delta: float) -> void:
	if death:
		return
	if global_position.y >= OUT_OF_BOUNDS_KILL_Y:
		_die(false)
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if player != null and not is_instance_valid(player):
		player = null
		chase = false

	if chase and player != null:
		_update_chase_movement()
	else:
		_update_patrol_movement(delta)
	_process_movement_sfx(delta)

	move_and_slide()
	if not chase and is_on_wall():
		_begin_patrol_pause(-patrol_direction)


func _play_animation(animation_name: StringName) -> void:
	if sprite == null or death:
		return
	if sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation(animation_name) == false:
		if animation_name != &"idle" and sprite.sprite_frames.has_animation(&"idle"):
			animation_name = &"idle"
		else:
			return
	if _current_animation == animation_name:
		return
	_current_animation = animation_name
	sprite.play(animation_name)


func _apply_wave_scaling() -> void:
	var wave_index: int = max(pending_wave - 1, 0)
	var speed_scale: float = 1.0 + min(0.06 * wave_index, 1.10)
	var damage_scale: float = 1.0 + min(0.08 * wave_index, 2.00)
	var gold_scale: float = 1.0 + (0.05 * wave_index)

	if pending_elite:
		speed_scale *= 1.15
		damage_scale *= 1.35
		gold_scale *= 1.75

	SPEED = base_speed * speed_scale
	DAMAGE = base_damage * damage_scale
	GOLD = int(round(base_gold * gold_scale))
	is_elite = pending_elite

	if sprite != null:
		sprite.modulate = Color(1.0, 0.72, 0.72, 1.0) if is_elite else Color.WHITE
		sprite.scale = base_sprite_scale * (1.08 if is_elite else 1.0)


func _capture_base_stats() -> void:
	if base_speed == 0.0:
		base_speed = SPEED
		base_damage = DAMAGE
		base_gold = GOLD
		if sprite != null:
			base_sprite_scale = sprite.scale


func _apply_detection_range() -> void:
	if detection_area == null:
		return

	for shape_node in detection_area.get_children():
		if shape_node is CollisionShape2D:
			var collision_shape: CollisionShape2D = shape_node as CollisionShape2D
			if collision_shape.shape is CircleShape2D:
				var detection_shape: CircleShape2D = collision_shape.shape as CircleShape2D
				detection_shape.radius = DETECTION_RANGE


func _configure_area_masks() -> void:
	for area in [detection_area, death_area, collision_area]:
		if area == null:
			continue
		area.collision_layer = 0
		area.collision_mask = PLAYER_COLLISION_LAYER


func _set_active_interactions(is_active: bool) -> void:
	if body_collision != null:
		body_collision.set_deferred("disabled", not is_active)
	for area in [detection_area, death_area, collision_area]:
		if area == null:
			continue
		area.set_deferred("monitoring", is_active)
		area.set_deferred("monitorable", is_active)
		for shape in area.get_children():
			if shape is CollisionShape2D:
				(shape as CollisionShape2D).set_deferred("disabled", not is_active)


func _update_chase_movement() -> void:
	var direction_x: float = signf(player.global_position.x - global_position.x)
	if direction_x == 0.0:
		direction_x = patrol_direction

	patrol_direction = direction_x
	if sprite != null:
		sprite.flip_h = direction_x > 0.0
	_play_animation(&"attack")
	velocity.x = direction_x * SPEED


func _update_patrol_movement(delta: float) -> void:
	if patrol_radius <= 0.0:
		velocity.x = 0.0
		_play_animation(&"idle")
		return

	if patrol_pause_timer > 0.0:
		patrol_pause_timer = maxf(patrol_pause_timer - delta, 0.0)
		velocity.x = 0.0
		_play_animation(&"idle")
		return

	var left_bound: float = patrol_origin_x - patrol_radius
	var right_bound: float = patrol_origin_x + patrol_radius
	if global_position.x <= left_bound and patrol_direction < 0.0:
		_begin_patrol_pause(1.0)
		return
	if global_position.x >= right_bound and patrol_direction > 0.0:
		_begin_patrol_pause(-1.0)
		return

	if sprite != null:
		sprite.flip_h = patrol_direction > 0.0
	_play_animation(&"attack")
	velocity.x = patrol_direction * SPEED * patrol_speed_multiplier


func _begin_patrol_pause(next_direction: float) -> void:
	if next_direction != 0.0:
		patrol_direction = next_direction
	patrol_pause_timer = patrol_pause_time
	velocity.x = 0.0
	_play_animation(&"idle")


func _process_movement_sfx(delta: float) -> void:
	if movement_sfx_key == &"":
		return

	movement_sfx_timer = maxf(movement_sfx_timer - delta, 0.0)
	if movement_sfx_timer > 0.0:
		return
	if absf(velocity.x) <= 6.0:
		return

	SoundManager.play_sfx(movement_sfx_key, movement_sfx_volume_db)
	movement_sfx_timer = maxf(movement_sfx_cooldown, 0.1)


func _on_player_detection_body_entered(body: Node2D) -> void:
	if body.name == "player":
		player = body
		chase = true
		patrol_pause_timer = 0.0


func _on_player_detection_body_exited(body: Node2D) -> void:
	if body.name == "player":
		player = null
		chase = false
		_begin_patrol_pause(-patrol_direction)


func _on_player_death_body_entered(body: Node2D) -> void:
	if body.name == "player" and not death:
		if take_hit(&"stomp", true):
			Game.mark_tutorial_step(&"stomp")
			if body.has_method("stomp_bounce"):
				body.call("stomp_bounce")


func _on_player_collision_body_entered(body: Node2D) -> void:
	if body.name == "player" and not death:
		Game.playerHP = max(Game.playerHP - int(DAMAGE), 0)
		player_damaged.emit(int(DAMAGE))
		_handle_player_collision()

func _die(gold_reward: bool = false) -> void:
	if death:
		return

	death = true
	chase = false
	SoundManager.play_sfx(&"enemy_explode", -2.5)
	var gold_amount := GOLD if gold_reward else 0

	if gold_amount > 0:
		Game.gold += gold_amount
		Game.apply_kill_lifesteal()

	defeated.emit(gold_amount, self)
	set_physics_process(false)
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	if body_collision != null:
		body_collision.set_deferred("disabled", true)

	for area in [detection_area, death_area, collision_area]:
		if area == null:
			continue
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		for shape in area.get_children():
			if shape is CollisionShape2D:
				shape.set_deferred("disabled", true)

	if sprite != null:
		_current_animation = &"death"
		sprite.play("death")
		await sprite.animation_finished

	queue_free()


func take_hit(_hit_source: StringName, gold_reward_on_defeat: bool = true) -> bool:
	if death:
		return false

	_die(gold_reward_on_defeat)
	return true


func _handle_player_collision() -> void:
	_die(false)


func set_wave_scaling(wave_number: int, elite_wave: bool = false) -> void:
	_capture_base_stats()
	pending_wave = max(wave_number, 1)
	pending_elite = elite_wave

	if is_node_ready():
		_apply_wave_scaling()


func get_stats() -> Dictionary:
	return {
		"speed": SPEED,
		"damage": DAMAGE,
		"gold": GOLD,
		"detection_range": DETECTION_RANGE,
		"wave": pending_wave,
		"is_elite": is_elite,
		"patrol_radius": patrol_radius,
		"patrol_pause_time": patrol_pause_time,
		"patrol_speed_multiplier": patrol_speed_multiplier
	}
	
