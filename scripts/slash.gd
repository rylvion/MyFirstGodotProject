extends Area2D

const ENEMY_COLLISION_LAYER: int = 4
const BOSS_COLLISION_LAYER: int = 8

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
const MAX_PIERCE_TARGETS: int = 3

var hit_targets: Array[Node] = []


func _ready() -> void:
	if body_entered.is_connected(_on_body_entered) == false:
		body_entered.connect(_on_body_entered)
	if area_entered.is_connected(_on_area_entered) == false:
		area_entered.connect(_on_area_entered)


func activate(spawn_position: Vector2, spawn_rotation: float) -> void:
	global_position = spawn_position
	global_rotation = spawn_rotation
	hit_targets.clear()
	collision_layer = 0
	collision_mask = ENEMY_COLLISION_LAYER | BOSS_COLLISION_LAYER
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", false)
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("slash-horizontal"):
		sprite.sprite_frames.set_animation_loop("slash-horizontal", false)
	sprite.play("slash-horizontal")
	if sprite.animation_finished.is_connected(_on_animation_finished) == false:
		sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func _on_body_entered(body: Node2D) -> void:
	_try_damage_target(body)


func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.name != "PlayerCollision":
		return
	_try_damage_target(area.get_parent() as Node)


func _try_damage_target(target: Node) -> void:
	if target == null:
		return
	if target.name == "player":
		return
	if target in hit_targets:
		return
	if target.has_method("take_hit") == false:
		return

	var did_hit: bool = bool(target.call("take_hit", &"slash", true))
	if did_hit == false:
		return

	SoundManager.play_sfx(&"slash_hit", -3.5)
	hit_targets.append(target)

	if hit_targets.size() >= MAX_PIERCE_TARGETS:
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		for child in get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", true)


func _on_animation_finished() -> void:
	queue_free()
