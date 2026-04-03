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
	sprite.play("idle")
	if Game.has_signal("level_changed"):
		Game.connect("level_changed", Callable(self, "_on_level_changed"))

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
