extends "res://scripts/enemies/enemy_base.gd"
class_name BossDragon

const BOSS_COLLISION_LAYER: int = 8
const BOSS_COLLISION_MASK: int = WORLD_COLLISION_LAYER
const HIT_COOLDOWN: float = 0.35
const WINDUP_DURATION: float = 0.45
const RECOVER_DURATION: float = 0.55
const SUMMON_DURATION: float = 0.8
const JUMP_LAUNCH_VELOCITY: float = -440.0
const SLAM_HORIZONTAL_SPEED: float = 135.0
const SLAM_GRAVITY_MULTIPLIER: float = 1.85
const DIRECT_IMPACT_RADIUS: float = 62.0
const SHOCKWAVE_RADIUS: float = 118.0
const SLAM_STUN_DURATION: float = 0.9
const HITSTOP_TIME_SCALE: float = 0.08
const HITSTOP_DURATION: float = 0.045
const SUMMON_FLASH_DURATION: float = 0.12
const SAME_LANE_THRESHOLD: float = 88.0
const TAIL_TRIGGER_RANGE: float = 190.0
const MIN_FIREBALL_RANGE: float = 120.0
const NEUTRAL_GAP_DURATION: float = 0.30
const FIREBALL_INTENT_DURATION: float = 0.25
const FIREBALL_TELEGRAPH_DURATION: float = 1.00
const FIREBALL_EXECUTION_DURATION: float = 0.15
const FIREBALL_RECOVERY_DURATION: float = 0.55
const TAIL_INTENT_DURATION: float = 0.20
const TAIL_TELEGRAPH_DURATION: float = 0.48
const TAIL_EXECUTION_DURATION: float = 0.62
const TAIL_HITBOX_ACTIVE_DURATION: float = 0.30
const TAIL_RECOVERY_DURATION: float = 0.75
const BOSS_GEM_DROP_MIN: int = 5
const BOSS_GEM_DROP_MAX: int = 10
const BOSS_GEM_TOTAL_GOLD: int = 100
const BOSS_CHASE_STOP_DISTANCE: float = 92.0
const SUMMON_INTENT_DURATION: float = 0.25
const SUMMON_TELEGRAPH_DURATION: float = 0.45
const SUMMON_EXECUTION_DURATION: float = 0.25
const SUMMON_RECOVERY_DURATION: float = 0.85
const BOSS_FIREBALL_DAMAGE_MULTIPLIER: float = 1.20
const BOSS_FIREBALL_VERTICAL_OFFSET: float = 12.0
const BREATH_ATTACK_ANIMATION: StringName = &"short_ranged_dragon_breath"
const LEGACY_BREATH_ATTACK_ANIMATION: StringName = &"attack"
const FIREBALL_ATTACK_LABEL: String = "Fireball"
const TAIL_ATTACK_LABEL: String = "Tail Swoop"
const SUMMON_ATTACK_LABEL: String = "Summon"
const GROWL_INTERVAL_MIN: float = 2.8
const GROWL_INTERVAL_MAX: float = 4.2
const LEFT_BODY_POSITION: Vector2 = Vector2(4.0, 35.0)
const RIGHT_BODY_POSITION: Vector2 = Vector2(-136.0, 35.0)
const LEFT_BREATH_POSITION: Vector2 = Vector2(-152.0, 40.0)
const RIGHT_BREATH_POSITION: Vector2 = Vector2(-48.0, 40.0)
const LEFT_TAIL_POSITION: Vector2 = Vector2(-93.0, 65.0)
const RIGHT_TAIL_POSITION: Vector2 = Vector2(-30.0, 65.0)
const LEFT_DETECTION_POSITION: Vector2 = Vector2.ZERO
const RIGHT_DETECTION_POSITION: Vector2 = Vector2(-85.0, 0.0)
const LEFT_JUMP_POSITION: Vector2 = Vector2(22.0, 24.0)
const RIGHT_JUMP_POSITION: Vector2 = Vector2(-130.0, 24.0)

enum BossVariant {
	DRAGON,
	CORRUPTED,
	CORRUPTED_ELITE,
}

enum BossState {
	CHASE,
	WINDUP,
	ATTACK,
	RECOVER,
	SUMMON,
}

enum QueuedAttack {
	NONE,
	FIREBALL,
	TAIL_SWOOP,
}

enum WindupStage {
	INTENT,
	TELEGRAPH,
}

enum SummonStage {
	INTENT,
	TELEGRAPH,
	EXECUTION,
	RECOVER,
}

static var _cached_boss_frames: SpriteFrames = null

signal health_changed(current_hits: int, max_hits: int)
signal attack_used(attack_name: String)

var boss_index: int = 1
var boss_variant: int = BossVariant.DRAGON
var max_hits: int = 10
var current_hits: int = 10
var hit_cooldown_timer: float = 0.0
var phase_two_active: bool = false
var phase_three_active: bool = false
var first_summon_done: bool = false
var second_summon_done: bool = false
var state: int = BossState.CHASE
var state_timer: float = 0.0
var queued_attack: int = QueuedAttack.NONE
var windup_stage: int = WindupStage.INTENT
var summon_stage: int = SummonStage.INTENT
var fireball_cooldown_timer: float = 0.0
var neutral_gap_timer: float = 0.0
var current_attack_name: String = ""
var current_recovery_duration: float = 0.0
var tail_hitbox_live: bool = false
var summon_spawn_count: int = 0
var spawner_ref: EnemySpawner = null
var hitstop_active: bool = false
var intimidation_sfx_timer: float = 0.0
var default_collision_layer: int = 0
var default_collision_mask: int = 0
var breath_animation_name: StringName = BREATH_ATTACK_ANIMATION
@onready var summon_node: Node2D = get_node_or_null("Summoning") as Node2D
@onready var summon_sprite: AnimatedSprite2D = get_node_or_null("Summoning/AnimatedSprite2D") as AnimatedSprite2D
@onready var breath_root: Node2D = get_node_or_null("breath") as Node2D
@onready var breath_area: Area2D = get_node_or_null("breath/PlayerCollision") as Area2D
@onready var breath_shape: CollisionShape2D = get_node_or_null("breath/PlayerCollision/dragon_breath") as CollisionShape2D
@onready var fireball_warning_root: Node2D = get_node_or_null("long_range_fireball") as Node2D
@onready var fireball_warning_area: Area2D = get_node_or_null("long_range_fireball/PlayerCollision") as Area2D
@onready var fireball_warning_shape: CollisionShape2D = get_node_or_null("long_range_fireball/PlayerCollision/fireball") as CollisionShape2D
@onready var tail_root: Node2D = get_node_or_null("TailSwoop") as Node2D
@onready var tail_area: Area2D = get_node_or_null("TailSwoop/PlayerCollision") as Area2D
@onready var tail_shape: CollisionShape2D = get_node_or_null("TailSwoop/PlayerCollision/sweep_the_floor") as CollisionShape2D
@onready var jump_shape: CollisionShape2D = get_node_or_null("PlayerDeath/jump_part") as CollisionShape2D
@onready var detection_shape: CollisionShape2D = get_node_or_null("PlayerDetection/detection_radius") as CollisionShape2D
@onready var boss_fireball_scene: PackedScene = preload("res://scenes/projectiles/big_fireball.tscn")
@onready var boss_gem_scene: PackedScene = preload("res://scenes/collectables/gems.tscn")

