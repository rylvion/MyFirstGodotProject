extends CharacterBody2D

const WORLD_COLLISION_LAYER: int = 1
const PLAYER_COLLISION_LAYER: int = 2
const ENEMY_COLLISION_LAYER: int = 4
const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0
const GRAVITY: float = 900.0
const FAST_FALL_GRAVITY_MULTIPLIER: float = 2.35
const CLIMB_SPEED: float = 150.0
const BASE_ATTACK_COOLDOWN: float = 3.0
const MIN_ATTACK_COOLDOWN: float = 0.25
const STOMP_BOUNCE_VELOCITY: float = -320.0
const STUN_MOVE_MULTIPLIER: float = 0.2
const FIREBALL_POOL_SIZE: int = 8
const MAX_ACTIVE_FIREBALLS: int = 4
const BURN_MAX_STACKS: int = 4
const BURN_TICK_INTERVAL: float = 0.7
const BURN_DURATION: float = 3.0
const BURN_DAMAGE_PER_STACK: int = 1
const SABER_ORBIT_DISTANCE: float = 58.0
const SABER_POSITION_LERP: float = 0.18
const SABER_ROTATION_LERP: float = 0.25
const SABER_ROTATION_OFFSET: float = PI / 4.0
const SABER_ATTACK_COOLDOWN: float = 0.35
const SABER_PULLBACK_DISTANCE: float = 9.0
const SABER_PULLBACK_DURATION: float = 0.06
const SABER_REAPPEAR_DELAY: float = 0.05
const SABER_SLASH_FORWARD_OFFSET: float = 14.0
const CROUCH_COLLISION_SCALE: Vector2 = Vector2(1.0, 0.58)
const CROUCH_COLLISION_OFFSET: Vector2 = Vector2(0.0, 7.0)
const CROUCH_SPRITE_OFFSET: Vector2 = Vector2(0.0, 5.0)
const DAMAGE_IFRAME_DURATION: float = 0.75
const DAMAGE_FLICKER_INTERVAL: float = 0.08

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var saber: Node2D = $Saber
@onready var saber_sprite: Sprite2D = $Saber/SaberSprite
var death: bool = false
var crouching: bool = false
var attack_timer: float = 0.0
var slash_attack_timer: float = 0.0
var stun_timer: float = 0.0
var burn_stacks: int = 0
var burn_tick_timer: float = 0.0
var burn_duration_timer: float = 0.0
var base_collision_position: Vector2 = Vector2.ZERO
var base_collision_scale: Vector2 = Vector2.ONE
var base_sprite_position: Vector2 = Vector2.ZERO
var damage_iframe_timer: float = 0.0
var damage_flicker_timer: float = 0.0
static var _cached_fallback_frames: SpriteFrames = null

var fireball_scene: PackedScene = preload("res://scenes/projectiles/fireball.tscn")
var slash_scene: PackedScene = preload("res://scenes/projectiles/slash.tscn")
var fireball_pool: Array[Fireball] = []
var fireball_container: Node2D
var slash_container: Node2D
var mouse_left_was_pressed: bool = false
var slash_swing_in_progress: bool = false
var active_slash: Area2D = null

signal burn_applied(stacks: int)
signal burn_ticked(damage_amount: int, stacks: int)
signal burn_ended

func _ready() -> void:
	collision_layer = PLAYER_COLLISION_LAYER
	collision_mask = WORLD_COLLISION_LAYER | ENEMY_COLLISION_LAYER
	_ensure_sprite_frames_loaded()
	if body_collision != null:
		base_collision_position = body_collision.position
		base_collision_scale = body_collision.scale
	if sprite != null:
		base_sprite_position = sprite.position
	sprite.play("idle")
	if Game.has_signal("level_changed"):
		Game.connect("level_changed", Callable(self, "_on_level_changed"))
	call_deferred("_setup_fireball_pool")
	call_deferred("_setup_slash_container")

func _ensure_sprite_frames_loaded() -> void:
	if sprite == null:
		return

	if _scene_frames_are_usable(sprite.sprite_frames):
		return

	if _cached_fallback_frames == null:
		_cached_fallback_frames = _build_fallback_frames()

	if _cached_fallback_frames != null and _cached_fallback_frames.get_frame_count("idle") > 0:
		_cached_fallback_frames.set_animation_loop("idle", true)
		sprite.sprite_frames = _cached_fallback_frames
		sprite.visible = true

