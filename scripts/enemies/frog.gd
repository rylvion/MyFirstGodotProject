extends "res://scripts/enemies/enemy_base.gd"
class_name Frog

func _ready() -> void:
	SPEED = 80.0
	DAMAGE = 5.0
	GOLD = 10
	DETECTION_RANGE = 260.0
	patrol_radius = 160.0
	patrol_pause_time = 0.12
	patrol_speed_multiplier = 0.9
	
	super._ready()
	