var boss_projectile: Fireball = null
var fireball_preview: Line2D = null
var tail_preview: Line2D = null
var summon_preview: Line2D = null


func _ready() -> void:
	# boss setup
	body_collision = get_node_or_null("hitbox") as CollisionShape2D
	_ensure_boss_frames_loaded()
	_resolve_breath_animation_name()
	SPEED = 78.0
	DAMAGE = 14.0
	GOLD = 90
	DETECTION_RANGE = 300.0
	patrol_radius = 92.0
	patrol_pause_time = 0.28
	patrol_speed_multiplier = 0.62
	super._ready()
	default_collision_layer = BOSS_COLLISION_LAYER
	default_collision_mask = BOSS_COLLISION_MASK
	_build_attack_previews()
	_apply_manual_facing_offsets()
	_sync_hitboxes_to_facing()
	fireball_cooldown_timer = _roll_fireball_cooldown() * 0.55
	intimidation_sfx_timer = randf_range(GROWL_INTERVAL_MIN, GROWL_INTERVAL_MAX)
	health_changed.emit(current_hits, max_hits)
	_set_summon_visible(false)
	_clear_attack_hitboxes()
	deactivate_for_wave()


func activate_for_wave(wave_number: int) -> void:
	print("boss active for wave ", wave_number)
	set_wave_scaling(wave_number, false)
	death = false
	chase = false
	player = null
	velocity = Vector2.ZERO
	state = BossState.CHASE
	state_timer = 0.0
	queued_attack = QueuedAttack.NONE
	windup_stage = WindupStage.INTENT
	summon_stage = SummonStage.INTENT
	intimidation_sfx_timer = randf_range(1.8, 3.2)
	current_attack_name = ""
	current_recovery_duration = 0.0
	hit_cooldown_timer = 0.0
	fireball_cooldown_timer = _roll_fireball_cooldown() * 0.55
	neutral_gap_timer = 0.0
	tail_hitbox_live = false
	_clear_attack_hitboxes()
	_set_summon_visible(false)
	_clear_summon_preview()

	visible = true
	set_process(true)
	set_physics_process(true)
	collision_layer = default_collision_layer
	collision_mask = default_collision_mask

	if body_collision != null:
		body_collision.set_deferred("disabled", false)

	for area in [detection_area]:
		if area == null:
			continue
		area.set_deferred("monitoring", true)
		area.set_deferred("monitorable", true)
		for shape in area.get_children():
			if shape is CollisionShape2D:
				shape.set_deferred("disabled", false)

	for area in [breath_area, fireball_warning_area]:
		if area != null:
			area.set_deferred("monitoring", false)
			area.set_deferred("monitorable", false)
	for shape in [breath_shape, fireball_warning_shape]:
		if shape != null:
			shape.set_deferred("disabled", true)
	if tail_area != null:
		tail_area.set_deferred("monitoring", false)
		tail_area.set_deferred("monitorable", false)
	if tail_shape != null:
		tail_shape.set_deferred("disabled", true)

	if sprite != null:
		sprite.visible = true
		_current_animation = &""
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(breath_animation_name):
			sprite.sprite_frames.set_animation_loop(breath_animation_name, false)
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(&"tail_swoop"):
			sprite.sprite_frames.set_animation_loop(&"tail_swoop", false)
		_play_animation(&"idle")

	SoundManager.play_music(&"boss_soundtrack", 5.0)
	health_changed.emit(current_hits, max_hits)
	SoundManager.play_sfx(&"roar", -10.0, 1.0, false)


func deactivate_for_wave() -> void:
	player = null
	chase = false
	velocity = Vector2.ZERO
	queued_attack = QueuedAttack.NONE
	current_attack_name = ""
	tail_hitbox_live = false
	_clear_attack_hitboxes()
	_set_summon_visible(false)
	_clear_summon_preview()
	collision_layer = 0
	collision_mask = 0
	if body_collision != null:
		body_collision.set_deferred("disabled", true)
	for area in [detection_area, breath_area, fireball_warning_area, tail_area]:
		if area == null:
			continue
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		for shape in area.get_children():
			if shape is CollisionShape2D:
				shape.set_deferred("disabled", true)
	set_physics_process(false)
	visible = false


func assign_spawner(next_spawner: EnemySpawner) -> void:
	spawner_ref = next_spawner


