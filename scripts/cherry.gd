extends Area2D

func _ready() -> void:
	$AnimatedSprite2D.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		Game.gold += 8
		print("[cherry] Picked!")
		$AnimatedSprite2D.play("feedback") # feedback should run 4 frames at 5 frames per second which is equivalent to 0.8 second
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", position - Vector2(0,25), 0.8)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
		tween.play()
		await $AnimatedSprite2D.animation_finished
		queue_free()
		
