extends Node2D

var cherry = preload("res://scenes/collectables/cherry.tscn")
const DEFAULT_SEGMENTS: Array = [
	{ "y": 300, "x_min": 0,   "x_max": 276 },
	{ "y": 300, "x_min": 312, "x_max": 352 },
	{ "y": 300, "x_min": 568, "x_max": 800 },
	{ "y": 425, "x_min": 832, "x_max": 1136 }
]

var parent_node: Node2D

func _ready() -> void:
	randomize()
	parent_node = $Node2D

func get_random_position(segments: Array = DEFAULT_SEGMENTS) -> Vector2:
	var total_width = 0
	for seg in segments:
		total_width += seg.x_max - seg.x_min + 1

	var r = randi_range(0, total_width - 1)

	for seg in segments:
		var width = seg.x_max - seg.x_min + 1
		if r < width:
			return Vector2(seg.x_min + r, seg.y)
		r -= width
		
	return Vector2.ZERO

func _on_timer_timeout() -> void:
	var cherryTemp = cherry.instantiate()
	cherryTemp.position = get_random_position()
	parent_node.add_child(cherryTemp)