func _physics_process(delta: float) -> void:
	if death:
		return
	if global_position.y >= OUT_OF_BOUNDS_KILL_Y:
		print("boss fell out of bounds")
		_die(false)
		return

	hit_cooldown_timer = maxf(hit_cooldown_timer - delta, 0.0)
	fireball_cooldown_timer = maxf(fireball_cooldown_timer - delta, 0.0)
	neutral_gap_timer = maxf(neutral_gap_timer - delta, 0.0)
	_process_intimidation_sfx(delta)

	if player != null and not is_instance_valid(player):
		player = null
		chase = false

	match state:
		BossState.CHASE:
			_run_ground_movement(delta)
			_try_trigger_attack_or_summon()
		BossState.WINDUP:
			_run_windup_state(delta)
		BossState.ATTACK:
			_run_attack_state(delta)
		BossState.RECOVER:
			_run_recover_state(delta)
		BossState.SUMMON:
			_run_summon_state(delta)

	_apply_body_contact_damage()


func set_wave_scaling(wave_number: int, _elite_wave: bool = false) -> void:
	_capture_base_stats()#
	pending_wave = max(wave_number, 1)
	pending_elite = false
	boss_index = _get_boss_index(pending_wave)
	boss_variant = _get_boss_variant(boss_index)
	max_hits = _get_base_hits_for_index(boss_index)
	current_hits = max_hits
	phase_two_active = false
	phase_three_active = false
	first_summon_done = false
	second_summon_done = false
	hit_cooldown_timer = 0.0
	fireball_cooldown_timer = _roll_fireball_cooldown()
	neutral_gap_timer = 0.0
	state = BossState.CHASE
	state_timer = 0.0
	queued_attack = QueuedAttack.NONE
	current_attack_name = ""
	tail_hitbox_live = false

	if is_node_ready():
		_apply_wave_scaling()
		health_changed.emit(current_hits, max_hits)


func _apply_wave_scaling() -> void:
	_capture_base_stats()

	var speed_scale: float = 1.0 + min(0.04 * float(max(boss_index - 1, 0)), 0.40)
	var damage_scale: float = 1.0 + min(0.14 * float(max(boss_index - 1, 0)), 0.90)
	var gold_scale: float = 1.0 + (0.20 * float(max(boss_index - 1, 0)))

	if phase_two_active:
		speed_scale *= 1.10
		damage_scale *= 1.10
	if phase_three_active:
		speed_scale *= 1.08
		damage_scale *= 1.15

	match boss_variant:
		BossVariant.CORRUPTED:
			speed_scale *= 1.06
			damage_scale *= 1.10
			gold_scale *= 1.15
		BossVariant.CORRUPTED_ELITE:
			speed_scale *= 1.12
			damage_scale *= 1.18
			gold_scale *= 1.30

	SPEED = base_speed * speed_scale
	DAMAGE = base_damage * damage_scale
	GOLD = int(round(base_gold * gold_scale))
	is_elite = false

	if sprite != null:
		sprite.modulate = _get_variant_color()
		sprite.scale = base_sprite_scale * _get_variant_scale_multiplier()


func _run_ground_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if chase and player != null:
		_update_chase_movement()
	else:
		_update_patrol_movement(delta)

	_sync_hitboxes_to_facing()
	move_and_slide()
	if not chase and is_on_wall():
		_begin_patrol_pause(-patrol_direction)


func _update_chase_movement() -> void:
	if player == null:
		return

	var horizontal_gap: float = player.global_position.x - global_position.x
	if absf(horizontal_gap) <= BOSS_CHASE_STOP_DISTANCE:
		velocity.x = 0.0
		_play_animation(&"idle")
		return

	var direction_x: float = signf(horizontal_gap)
	if direction_x == 0.0:
		direction_x = patrol_direction

	patrol_direction = direction_x
	if sprite != null:
		sprite.flip_h = direction_x > 0.0
	_play_animation(&"idle")
	velocity.x = direction_x * SPEED


func _try_trigger_attack_or_summon() -> void:
	if neutral_gap_timer > 0.0:
		return

	if not first_summon_done and current_hits <= int(ceil(float(max_hits) * 0.65)):
		first_summon_done = true
		_enter_summon_state()
		return

	if not second_summon_done and current_hits <= int(ceil(float(max_hits) * 0.30)):
		second_summon_done = true
		_enter_summon_state()
		return

	if player == null or not is_instance_valid(player):
		return

	_face_player_once()
	var next_attack: int = _select_attack()
	if next_attack == QueuedAttack.NONE:
		return

	_enter_windup_state(next_attack)


func _enter_windup_state(next_attack: int) -> void:
	queued_attack = next_attack
	state = BossState.WINDUP
	windup_stage = WindupStage.INTENT
	state_timer = _get_attack_intent_duration(queued_attack)
	velocity.x = 0.0
	current_attack_name = _get_attack_display_name(queued_attack)
	_face_player_once()
	_clear_attack_hitboxes()
	_play_animation(&"idle")


func _enter_attack_state() -> void:
	state = BossState.ATTACK
	state_timer = _get_attack_execution_duration(queued_attack)
	velocity = Vector2.ZERO
	set_attack_hitbox_live(queued_attack)
	match queued_attack:
		QueuedAttack.FIREBALL:
			_play_animation(breath_animation_name)
			_spawn_boss_fireball()
			fireball_cooldown_timer = _roll_fireball_cooldown()
		QueuedAttack.TAIL_SWOOP:
			if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(&"tail_swoop"):
				_current_animation = &"tail_swoop"
				sprite.play(&"tail_swoop")
			else:
				_play_animation(&"attack")
			_deactivate_tail_hitbox_after_delay()
			call_deferred("_apply_tail_swoop_if_overlapping")


func _deactivate_tail_hitbox_after_delay() -> void:
	await get_tree().create_timer(TAIL_HITBOX_ACTIVE_DURATION).timeout
	if death:
		return
	if state != BossState.ATTACK or queued_attack != QueuedAttack.TAIL_SWOOP:
		return
	tail_hitbox_live = false
	_set_preview_state(tail_preview, tail_area, false, Color(1.0, 1.0, 1.0, 0.0), false)


func _run_windup_state(delta: float) -> void:
	velocity.x = 0.0
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	_sync_hitboxes_to_facing()
	move_and_slide()

	state_timer = maxf(state_timer - delta, 0.0)
	if state_timer > 0.0:
		return

	if windup_stage == WindupStage.INTENT:
		_begin_attack_telegraph()
		return

	_enter_attack_state()


