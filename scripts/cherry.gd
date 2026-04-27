extends Area2D

const PLAYER_COLLISION_LAYER: int = 2

@export var pickup_gold: int = 3
@export var collectable_group: StringName = &"cherry_collectable"
@export var pickup_rise_distance: float = 25.0
@export var pickup_duration: float = 0.8
@export var idle_float_enabled: bool = false
@export var idle_float_distance: float = 5.0
@export var idle_float_duration: float = 0.9
@export var idle_float_start_delay: float = 0.45

var idle_float_tween: Tween = null
var is_collected: bool = false


func _ready() -> void:
	add_to_group(collectable_group)
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = PLAYER_COLLISION_LAYER
	$AnimatedSprite2D.play("idle")
	if idle_float_enabled:
		call_deferred("start_idle_float")


func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.name == "player":
		is_collected = true
		if idle_float_tween != null:
			idle_float_tween.kill()
		SoundManager.play_sfx(&"pickup_collectable", -4.0)
		Game.gold += pickup_gold
		Game.mark_tutorial_step(&"pickup_gold")
		$AnimatedSprite2D.play("feedback") # feedback should run 4 frames at 5 frames per second which is equivalent to 0.8 second
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", position - Vector2(0, pickup_rise_distance), pickup_duration)
		tween.parallel().tween_property(self, "modulate:a", 0.0, pickup_duration)
		tween.play() # simulataneously making it invisible and rasing its height at the same time
		await $AnimatedSprite2D.animation_finished
		queue_free() # deletes it


func start_idle_float() -> void:
	if idle_float_enabled == false or is_collected:
		return
	if idle_float_tween != null:
		idle_float_tween.kill()
	if idle_float_start_delay > 0.0:
		await get_tree().create_timer(idle_float_start_delay).timeout
		if is_collected:
			return

	var start_y: float = position.y
	idle_float_tween = create_tween()
	idle_float_tween.set_loops()
	idle_float_tween.tween_property(self, "position:y", start_y - idle_float_distance, idle_float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	idle_float_tween.tween_property(self, "position:y", start_y, idle_float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
