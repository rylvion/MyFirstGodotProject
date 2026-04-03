extends Area2D

const SPEED: float = 400.0
const LIFETIME: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var lifetime_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.play("fly")
	sprite.flip_h = direction.x < 0

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	lifetime_timer += delta
	
	if lifetime_timer >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is EnemyBase:
		body._die(true)
		_explode()
	elif body is TileMapLayer or body is StaticBody2D:
		_explode()

func _explode() -> void:
	set_physics_process(false)
	sprite.play("hit")
	await sprite.animation_finished
	queue_free()
