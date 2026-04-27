extends "res://scripts/enemies/enemy_base.gd"
class_name Slime

static var _cached_slime_frames: SpriteFrames = null


func _ready() -> void:
	_ensure_slime_frames_loaded()
	SPEED = 50.0
	DAMAGE = 3.0
	GOLD = 5
	DETECTION_RANGE = 210.0
	patrol_radius = 136.0
	patrol_pause_time = 0.18
	patrol_speed_multiplier = 0.78
	movement_sfx_key = &"slime_move"
	movement_sfx_cooldown = 0.62
	movement_sfx_volume_db = -18.0
	
	super._ready()


func _ensure_slime_frames_loaded() -> void:
	if sprite == null:
		return

	if _scene_frames_are_usable(sprite.sprite_frames):
		return

	if _cached_slime_frames == null:
		_cached_slime_frames = _build_slime_frames()

	if _cached_slime_frames != null and _cached_slime_frames.get_frame_count("idle") > 0:
		_cached_slime_frames.set_animation_loop("idle", true)
		sprite.sprite_frames = _cached_slime_frames
		sprite.visible = true

func _scene_frames_are_usable(frames: SpriteFrames) -> bool:
	if frames == null:
		return false

	var required := ["idle", "attack", "death"]
	for anim_name in required:
		if not frames.has_animation(anim_name):
			return false
		if frames.get_frame_count(anim_name) <= 0:
			return false
		if frames.get_frame_texture(anim_name, 0) == null:
			return false

	return true

func _build_slime_frames() -> SpriteFrames:
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

	return frames


func _add_animation(frames: SpriteFrames, anim_name: String, texture_paths: Array[String], loop: bool, speed: float) -> void:
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)
	for path in texture_paths:
		var texture: Texture2D = _load_texture_fallback(path)
		if texture != null:
			frames.add_frame(anim_name, texture)

func _load_texture_fallback(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null

	var abs_path := ProjectSettings.globalize_path(path)
	var image := Image.load_from_file(abs_path)
	if image == null or image.is_empty():
		return null

	return ImageTexture.create_from_image(image)
	
