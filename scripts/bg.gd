extends Node2D

var sky_speed := 30.0
var mountains_speed := 100.0
var houses_speed := 50.0

var sky_repeat := 1152.0
var mountains_repeat := 1172.0
var houses_repeat := 1172.0

@onready var sky_layer = $Sky
@onready var mountains_layer = $Mountains
@onready var houses_layer = $Houses

# Generalized scroll function
func scroll_layer(layer: Parallax2D, speed: float, repeat: float, delta: float) -> void:
	layer.scroll_offset.x -= speed * delta
	if repeat > 0:
		layer.scroll_offset.x = fmod(layer.scroll_offset.x, repeat)

func _process(delta: float) -> void:
	scroll_layer(sky_layer, sky_speed, sky_repeat, delta)
	scroll_layer(mountains_layer, mountains_speed, mountains_repeat, delta)
	scroll_layer(houses_layer, houses_speed, houses_repeat, delta)
