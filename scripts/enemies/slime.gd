extends "res://scripts/enemies/enemy_base.gd"
class_name Slime


func _ready() -> void:
	SPEED = 50.0
	DAMAGE = 3.0
	GOLD = 5
	DETECTION_RANGE = 104.0
	
	super._ready()
	