func _run_attack_state(delta: float) -> void:
	state_timer = maxf(state_timer - delta, 0.0)
	velocity.x = 0.0
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	_sync_hitboxes_to_facing()
	move_and_slide()
	if state_timer <= 0.0:
		_enter_recover_state()


func _run_recover_state(delta: float) -> void:
	state_timer = maxf(state_timer - delta, 0.0)
	velocity.x = 0.0
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	_sync_hitboxes_to_facing()
	move_and_slide()
	if state_timer <= 0.0:
		state = BossState.CHASE
		queued_attack = QueuedAttack.NONE
		current_attack_name = ""
		current_recovery_duration = 0.0
		_play_animation(&"idle")


func _enter_summon_state() -> void:
	state = BossState.SUMMON
	summon_stage = SummonStage.INTENT
	state_timer = SUMMON_INTENT_DURATION
	velocity = Vector2.ZERO
	summon_spawn_count = 2 if boss_index <= 1 else 3
	current_attack_name = SUMMON_ATTACK_LABEL
	_clear_attack_hitboxes()
	_set_summon_visible(false)
	_clear_summon_preview()
	_play_animation(&"idle")


func _run_summon_state(delta: float) -> void:
	state_timer = maxf(state_timer - delta, 0.0)
	velocity.x = 0.0
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	_sync_hitboxes_to_facing()
	move_and_slide()
	if state_timer > 0.0:
		return

	match summon_stage:
		SummonStage.INTENT:
			summon_stage = SummonStage.TELEGRAPH
			state_timer = SUMMON_TELEGRAPH_DURATION
			SoundManager.play_sfx(&"roar", -4.5)
			attack_used.emit(SUMMON_ATTACK_LABEL)
			_set_summon_visible(true)
			_show_summon_feedback()
			_set_summon_breath_hitbox_active(true)
		SummonStage.TELEGRAPH:
			summon_stage = SummonStage.EXECUTION
			state_timer = SUMMON_EXECUTION_DURATION
			if spawner_ref != null:
				var summon_origin: Vector2 = global_position + Vector2(0.0, -120.0)
				spawner_ref.spawn_elite_pack(summon_spawn_count, summon_origin)
		SummonStage.EXECUTION:
			summon_stage = SummonStage.RECOVER
			state_timer = SUMMON_RECOVERY_DURATION
			_set_summon_breath_hitbox_active(false)
		SummonStage.RECOVER:
			state = BossState.CHASE
			summon_stage = SummonStage.INTENT
			current_attack_name = ""
			neutral_gap_timer = NEUTRAL_GAP_DURATION
			_set_summon_visible(false)
			_clear_summon_preview()
			_play_animation(&"idle")


func _play_animation(animation_name: StringName) -> void:
	if animation_name == breath_animation_name and sprite != null and not death:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name):
			sprite.sprite_frames.set_animation_loop(animation_name, false)
		if _current_animation != animation_name or sprite.animation != animation_name:
			_current_animation = animation_name
			sprite.play(animation_name)
		elif sprite.is_playing() == false:
			sprite.play(animation_name)
		return

	super._play_animation(animation_name)


func _begin_attack_telegraph() -> void:
	windup_stage = WindupStage.TELEGRAPH
	state_timer = _get_attack_telegraph_duration(queued_attack)
	attack_used.emit(current_attack_name)
	show_attack_hitbox_preview(queued_attack)

	match queued_attack:
		QueuedAttack.FIREBALL:
			SoundManager.play_sfx(&"growl", 60.0, 1.0, false)
			_play_animation(breath_animation_name)
		QueuedAttack.TAIL_SWOOP:
			if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(&"tail_swoop"):
				_current_animation = &"tail_swoop"
				sprite.play(&"tail_swoop")
				sprite.stop()
				sprite.frame = 0
			else:
				_play_animation(&"idle")


func _enter_recover_state() -> void:
	state = BossState.RECOVER
	current_recovery_duration = _get_attack_recovery_duration(queued_attack)
	state_timer = current_recovery_duration
	tail_hitbox_live = false
	_clear_attack_hitboxes()
	_play_animation(&"idle")
	neutral_gap_timer = NEUTRAL_GAP_DURATION


func _select_attack() -> int:
	var same_lane: bool = _is_player_in_same_lane()
	var horizontal_distance: float = _get_horizontal_distance_to_player()
	if same_lane and horizontal_distance <= TAIL_TRIGGER_RANGE and _is_player_inside_tail_hitbox():
		return QueuedAttack.TAIL_SWOOP
	if horizontal_distance >= MIN_FIREBALL_RANGE and fireball_cooldown_timer <= 0.0 and not _boss_fireball_is_active():
		return QueuedAttack.FIREBALL
	return QueuedAttack.NONE


func _face_player_once() -> void:
	if player == null or sprite == null:
		return

	var direction_x: float = signf(player.global_position.x - global_position.x)
	if direction_x == 0.0:
		direction_x = patrol_direction
	patrol_direction = direction_x
	sprite.flip_h = direction_x > 0.0
	_sync_hitboxes_to_facing()


func _is_player_in_same_lane() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	return absf(player.global_position.y - global_position.y) <= SAME_LANE_THRESHOLD


func _get_horizontal_distance_to_player() -> float:
	if player == null or not is_instance_valid(player):
		return INF
	return absf(player.global_position.x - global_position.x)


func _get_attack_display_name(attack_type: int) -> String:
	match attack_type:
		QueuedAttack.FIREBALL:
			return FIREBALL_ATTACK_LABEL
		QueuedAttack.TAIL_SWOOP:
			return TAIL_ATTACK_LABEL
	return ""


func _get_attack_intent_duration(attack_type: int) -> float:
	match attack_type:
		QueuedAttack.FIREBALL:
			return FIREBALL_INTENT_DURATION
		QueuedAttack.TAIL_SWOOP:
			return TAIL_INTENT_DURATION
	return 0.0


