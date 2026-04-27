extends Area2D
class_name Fireball

const SPEED: float = 400.0
const LIFETIME: float = 1.75
const ACTIVE_COLLISION_LAYER: int = 4
const PLAYER_COLLISION_LAYER: int = 2
const ENEMY_COLLISION_LAYER: int = 4
const BOSS_COLLISION_LAYER: int = 8
const WORLD_COLLISION_LAYER: int = 1

var direction: Vector2 = Vector2.RIGHT
var lifetime_timer: float = 0.0
var is_active: bool = false
var is_exploding: bool = false
var source_team: StringName = &"player"
var damage_amount: int = 1
var owner_ref: Node = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	deactivate()

func _physics_process(delta: float) -> void:
	if not is_active or is_exploding:
		return

	position += direction * SPEED * delta
	lifetime_timer += delta

	if lifetime_timer >= LIFETIME:
		_explode()


func activate(spawn_position: Vector2, new_direction: Vector2, team: StringName = &"player", next_damage_amount: int = 1, next_owner: Node = null) -> void:
	global_position = spawn_position
	direction = new_direction.normalized()
	lifetime_timer = 0.0
	is_active = true
	is_exploding = false
	source_team = team
	damage_amount = next_damage_amount
	owner_ref = next_owner
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	collision_layer = ACTIVE_COLLISION_LAYER
	collision_mask = PLAYER_COLLISION_LAYER | WORLD_COLLISION_LAYER if source_team == &"enemy" else (ENEMY_COLLISION_LAYER | BOSS_COLLISION_LAYER | WORLD_COLLISION_LAYER)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)
	set_physics_process(true)
	if sprite != null:
		sprite.play("fly")
		sprite.flip_h = direction.x < 0

	SoundManager.play_sfx("fireball", 0.0, randf_range(0.95, 1.05))

func deactivate() -> void:
	is_active = false
	is_exploding = false
	lifetime_timer = 0.0
	source_team = &"player"
	damage_amount = 1
	owner_ref = null
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	if sprite != null:
		sprite.stop()
		sprite.frame = 0

func _on_body_entered(body: Node2D) -> void:
	if not is_active or is_exploding:
		return

	if owner_ref != null and body == owner_ref:
		return

	if source_team == &"player" and body is EnemyBase:
		body.take_hit(&"fireball", true)
		_explode()
	elif source_team == &"enemy" and body.name == "player":
		Game.playerHP = max(Game.playerHP - damage_amount, 0)
		_explode()
	elif body is TileMapLayer or body is StaticBody2D:
		_explode()

func _explode() -> void:
	if not is_active or is_exploding:
		return

	is_exploding = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	if sprite != null:
		sprite.play("hit")
		await sprite.animation_finished
	deactivate()
