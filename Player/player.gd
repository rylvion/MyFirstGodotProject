extends CharacterBody2D

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0
const GRAVITY: float = 900.0
const CLIMB_SPEED: float = 150.0
const BASE_ATTACK_COOLDOWN: float = 3.0
const MIN_ATTACK_COOLDOWN: float = 1.0
const MIN_ATTACK_COOLDOWN_LATE: float = 0.05

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var death: bool = false
var on_ladder: bool = false
var attack_timer: float = 0.0

var fireball_scene: PackedScene = preload("res://scenes/projectiles/fireball.tscn")

func _ready() -> void:
	_ensure_sprite_frames_loaded()
	sprite.play("idle")
	if Game.has_signal("level_changed"):
		Game.connect("level_changed", Callable(self, "_on_level_changed"))

func _ensure_sprite_frames_loaded() -> void:
	if sprite == null:
		return

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

	if fallback_frames.get_frame_count("idle") > 0:
		sprite.sprite_frames = fallback_frames
		sprite.visible = true

func _add_fallback_animation(frames: SpriteFrames, name: String, texture_paths: Array[String], loop: bool, speed: float) -> void:
	if not frames.has_animation(name):
		frames.add_animation(name)
	frames.set_animation_loop(name, loop)
	frames.set_animation_speed(name, speed)
	for path in texture_paths:
		var texture: Texture2D = load(path)
		if texture != null:
			frames.add_frame(name, texture)

func _on_level_changed(_new_level: int) -> void:
	attack_timer = 0.0

func _get_attack_cooldown() -> float:
	# ;inear decrease: 0.1 per level until level 20 (reaches 1.0 sec minimum)
	if Game.level <= 20:
		return max(MIN_ATTACK_COOLDOWN, BASE_ATTACK_COOLDOWN - (Game.level - 1) * 0.1)
	else:
		# exponential slowdown after level 20: 5% reduction per level (much slower, but caps at 0.05 sec minimum)
		return max(MIN_ATTACK_COOLDOWN_LATE, 1.0 * pow(0.95, Game.level - 20))

func _try_level_up() -> void:
	var cost = Game.get_hp_upgrade_cost(Game.level)
	if Game.gold >= cost:
		Game.gold -= cost
		Game.level += 1
		Utils.saveGame()

func _physics_process(delta: float) -> void:
	if death:
		return
	
	if attack_timer > 0:
		attack_timer -= delta
	
	if Input.is_action_just_pressed("attack") and attack_timer <= 0:
		shoot_fireball()
		attack_timer = _get_attack_cooldown()

	if on_ladder:
		velocity.y = 0

		var climb_direction := Input.get_axis("move_up", "move_down")
		velocity.y = climb_direction * CLIMB_SPEED

		var horizontal := Input.get_axis("move_left", "move_right")
		velocity.x = horizontal * (SPEED * 0.5) 

		if climb_direction != 0:
			sprite.play("climb")
		else:
			sprite.play("climb_idle")

		if horizontal < 0:
			sprite.flip_h = true
		elif horizontal > 0:
			sprite.flip_h = false

	else:
		if not is_on_floor():
			velocity.y += GRAVITY * delta

		if Input.is_action_just_pressed("move_up") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var direction := Input.get_axis("move_left", "move_right")
		velocity.x = direction * SPEED

		if direction == 0:
			velocity.x = lerp(velocity.x, 0.0, 0.1)

		if direction < 0:
			sprite.flip_h = true
		elif direction > 0:
			sprite.flip_h = false

		if velocity.y < 0:
			sprite.play("jump")
		elif velocity.y > 0 and not is_on_floor():
			sprite.play("fall")
		elif direction != 0 and is_on_floor():
			sprite.play("run")
		else:
			sprite.play("idle")

	if Input.is_action_just_pressed("level_up"):
		_try_level_up()
	
	if Game.playerHP <= 0:
		handle_death()
		return
	elif Input.is_action_just_pressed("quit"):
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")

	move_and_slide()

func handle_death() -> void:
	if death:
		return
	
	death = true
	print("Exiting....")
	sprite.play("death")
	await sprite.animation_finished
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_ladders_body_entered(body: Node2D) -> void:
	if body == self:
		on_ladder = true
		velocity = Vector2.ZERO

func _on_ladders_body_exited(body: Node2D) -> void:
	if body == self:
		on_ladder = false

func shoot_fireball() -> void:
	var fireball = fireball_scene.instantiate()
	var facing_left := sprite.flip_h
	var x_offset := -20.0 if facing_left else 20.0
	var spawn_pos := global_position + Vector2(x_offset, -8.0)
	fireball.global_position = spawn_pos
	fireball.direction = Vector2.LEFT if facing_left else Vector2.RIGHT
	get_tree().current_scene.add_child(fireball)