func _get_attack_telegraph_duration(attack_type: int) -> float:
	match attack_type:
		QueuedAttack.FIREBALL:
			return FIREBALL_TELEGRAPH_DURATION
		QueuedAttack.TAIL_SWOOP:
			return TAIL_TELEGRAPH_DURATION
	return 0.0


func _get_attack_execution_duration(attack_type: int) -> float:
	match attack_type:
		QueuedAttack.FIREBALL:
			return FIREBALL_EXECUTION_DURATION
		QueuedAttack.TAIL_SWOOP:
			return TAIL_EXECUTION_DURATION
	return 0.0


func _get_attack_recovery_duration(attack_type: int) -> float:
	match attack_type:
		QueuedAttack.FIREBALL:
			return FIREBALL_RECOVERY_DURATION
		QueuedAttack.TAIL_SWOOP:
			return TAIL_RECOVERY_DURATION
	return 0.0


func _boss_fireball_is_active() -> bool:
	return boss_projectile != null and is_instance_valid(boss_projectile) and boss_projectile.is_active


func _spawn_boss_fireball() -> void:
	if boss_fireball_scene == null or _boss_fireball_is_active():
		return

	if boss_projectile == null or not is_instance_valid(boss_projectile):
		boss_projectile = boss_fireball_scene.instantiate() as Fireball
		if boss_projectile == null:
			return
		var projectile_parent: Node = get_tree().current_scene
		var explicit_container: Node = projectile_parent.get_node_or_null("Fireballs") if projectile_parent != null else null
		if explicit_container != null:
			projectile_parent = explicit_container
		projectile_parent.add_child(boss_projectile)

	var facing_direction: Vector2 = Vector2.RIGHT if sprite != null and sprite.flip_h else Vector2.LEFT
	var spawn_position: Vector2 = breath_shape.global_position if breath_shape != null else (breath_area.global_position if breath_area != null else global_position)
	spawn_position.y += BOSS_FIREBALL_VERTICAL_OFFSET
	var damage_amount: int = int(round(DAMAGE * BOSS_FIREBALL_DAMAGE_MULTIPLIER))
	print("boss used breath shot")
	boss_projectile.activate(spawn_position, facing_direction, &"enemy", damage_amount, self)


func _on_player_death_body_entered(_body: Node2D) -> void:
	return


func take_hit(hit_source: StringName, gold_reward_on_defeat: bool = true) -> bool:
	if death:
		return false

	if hit_cooldown_timer > 0.0:
		return false
	else:
		hit_cooldown_timer = HIT_COOLDOWN

	current_hits = max(current_hits - 1, 0)
	print("boss hit from ", hit_source, " hp ", current_hits, "/", max_hits)
	_update_phase_flags()
	_apply_wave_scaling()
	_flash_hurt()
	_trigger_hitstop()
	health_changed.emit(current_hits, max_hits)

	if current_hits <= 0:
		_die(gold_reward_on_defeat)

	return true


func _update_phase_flags() -> void:
	var phase_changed: bool = false
	if not phase_two_active and current_hits > 0 and current_hits <= int(ceil(float(max_hits) * 0.65)):
		phase_two_active = true
		phase_changed = true
	if not phase_three_active and current_hits > 0 and current_hits <= int(ceil(float(max_hits) * 0.30)):
		phase_three_active = true
		phase_changed = true

	if phase_changed:
		SoundManager.play_sfx(&"roar", -4.0, 1.0, false)


func _handle_player_collision() -> void:
	if player == null or not is_instance_valid(player):
		return
	_damage_player_with_invincibility(player, int(round(DAMAGE)))


func _on_player_collision_body_entered(body: Node2D) -> void:
	if body.name != "player" or death:
		return

	if state == BossState.SUMMON:
		_damage_player_with_invincibility(body, int(round(DAMAGE)))
		return

	if state != BossState.ATTACK or queued_attack != QueuedAttack.TAIL_SWOOP or not tail_hitbox_live:
		return

	_apply_tail_swoop_damage(body)


func _apply_body_contact_damage() -> void:
	if death or player == null or not is_instance_valid(player):
		return
	if state == BossState.SUMMON:
		return
	if not _is_player_body_colliding_with_boss():
		return

	_damage_player_with_invincibility(player, int(round(DAMAGE)))


func _is_player_body_colliding_with_boss() -> bool:
	if body_collision == null or body_collision.shape == null:
		return false
	if player == null or not is_instance_valid(player):
		return false

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body_collision.shape
	query.transform = body_collision.global_transform
	query.collision_mask = PLAYER_COLLISION_LAYER
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [self.get_rid()]

	var overlaps: Array[Dictionary] = space_state.intersect_shape(query, 8)
	for overlap in overlaps:
		if overlap.get("collider") == player:
			return true

	return false


func _apply_tail_swoop_if_overlapping() -> void:
	if tail_area == null or tail_area.monitoring == false:
		return

	for overlapping_body in tail_area.get_overlapping_bodies():
		if overlapping_body.name == "player":
			_apply_tail_swoop_damage(overlapping_body)
			return


func _apply_tail_swoop_damage(target: Node2D = null) -> void:
	var target_player: Node2D = target
	if target_player == null:
		target_player = player
	if target_player == null or not is_instance_valid(target_player):
		return

	var damage_amount: int = int(round(DAMAGE * 1.35))
	_damage_player_with_invincibility(target_player, damage_amount)


func _damage_player_with_invincibility(target_player: Node2D, damage_amount: int) -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	if target_player.has_method("can_take_damage") and target_player.call("can_take_damage") == false:
		return

	Game.playerHP = max(Game.playerHP - damage_amount, 0)
	player_damaged.emit(damage_amount)
	if target_player.has_method("trigger_damage_invincibility"):
		target_player.call("trigger_damage_invincibility")