func _scene_frames_are_usable(frames: SpriteFrames) -> bool:
	if frames == null:
		return false

	var required := ["idle", "run", "jump", "fall", "climb", "death", "crouch"]
	for anim_name in required:
		if not frames.has_animation(anim_name):
			return false
		if frames.get_frame_count(anim_name) <= 0:
			return false
		if frames.get_frame_texture(anim_name, 0) == null:
			return false

	return true

func _build_fallback_frames() -> SpriteFrames:
	var fallback_frames := SpriteFrames.new()

	_add_fallback_animation(fallback_frames, "idle", [
		"res://assets/Characters/Players/Foxy/Sprites/idle/player-idle-1.png",
		"res://assets/Characters/Players/Foxy/Sprites/idle/player-idle-2.png",
		"res://assets/Characters/Players/Foxy/Sprites/idle/player-idle-3.png",
		"res://assets/Characters/Players/Foxy/Sprites/idle/player-idle-4.png"
	], true, 5.0)
	_add_fallback_animation(fallback_frames, "run", [
		"res://assets/Characters/Players/Foxy/Sprites/run/player-run-1.png",
		"res://assets/Characters/Players/Foxy/Sprites/run/player-run-2.png",
		"res://assets/Characters/Players/Foxy/Sprites/run/player-run-3.png",
		"res://assets/Characters/Players/Foxy/Sprites/run/player-run-4.png",
		"res://assets/Characters/Players/Foxy/Sprites/run/player-run-5.png",
		"res://assets/Characters/Players/Foxy/Sprites/run/player-run-6.png"
	], true, 7.0)
	_add_fallback_animation(fallback_frames, "jump", ["res://assets/Characters/Players/Foxy/Sprites/jump/player-jump-1.png"], true, 5.0)
	_add_fallback_animation(fallback_frames, "fall", ["res://assets/Characters/Players/Foxy/Sprites/jump/player-jump-2.png"], true, 5.0)
	_add_fallback_animation(fallback_frames, "climb", [
		"res://assets/Characters/Players/Foxy/Sprites/climb/player-climb-1.png",
		"res://assets/Characters/Players/Foxy/Sprites/climb/player-climb-2.png",
		"res://assets/Characters/Players/Foxy/Sprites/climb/player-climb-3.png"
	], true, 5.0)
	_add_fallback_animation(fallback_frames, "climb_idle", ["res://assets/Characters/Players/Foxy/Sprites/climb/player-climb-1.png"], true, 5.0)
	_add_fallback_animation(fallback_frames, "crouch", [
		"res://assets/Characters/Players/Foxy/Sprites/crouch/player-crouch-1.png",
		"res://assets/Characters/Players/Foxy/Sprites/crouch/player-crouch-2.png"
	], true, 5.0)
	_add_fallback_animation(fallback_frames, "hurt", [
		"res://assets/Characters/Players/Foxy/Sprites/hurt/player-hurt-1.png",
		"res://assets/Characters/Players/Foxy/Sprites/hurt/player-hurt-2.png"
	], false, 5.0)
	_add_fallback_animation(fallback_frames, "hurt2", ["res://assets/Characters/Players/Foxy/Sprites/Hurt2/hurt-2.png"], true, 5.0)
	_add_fallback_animation(fallback_frames, "lookup", ["res://assets/Characters/Players/Foxy/Sprites/LookUp/lookUp.png"], true, 5.0)
	_add_fallback_animation(fallback_frames, "roll", [
		"res://assets/Characters/Players/Foxy/Sprites/Roll/Roll1.png",
		"res://assets/Characters/Players/Foxy/Sprites/Roll/Roll2.png",
		"res://assets/Characters/Players/Foxy/Sprites/Roll/Roll3.png",
		"res://assets/Characters/Players/Foxy/Sprites/Roll/Roll4.png"
	], true, 5.0)
	_add_fallback_animation(fallback_frames, "wallgrab", [
		"res://assets/Characters/Players/Foxy/Sprites/WallGrab/wall-grab1.png",
		"res://assets/Characters/Players/Foxy/Sprites/WallGrab/wall-grab2.png"
	], true, 5.0)
	_add_fallback_animation(fallback_frames, "dizzy", [
		"res://assets/Characters/Players/Foxy/Sprites/Dizzy/Dizzy1.png",
		"res://assets/Characters/Players/Foxy/Sprites/Dizzy/Dizzy2.png",
		"res://assets/Characters/Players/Foxy/Sprites/Dizzy/Dizzy3.png",
		"res://assets/Characters/Players/Foxy/Sprites/Dizzy/Dizzy4.png",
		"res://assets/Characters/Players/Foxy/Sprites/Dizzy/Dizzy5.png",
		"res://assets/Characters/Players/Foxy/Sprites/Dizzy/Dizzy6.png"
	], true, 5.0)
	_add_fallback_animation(fallback_frames, "death", [
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-1.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-2.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-3.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-4.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-5.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-6.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-7.png"
	], false, 5.0)
	_add_fallback_animation(fallback_frames, "victory", ["res://assets/Characters/Players/Foxy/Sprites/Victory/Victory.png"], true, 5.0)
	return fallback_frames

