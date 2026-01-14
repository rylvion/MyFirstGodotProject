extends CharacterBody2D

const SPEED: int = 50
const DAMAGE: int = 3
const GOLD: int = 5

var player: CharacterBody2D = null
var chase: bool = false
var death: bool = false 

func _ready() -> void:
	$AnimatedSprite2D.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if chase and player:
		var direction: Vector2 = (player.global_position - global_position).normalized()

		$AnimatedSprite2D.flip_h = direction.x > 0
		velocity.x = direction.x * SPEED
		if $AnimatedSprite2D.animation != "death":
			$AnimatedSprite2D.play("attack")
	else:
		velocity.x = 0
		if $AnimatedSprite2D.animation != "death" or not death:
			$AnimatedSprite2D.play("idle")

	move_and_slide()


func _on_player_detection_body_entered(body: Node2D) -> void:
	if body.name == "player":
		player = body
		chase = true


func _on_player_detection_body_exited(body: Node2D) -> void:
	if body.name == "player":
		player = null
		chase = false

func _on_player_death_body_entered(body: Node2D) -> void:
	death_logic(body, "death by player", 0.0, GOLD)


func _on_player_collision_body_entered(body: Node2D) -> void:
	death_logic(body, "death by collision", DAMAGE, 0)
	
func death_logic(body: Node2D, message: String = "Dead", damage: int = 0, gold: int = 0) -> void:
	if body.name == "player" and not death:
		Game.gold += gold
		Game.playerHP = max(Game.playerHP - damage, 0)
		Utils.saveGame()
		chase = false
		death = true
		print("[slime] %s " % message)
		
		set_physics_process(false)
		velocity = Vector2.ZERO
		collision_layer = 0
		collision_mask = 0
		
		for child in get_children():
			if child is CollisionShape2D:
				child.call_deferred("set", "disabled", true)
		
		$AnimatedSprite2D.play("death")
		await $AnimatedSprite2D.animation_finished
		self.queue_free()
	