func _die(gold_reward: bool = false) -> void:
	if death:
		return

	print("boss died gold reward: ", gold_reward)
	death = true
	chase = false
	SoundManager.play_sfx(&"enemy_explode", -1.5)
	var gold_amount: int = GOLD if gold_reward else 0
	if gold_amount > 0:
		Game.gold += gold_amount
	_clear_attack_hitboxes()
	_clear_summon_preview()
	_set_summon_visible(false)
	collision_layer = 0
	collision_mask = 0
	if body_collision != null:
		body_collision.set_deferred("disabled", true)
	for area in [detection_area, breath_area, fireball_warning_area, tail_area]:
		if area == null:
			continue
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		for shape in area.get_children():
			if shape is CollisionShape2D:
				(shape as CollisionShape2D).set_deferred("disabled", true)
	set_physics_process(false)
	_clear_attack_hitboxes()
	_clear_summon_preview()
	if gold_reward:
		call_deferred("_spawn_boss_gem_burst", BOSS_GEM_TOTAL_GOLD)
	defeated.emit(gold_amount, self)
	if sprite != null:
		_current_animation = &"death"
		sprite.play(&"death")
		await sprite.animation_finished
	deactivate_for_wave()


func _process_intimidation_sfx(delta: float) -> void:
	if death or state != BossState.CHASE:
		return
	if not chase or player == null or not is_instance_valid(player):
		return

	intimidation_sfx_timer = maxf(intimidation_sfx_timer - delta, 0.0)
	if intimidation_sfx_timer > 0.0:
		return

	SoundManager.play_sfx(&"growl", -3.5, 1.0, false)
	intimidation_sfx_timer = randf_range(GROWL_INTERVAL_MIN, GROWL_INTERVAL_MAX)