func _add_fallback_animation(frames: SpriteFrames, anim_name: String, texture_paths: Array[String], loop: bool, speed: float) -> void:
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

	var abs_path := ProjectSettings.globalize_path(path)
	var image := Image.load_from_file(abs_path)
	if image == null or image.is_empty():
		return null

	return ImageTexture.create_from_image(image)

func _on_level_changed(_new_level: int) -> void:
	attack_timer = 0.0

func get_attack_cooldown() -> float:
	var level_index: int = max(Game.level - 1, 0)
	return max(MIN_ATTACK_COOLDOWN, BASE_ATTACK_COOLDOWN / (1.0 + (0.12 * level_index)))

func _get_attack_cooldown() -> float:
	return get_attack_cooldown()

func _try_level_up() -> void:
	if Game.try_level_up():
		Utils.saveGame()

func _setup_fireball_pool() -> void:
	if not fireball_pool.is_empty():
		return

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	fireball_container = current_scene.get_node_or_null("Fireballs") as Node2D
	if fireball_container == null:
		fireball_container = Node2D.new()
		fireball_container.name = "Fireballs"
		current_scene.add_child(fireball_container)

	for _index in range(FIREBALL_POOL_SIZE):
		var fireball := fireball_scene.instantiate() as Fireball
		fireball_container.add_child(fireball)
		fireball_pool.append(fireball)


func _setup_slash_container() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	slash_container = current_scene.get_node_or_null("Slashes") as Node2D
	if slash_container == null:
		slash_container = Node2D.new()
		slash_container.name = "Slashes"
		current_scene.add_child(slash_container)

func _get_active_fireball_count() -> int:
	var active_count := 0
	for fireball in fireball_pool:
		if fireball.is_active:
			active_count += 1
	return active_count

func _get_available_fireball() -> Fireball:
	for fireball in fireball_pool:
		if not fireball.is_active:
			return fireball
	return null


func _get_saber_target() -> Dictionary:
	var mouse_position: Vector2 = get_global_mouse_position()
	var direction_to_mouse: Vector2 = mouse_position - global_position
	if direction_to_mouse.length_squared() < 0.001:
		direction_to_mouse = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT

	var aim_direction: Vector2 = direction_to_mouse.normalized()
	var target_position: Vector2 = global_position + (aim_direction * SABER_ORBIT_DISTANCE)
	var target_rotation: float = direction_to_mouse.angle() + SABER_ROTATION_OFFSET
	return {"position": target_position, "rotation": target_rotation}


func _update_saber(delta: float) -> void:
	if saber == null:
		return

	var target_state: Dictionary = _get_saber_target()
	var target_position: Vector2 = target_state["position"]
	var target_rotation: float = target_state["rotation"]

	saber.global_position = saber.global_position.lerp(target_position, clampf(SABER_POSITION_LERP * (delta * 60.0), 0.0, 1.0))
	saber.global_rotation = lerp_angle(saber.global_rotation, target_rotation, clampf(SABER_ROTATION_LERP * (delta * 60.0), 0.0, 1.0))


func _can_spawn_slash() -> bool:
	return not slash_swing_in_progress and (active_slash == null or not is_instance_valid(active_slash))


func _on_active_slash_exited() -> void:
	active_slash = null


func spawn_slash() -> Area2D:
	if active_slash != null and is_instance_valid(active_slash):
		return null

	if slash_scene == null:
		return null

	if slash_container == null:
		_setup_slash_container()
	if slash_container == null or saber == null:
		return null

	var slash := slash_scene.instantiate()
	if slash == null:
		return null

	slash_container.add_child(slash)
	active_slash = slash as Area2D
	if active_slash != null and active_slash.tree_exited.is_connected(_on_active_slash_exited) == false:
		active_slash.tree_exited.connect(_on_active_slash_exited, CONNECT_ONE_SHOT)
	if slash.has_method("activate"):
		var slash_spawn_position: Vector2 = saber.global_position + Vector2.RIGHT.rotated(saber.global_rotation - SABER_ROTATION_OFFSET) * SABER_SLASH_FORWARD_OFFSET
		slash.call("activate", slash_spawn_position, saber.global_rotation)
	else:
		slash.global_position = saber.global_position
		slash.global_rotation = saber.global_rotation

	return active_slash


