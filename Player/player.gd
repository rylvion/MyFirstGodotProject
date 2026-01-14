extends CharacterBody2D

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0
const GRAVITY: float = 900.0
const CLIMB_SPEED: float = 150.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var death: bool = false
var on_ladder: bool = false

func _ready() -> void:
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if death:
		return

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