func _spawn_boss_gem_burst(total_gold: int) -> void:
	if boss_gem_scene == null:
		return

	var gem_count: int = randi_range(BOSS_GEM_DROP_MIN, BOSS_GEM_DROP_MAX)
	var gem_values: Array[int] = _split_gold_into_gems(total_gold, gem_count)
	if gem_values.is_empty():
		return

	var drop_parent: Node = get_tree().current_scene
	if drop_parent == null:
		drop_parent = get_parent()
	if drop_parent == null:
		return

	for gem_index in range(gem_values.size()):
		var gem := boss_gem_scene.instantiate() as Area2D
		if gem == null:
			continue

		gem.set("pickup_gold", gem_values[gem_index])
		gem.set("collectable_group", &"boss_gem_collectable")
		drop_parent.add_child(gem)
		gem.visible = true
		gem.set_deferred("monitoring", true)
		gem.set_deferred("monitorable", true)
		for child in gem.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", false)

		var start_position: Vector2 = global_position + Vector2(0.0, -10.0)
		gem.global_position = start_position
		gem.modulate.a = 0.0
		gem.scale = Vector2.ONE * 0.82

		var angle: float = (TAU * float(gem_index) / float(gem_values.size())) + randf_range(-0.22, 0.22)
		var spread: float = randf_range(74.0, 124.0)
		var apex_position: Vector2 = start_position + Vector2(cos(angle) * spread * 0.36, randf_range(-26.0, -12.0))
		var settle_position: Vector2 = Vector2(
			start_position.x + (cos(angle) * spread),
			start_position.y + randf_range(72.0, 90.0)
		)

		var tween: Tween = gem.create_tween()
		tween.tween_interval(float(gem_index) * 0.03)
		tween.tween_property(gem, "global_position", apex_position, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(gem, "global_position", settle_position, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(gem, "modulate:a", 1.0, 0.16).from(0.0)
		tween.parallel().tween_property(gem, "scale", Vector2.ONE, 0.20).from(Vector2.ONE * 0.82).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _split_gold_into_gems(total_gold: int, gem_count: int) -> Array[int]:
	var values: Array[int] = []
	if gem_count <= 0 or total_gold <= 0:
		return values

	var base_value: int = int(floor(float(total_gold) / float(gem_count)))
	var remainder: int = total_gold - (base_value * gem_count)
	for gem_index in range(gem_count):
		values.append(base_value + (1 if gem_index < remainder else 0))

	values.shuffle()
	return values


func get_hits_remaining() -> int:
	return current_hits


func get_max_hits() -> int:
	return max_hits


func get_boss_name() -> String:
	match boss_variant:
		BossVariant.CORRUPTED:
			return "Corrupted Dragon"
		BossVariant.CORRUPTED_ELITE:
			return "Corrupted Elite Dragon"
	return "Dragon"


func _get_base_hits_for_index(index: int) -> int:
	if index >= 3:
		return 40
	if index >= 2:
		return 25
	return 12


func _get_boss_index(wave_number: int) -> int:
	return 1 + int(floor(float(max(wave_number - 10, 0)) / 10.0))


func _get_boss_variant(index: int) -> int:
	if index >= 3:
		return BossVariant.CORRUPTED_ELITE
	if index >= 2:
		return BossVariant.CORRUPTED
	return BossVariant.DRAGON


func _get_variant_scale_multiplier() -> float:
	match boss_variant:
		BossVariant.CORRUPTED:
			return 1.05
		BossVariant.CORRUPTED_ELITE:
			return 1.10
	return 1.0


func _get_variant_color() -> Color:
	if phase_three_active:
		match boss_variant:
			BossVariant.CORRUPTED:
				return Color(0.90, 0.38, 0.56, 1.0)
			BossVariant.CORRUPTED_ELITE:
				return Color(0.74, 0.24, 0.50, 1.0)
		return Color(0.98, 0.46, 0.46, 1.0)

	if phase_two_active:
		match boss_variant:
			BossVariant.CORRUPTED:
				return Color(0.92, 0.46, 0.64, 1.0)
			BossVariant.CORRUPTED_ELITE:
				return Color(0.80, 0.30, 0.58, 1.0)
		return Color(1.0, 0.56, 0.56, 1.0)

	match boss_variant:
		BossVariant.CORRUPTED:
			return Color(0.78, 0.50, 0.70, 1.0)
		BossVariant.CORRUPTED_ELITE:
			return Color(0.66, 0.34, 0.56, 1.0)
	return Color(1.0, 0.84, 0.84, 1.0)


func _roll_fireball_cooldown() -> float:
	var min_time: float = max(1.75, 2.2 - (0.12 * float(max(boss_index - 1, 0))))
	var max_time: float = max(min_time + 0.25, 2.8 - (0.15 * float(max(boss_index - 1, 0))))
	if phase_three_active:
		min_time = max(1.45, min_time - 0.15)
		max_time = max(min_time + 0.20, max_time - 0.15)
	return randf_range(min_time, max_time)


func show_attack_hitbox_preview(attack_type: int) -> void:
	match attack_type:
		QueuedAttack.FIREBALL:
			_set_preview_state(fireball_preview, fireball_warning_area, false, Color(1.0, 0.76, 0.18, 0.95))
		QueuedAttack.TAIL_SWOOP:
			_set_preview_state(tail_preview, tail_area, false, Color(1.0, 0.72, 0.18, 0.98))


func set_attack_hitbox_live(attack_type: int) -> void:
	match attack_type:
		QueuedAttack.FIREBALL:
			_set_preview_state(fireball_preview, fireball_warning_area, false, Color(1.0, 0.34, 0.12, 1.0))
		QueuedAttack.TAIL_SWOOP:
			tail_hitbox_live = true
			_set_preview_state(tail_preview, tail_area, true, Color(1.0, 0.22, 0.22, 1.0))


func _clear_attack_hitboxes() -> void:
	tail_hitbox_live = false
	_set_preview_state(fireball_preview, fireball_warning_area, false, Color(1.0, 1.0, 1.0, 0.0), false)
	_set_preview_state(tail_preview, tail_area, false, Color(1.0, 1.0, 1.0, 0.0), false)
	_set_summon_breath_hitbox_active(false)


func _build_attack_previews() -> void:
	# boss warning shapes
	fireball_preview = _build_preview_for_shape(fireball_warning_root, fireball_warning_shape, 4.0)
	tail_preview = _build_preview_for_shape(tail_area, tail_shape, 4.0)


func _build_preview_for_shape(parent_node: Node2D, shape_node: CollisionShape2D, width: float) -> Line2D:
	if parent_node == null or shape_node == null or shape_node.shape == null:
		return null

	var preview: Line2D = Line2D.new()
	preview.closed = true
	preview.width = width
	preview.default_color = Color(1.0, 1.0, 1.0, 0.0)
	preview.z_index = 25
	preview.visible = false
	preview.points = _build_shape_outline(shape_node.shape)
	preview.position = shape_node.position
	parent_node.add_child(preview)
	return preview


func _build_shape_outline(shape: Shape2D) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	if shape is RectangleShape2D:
		var rectangle: RectangleShape2D = shape as RectangleShape2D
		var half_size: Vector2 = rectangle.size * 0.5
		points.append(Vector2(-half_size.x, -half_size.y))
		points.append(Vector2(half_size.x, -half_size.y))
		points.append(Vector2(half_size.x, half_size.y))
		points.append(Vector2(-half_size.x, half_size.y))
	elif shape is CircleShape2D:
		var circle: CircleShape2D = shape as CircleShape2D
		points = _build_circle_points(circle.radius, 24)
	return points


func _set_preview_state(preview: Line2D, area: Area2D, live: bool, color: Color, should_show: bool = true) -> void:
	if preview != null:
		preview.visible = should_show
		preview.default_color = color
	if area != null:
		area.set_deferred("monitoring", live)
		area.set_deferred("monitorable", live)
		for child in area.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", not live)


func _show_summon_preview() -> void:
	# enemy summoning pos
	_clear_summon_preview()
	var preview: Line2D = Line2D.new()
	preview.closed = true
	preview.width = 5.0
	preview.default_color = Color(0.86, 0.28, 1.0, 0.95)
	preview.points = _build_circle_points(136.0, 28)
	preview.z_index = 30
	add_child(preview)
	preview.position = Vector2.ZERO
	summon_preview = preview

	var tween: Tween = create_tween()
	tween.tween_property(preview, "scale", Vector2.ONE * 1.12, SUMMON_TELEGRAPH_DURATION).from(Vector2.ONE * 0.88).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(preview, "modulate:a", 1.0, SUMMON_TELEGRAPH_DURATION * 0.45).from(0.0)


func _clear_summon_preview() -> void:
	if summon_preview != null and is_instance_valid(summon_preview):
		summon_preview.queue_free()
	summon_preview = null


func _build_circle_points(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var angle: float = TAU * float(point_index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _flash_hurt() -> void:
	if sprite == null:
		return

	var original_modulate: Color = _get_variant_color()
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _trigger_hitstop() -> void:
	if hitstop_active:
		return

	hitstop_active = true
	_play_hitstop()


func _play_hitstop() -> void:
	Engine.time_scale = HITSTOP_TIME_SCALE
	await get_tree().create_timer(HITSTOP_DURATION, true, false, true).timeout
	Engine.time_scale = 1.0
	hitstop_active = false


func _show_summon_feedback() -> void:
	if sprite == null:
		return

	print("boss summon windup")
	_set_summon_visible(true)
	if summon_sprite == null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(breath_animation_name):
		sprite.play(breath_animation_name)
	_spawn_summon_burst_effect()
	var original_modulate: Color = _get_variant_color()
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_interval(SUMMON_FLASH_DURATION)
	tween.tween_property(sprite, "modulate", original_modulate, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_set_summon_visible").bind(false))


func _spawn_summon_burst_effect() -> void:
	var pulse := Line2D.new()
	pulse.closed = true
	pulse.width = 6.0
	pulse.default_color = Color(1.0, 0.55, 0.12, 0.92)
	pulse.points = _build_circle_points(24.0, 28)
	pulse.z_index = 60
	pulse.position = Vector2.ZERO
	pulse.modulate.a = 0.0
	add_child(pulse)

	var tween := create_tween()
	tween.tween_property(pulse, "modulate:a", 1.0, 0.08).from(0.0)
	tween.parallel().tween_property(pulse, "scale", Vector2.ONE * 2.9, 0.28).from(Vector2.ONE * 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(pulse.queue_free)


func _set_summon_visible(visible_state: bool) -> void:
	if summon_node != null:
		summon_node.visible = visible_state
	if summon_sprite != null:
		summon_sprite.visible = visible_state
		if visible_state:
			summon_sprite.play(&"summon")
		else:
			summon_sprite.stop()


func _set_summon_breath_hitbox_active(is_active: bool) -> void:
	if breath_area != null:
		breath_area.set_deferred("monitoring", is_active)
		breath_area.set_deferred("monitorable", is_active)
	if breath_shape != null:
		breath_shape.set_deferred("disabled", not is_active)


func _ensure_boss_frames_loaded() -> void:
	if sprite == null:
		return

	if _scene_frames_are_usable(sprite.sprite_frames):
		return

	if _cached_boss_frames == null:
		_cached_boss_frames = _build_boss_frames()

	if _cached_boss_frames != null and _cached_boss_frames.get_frame_count("idle") > 0:
		sprite.sprite_frames = _cached_boss_frames
		sprite.visible = true


func _scene_frames_are_usable(frames: SpriteFrames) -> bool:
	if frames == null:
		return false

	var attack_animation_name: StringName = BREATH_ATTACK_ANIMATION if frames.has_animation(BREATH_ATTACK_ANIMATION) else LEGACY_BREATH_ATTACK_ANIMATION
	var required: Array[StringName] = [&"idle", attack_animation_name, &"death", &"tail_swoop"]
	for anim_name in required:
		if not frames.has_animation(anim_name):
			return false
		if frames.get_frame_count(anim_name) <= 1:
			return false
		if frames.get_frame_texture(anim_name, 0) == null:
			return false

	return true


func _build_boss_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()

	_add_animation(frames, "idle", [
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/idle/_0000_Layer-1.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/idle/_0001_Layer-2.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/idle/_0002_Layer-3.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/idle/_0003_Layer-4.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/idle/_0004_Layer-5.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/idle/_0005_Layer-6.png"
	], true, 4.0)

	_add_animation(frames, String(BREATH_ATTACK_ANIMATION), [
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/breath/_0000_Layer-1.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/breath/_0001_Layer-2.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/breath/_0002_Layer-3.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/breath/_0003_Layer-4.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/breath/_0004_Layer-5.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/breath/_0005_Layer-6.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/breath/_0006_Layer-7.png"
	], false, 6.0)

	_add_animation(frames, "tail_swoop", [
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/tail/_0000_Layer-1.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/tail/_0001_Layer-2.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/tail/_0002_Layer-3.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/tail/_0003_Layer-4.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/tail/_0004_Layer-5.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/tail/_0005_Layer-6.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/tail/_0006_Layer-7.png",
		"res://assets/Characters/Enemies and NPC/Grotto-escape-2-boss-dragon/sprites/tail/_0007_Layer-8.png"
	], false, 7.0)

	_add_animation(frames, "death", [
		"res://assets/Props Items and VFX/enemy-death 2/Sprites/enemy-death-1.png",
		"res://assets/Props Items and VFX/enemy-death 2/Sprites/enemy-death-2.png",
		"res://assets/Props Items and VFX/enemy-death 2/Sprites/enemy-death-3.png",
		"res://assets/Props Items and VFX/enemy-death 2/Sprites/enemy-death-4.png"
	], false, 5.0)

	return frames


func _add_animation(frames: SpriteFrames, anim_name: String, texture_paths: Array[String], loop: bool, speed: float) -> void:
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)

	for path in texture_paths:
		var texture: Texture2D = _load_texture_fallback(path)
		if texture != null:
			frames.add_frame(anim_name, texture)


func _load_texture_fallback(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null

	var abs_path: String = ProjectSettings.globalize_path(path)
	var image: Image = Image.load_from_file(abs_path)
	if image == null or image.is_empty():
		return null

	return ImageTexture.create_from_image(image)


func _sync_hitboxes_to_facing() -> void:
	if sprite == null:
		return

	_apply_manual_facing_offsets()


func _configure_area_masks() -> void:
	for area in [detection_area, breath_area, fireball_warning_area, tail_area]:
		if area == null:
			continue
		area.collision_layer = 0
		area.collision_mask = PLAYER_COLLISION_LAYER


func _resolve_breath_animation_name() -> void:
	if sprite == null or sprite.sprite_frames == null:
		breath_animation_name = BREATH_ATTACK_ANIMATION
		return
	if sprite.sprite_frames.has_animation(BREATH_ATTACK_ANIMATION):
		breath_animation_name = BREATH_ATTACK_ANIMATION
		return
	breath_animation_name = LEGACY_BREATH_ATTACK_ANIMATION


func _apply_manual_facing_offsets() -> void:
	# db sect
	var facing_right: bool = sprite != null and sprite.flip_h
	if body_collision != null:
		body_collision.position = RIGHT_BODY_POSITION if facing_right else LEFT_BODY_POSITION
	if breath_shape != null:
		breath_shape.position = RIGHT_BREATH_POSITION if facing_right else LEFT_BREATH_POSITION
	if fireball_warning_shape != null:
		fireball_warning_shape.position = Vector2(408.0, 19.0) if facing_right else Vector2(-476.0, 19.0)
		if fireball_preview != null:
			fireball_preview.position = fireball_warning_shape.position
	if tail_shape != null:
		tail_shape.position = RIGHT_TAIL_POSITION if facing_right else LEFT_TAIL_POSITION
		if tail_preview != null:
			tail_preview.position = tail_shape.position
	if detection_shape != null:
		detection_shape.position = RIGHT_DETECTION_POSITION if facing_right else LEFT_DETECTION_POSITION
	if jump_shape != null:
		jump_shape.position = RIGHT_JUMP_POSITION if facing_right else LEFT_JUMP_POSITION


func _is_player_inside_tail_hitbox() -> bool:
	if tail_shape == null or tail_shape.shape == null:
		return false
	if player == null or not is_instance_valid(player):
		return false

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = tail_shape.shape
	query.transform = tail_shape.global_transform
	query.collision_mask = PLAYER_COLLISION_LAYER
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [self.get_rid()]

	for overlap in space_state.intersect_shape(query, 8):
		if overlap.get("collider") == player:
			return true
	return false
