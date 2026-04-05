extends "res://scripts/enemies/enemy_base.gd"
class_name Slime


func _ready() -> void:
	_ensure_slime_frames_loaded()
	SPEED = 50.0
	DAMAGE = 3.0
	GOLD = 5
	DETECTION_RANGE = 104.0
	
	super._ready()


func _ensure_slime_frames_loaded() -> void:
	if not has_node("AnimatedSprite2D"):
		return

	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	var frames := SpriteFrames.new()

	_add_animation(frames, "idle", [
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer-Idle/slimer-idle1.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer-Idle/slimer-idle2.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer-Idle/slimer-idle3.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer-Idle/slimer-idle4.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer-Idle/slimer-idle5.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer-Idle/slimer-idle6.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer-Idle/slimer-idle7.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer-Idle/slimer-idle8.png"
	], true, 5.0)

	_add_animation(frames, "attack", [
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer/slimer1.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer/slimer2.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer/slimer3.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer/slimer4.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer/slimer5.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer/slimer6.png",
		"res://assets/Characters/Enemies and NPC/Slimer/Sprites/Slimer/slimer7.png"
	], true, 5.0)

	_add_animation(frames, "death", [
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-1.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-2.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-3.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-4.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-5.png",
		"res://assets/Props Items and VFX/enemy-death/Sprites/enemy-death-6.png"
	], false, 5.0)

	if frames.get_frame_count("idle") > 0:
		sprite.sprite_frames = frames
		sprite.visible = true


func _add_animation(frames: SpriteFrames, name: String, texture_paths: Array[String], loop: bool, speed: float) -> void:
	if not frames.has_animation(name):
		frames.add_animation(name)
	frames.set_animation_loop(name, loop)
	frames.set_animation_speed(name, speed)
	for path in texture_paths:
		var texture: Texture2D = load(path)
		if texture != null:
			frames.add_frame(name, texture)
	