func _start_slash_swing() -> void:
	if saber == null or not _can_spawn_slash():
		return

	slash_swing_in_progress = true
	var target_state: Dictionary = _get_saber_target()
	var target_position: Vector2 = target_state["position"]
	var aim_direction: Vector2 = (target_position - global_position).normalized()
	if aim_direction.length_squared() < 0.001:
		aim_direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT

	var pullback_position: Vector2 = target_position - (aim_direction * SABER_PULLBACK_DISTANCE)
	var pullback_tween: Tween = create_tween()
	pullback_tween.tween_property(saber, "global_position", pullback_position, SABER_PULLBACK_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await pullback_tween.finished

	if saber_sprite != null:
		saber_sprite.visible = false

	var slash_instance: Area2D = spawn_slash()
	if slash_instance != null:
		await get_tree().create_timer(SABER_REAPPEAR_DELAY).timeout
		if slash_instance != null and is_instance_valid(slash_instance):
			await slash_instance.tree_exited

	if saber_sprite != null:
		saber_sprite.visible = true
	slash_swing_in_progress = false

func _physics_process(delta: float) -> void:
	if death:
		return

	var input_blocked: bool = Game.input_blocked
	
	if attack_timer > 0:
		attack_timer -= delta
	if slash_attack_timer > 0:
		slash_attack_timer -= delta
	if stun_timer > 0.0:
		stun_timer = maxf(stun_timer - delta, 0.0)
	if damage_iframe_timer > 0.0:
		damage_iframe_timer = maxf(damage_iframe_timer - delta, 0.0)
		_update_damage_flicker(delta)
	elif sprite != null and sprite.visible == false:
		sprite.visible = true
	_process_burn(delta)
	_update_saber(delta)
	
	if not input_blocked and stun_timer <= 0.0 and Input.is_action_just_pressed("attack") and attack_timer <= 0:
		shoot_fireball()
		attack_timer = get_attack_cooldown()

	var mouse_left_pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not input_blocked and stun_timer <= 0.0 and mouse_left_pressed and not mouse_left_was_pressed and slash_attack_timer <= 0.0 and _can_spawn_slash():
		_start_slash_swing()
		Game.mark_tutorial_step(&"slash")
		slash_attack_timer = SABER_ATTACK_COOLDOWN
	mouse_left_was_pressed = mouse_left_pressed

	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if not input_blocked and stun_timer <= 0.0 and Input.is_action_pressed("move_down"):
			velocity.y += GRAVITY * FAST_FALL_GRAVITY_MULTIPLIER * delta

	if not input_blocked and stun_timer <= 0.0 and Input.is_action_just_pressed("move_up") and is_on_floor() and not crouching:
		velocity.y = JUMP_VELOCITY
		Game.mark_tutorial_step(&"jump")

	var direction := 0.0 if input_blocked else Input.get_axis("move_left", "move_right")
	if stun_timer > 0.0:
		direction *= STUN_MOVE_MULTIPLIER

	crouching = not input_blocked and stun_timer <= 0.0 and is_on_floor() and Input.is_action_pressed("move_down")
	_apply_crouch_state(crouching)

	if crouching:
		velocity.x = 0.0
	elif input_blocked:
		velocity.x = 0.0
	else:
		velocity.x = direction * SPEED

	if direction == 0:
		velocity.x = lerp(velocity.x, 0.0, 0.1)

	if direction < 0:
		sprite.flip_h = true
	elif direction > 0:
		sprite.flip_h = false
	if absf(direction) > 0.0:
		Game.mark_tutorial_step(&"move")

	if input_blocked:
		if not is_on_floor():
			sprite.play("fall")
		else:
			sprite.play("idle")
	elif stun_timer > 0.0:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("dizzy"):
			sprite.play("dizzy")
		else:
			sprite.play("idle")
	elif crouching:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("crouch"):
			sprite.play("crouch")
		else:
			sprite.play("idle")
	elif velocity.y < 0:
		sprite.play("jump")
	elif velocity.y > 0 and not is_on_floor():
		sprite.play("fall")
	elif direction != 0 and is_on_floor():
		sprite.play("run")
	else:
		sprite.play("idle")

	if not input_blocked and stun_timer <= 0.0 and Input.is_action_just_pressed("level_up"):
		_try_level_up()
	
	if Game.playerHP <= 0:
		handle_death()
		return

	move_and_slide()

func handle_death() -> void:
	if death:
		return
	
	death = true
	if sprite != null:
		sprite.visible = true
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_clear_burn(false)
	print("Exiting....")
	sprite.play("death")
	await sprite.animation_finished
	Utils.saveGame()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_ladders_body_entered(_body: Node2D) -> void:
	pass

func _on_ladders_body_exited(_body: Node2D) -> void:
	pass

func stomp_bounce(strength: float = STOMP_BOUNCE_VELOCITY) -> void:
	if death:
		return

	velocity.y = strength
	crouching = false
	_apply_crouch_state(false)


func apply_stun(duration: float) -> void:
	if death:
		return

	stun_timer = maxf(stun_timer, maxf(duration, 0.0))
	crouching = false
	_apply_crouch_state(false)


func is_stunned() -> bool:
	return stun_timer > 0.0


func apply_burn(stacks_to_add: int = 1, duration: float = BURN_DURATION) -> void:
	if death:
		return

	var added_stacks: int = max(stacks_to_add, 1)
	burn_stacks = clampi(burn_stacks + added_stacks, 1, BURN_MAX_STACKS)
	burn_duration_timer = maxf(burn_duration_timer, maxf(duration, 0.0))
	if burn_tick_timer <= 0.0:
		burn_tick_timer = BURN_TICK_INTERVAL
	burn_applied.emit(burn_stacks)


func _process_burn(delta: float) -> void:
	if burn_stacks <= 0 or death:
		return

	burn_duration_timer = maxf(burn_duration_timer - delta, 0.0)
	burn_tick_timer -= delta

	if burn_tick_timer <= 0.0 and Game.playerHP > 0:
		var tick_damage: int = max(1, burn_stacks * BURN_DAMAGE_PER_STACK)
		Game.playerHP = max(Game.playerHP - tick_damage, 0)
		burn_ticked.emit(tick_damage, burn_stacks)
		burn_tick_timer += BURN_TICK_INTERVAL

	if burn_duration_timer <= 0.0:
		_clear_burn(true)


func _clear_burn(should_emit_burn_ended: bool) -> void:
	if burn_stacks <= 0:
		return

	burn_stacks = 0
	burn_tick_timer = 0.0
	burn_duration_timer = 0.0
	if should_emit_burn_ended:
		burn_ended.emit()


func _apply_crouch_state(should_crouch: bool) -> void:
	if body_collision != null:
		body_collision.scale = base_collision_scale * (CROUCH_COLLISION_SCALE if should_crouch else Vector2.ONE)
		body_collision.position = base_collision_position + (CROUCH_COLLISION_OFFSET if should_crouch else Vector2.ZERO)
	if sprite != null:
		sprite.position = base_sprite_position + (CROUCH_SPRITE_OFFSET if should_crouch else Vector2.ZERO)


func can_take_damage() -> bool:
	return not death and damage_iframe_timer <= 0.0


func trigger_damage_invincibility(duration: float = DAMAGE_IFRAME_DURATION) -> void:
	if death:
		return

	damage_iframe_timer = maxf(damage_iframe_timer, maxf(duration, 0.0))
	damage_flicker_timer = 0.0
	if sprite != null:
		sprite.visible = true


func _update_damage_flicker(delta: float) -> void:
	if sprite == null:
		return

	damage_flicker_timer += delta
	if damage_flicker_timer >= DAMAGE_FLICKER_INTERVAL:
		damage_flicker_timer = 0.0
		sprite.visible = not sprite.visible

func shoot_fireball() -> void:
	if _get_active_fireball_count() >= MAX_ACTIVE_FIREBALLS:
		return

	var fireball: Fireball = _get_available_fireball()
	if fireball == null:
		return

	var facing_left := sprite.flip_h
	var x_offset := -20.0 if facing_left else 20.0
	var spawn_pos := global_position + Vector2(x_offset, -8.0)
	fireball.activate(spawn_pos, Vector2.LEFT if facing_left else Vector2.RIGHT)
	Game.mark_tutorial_step(&"attack")
