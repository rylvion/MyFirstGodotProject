extends "res://scripts/enemies/enemy_base.gd"
class_name Frog

func _ready() -> void:
	SPEED = 80.0
	DAMAGE = 5.0
	GOLD = 10
	DETECTION_RANGE = 104.0
	
	super._ready()
	
