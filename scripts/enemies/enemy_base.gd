extends CharacterBody2D
class_name EnemyBase

# stats (override in child classes)
@export var SPEED: float = 50.0
@export var DAMAGE: float = 3.0
@export var GOLD: int = 5
@export var DETECTION_RANGE: float = 104.0
@export var SCALE_FACTOR: float = 1.0

# base stats (stored on spawn for clean scaling)
var base_speed: float = 0.0
var base_damage: float = 0.0
var base_gold: int = 0
var pending_level: int = 1
var has_pending_scaling: bool = false

# internal state
var player: CharacterBody2D = null
var chase: bool = false
var death: bool = false
var gravity: float = 980.0

signal enemy_died(gold_amount: int)
signal player_damaged(damage_amount: float)


func _ready() -> void:
	_capture_base_stats()
	if has_pending_scaling:
		_apply_current_scaling()
	
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")
	
	if has_node("PlayerDetection"):
		var detection := $PlayerDetection
		if not detection.body_entered.is_connected(Callable(self, "_on_player_detection_body_entered")):
			detection.body_entered.connect(_on_player_detection_body_entered)
		if not detection.body_exited.is_connected(Callable(self, "_on_player_detection_body_exited")):
			detection.body_exited.connect(_on_player_detection_body_exited)
	
	if has_node("PlayerDeath"):
		var death_area := $PlayerDeath
		if not death_area.body_entered.is_connected(Callable(self, "_on_player_death_body_entered")):
			death_area.body_entered.connect(_on_player_death_body_entered)
	
	if has_node("PlayerCollision"):
		var collide_area := $PlayerCollision
		if not collide_area.body_entered.is_connected(Callable(self, "_on_player_collision_body_entered")):
			collide_area.body_entered.connect(_on_player_collision_body_entered)


func _physics_process(delta: float) -> void:
	if not death:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
	
	if chase and player and not death:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.flip_h = direction.x > 0
			$AnimatedSprite2D.play("attack")
		
		velocity.x = direction.x * SPEED
	else:
		velocity.x = 0
		if has_node("AnimatedSprite2D") and not death:
			$AnimatedSprite2D.play("idle")
	
	move_and_slide()


func _apply_scaling(gold_scale_factor: float) -> void:
	SPEED = base_speed * SCALE_FACTOR
	DAMAGE = base_damage * SCALE_FACTOR
	GOLD = int(base_gold * gold_scale_factor)


func _apply_current_scaling() -> void:
	SCALE_FACTOR = pow(1.05, pending_level - 1)
	var gold_scale_factor := pow(1.03, pending_level - 1)
	_apply_scaling(gold_scale_factor)
	has_pending_scaling = false


func _capture_base_stats() -> void:
	if base_speed == 0.0:
		base_speed = SPEED
		base_damage = DAMAGE
		base_gold = GOLD


func _on_player_detection_body_entered(body: Node2D) -> void:
	if body.name == "player":
		player = body
		chase = true


func _on_player_detection_body_exited(body: Node2D) -> void:
	if body.name == "player":
		chase = false


func _on_player_death_body_entered(body: Node2D) -> void:
	if body.name == "player" and not death:
		_die(true)


func _on_player_collision_body_entered(body: Node2D) -> void:
	if body.name == "player" and not death:
		Game.playerHP = max(Game.playerHP - int(DAMAGE), 0)
		player_damaged.emit(int(DAMAGE))
		
		_die(false)


func _die(gold_reward: bool = false) -> void:
	if death:
		return
	
	death = true
	chase = false
	
	if gold_reward:
		Game.gold += GOLD
		enemy_died.emit(GOLD)
	
	Utils.saveGame()
	
	set_physics_process(false)
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
		elif child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
			for shape in child.get_children():
				if shape is CollisionShape2D:
					shape.set_deferred("disabled", true)
	
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("death")
		await $AnimatedSprite2D.animation_finished
	
	queue_free()


func set_difficulty_scaling(level: int) -> void:
	_capture_base_stats()
	pending_level = level
	has_pending_scaling = true

	if is_node_ready():
		_apply_current_scaling()


func get_stats() -> Dictionary:
	return {
		"speed": SPEED,
		"damage": DAMAGE,
		"gold": GOLD,
		"scale_factor": SCALE_FACTOR,
		"detection_range": DETECTION_RANGE
	}
