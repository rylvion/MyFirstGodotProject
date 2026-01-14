extends Node2D 

var sky_speed := 30.0
var sky_repeat := 1152.0 
@onready var sky_layer = $Sky

func scroll_layer(layer: Parallax2D, speed: float, repeat: float, delta: float) -> void:
	layer.scroll_offset.x -= speed * delta
	if repeat > 0:
		layer.scroll_offset.x = fmod(layer.scroll_offset.x, repeat)

func _process(delta: float) -> void:
	scroll_layer(sky_layer, sky_speed, sky_repeat, delta)
