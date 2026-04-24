extends Node2D

var cherry = preload("res://scenes/collectables/cherry.tscn")
const MAX_ACTIVE_CHERRIES: int = 15
const DEFAULT_SEGMENTS: Array = [
	{ "y": 298, "x_min": 48, "x_max": 2248 }
]

var parent_node: Node2D
var active_cherries: int = 0

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
	if active_cherries >= MAX_ACTIVE_CHERRIES:
		return

	var cherryTemp = cherry.instantiate()
	cherryTemp.position = get_random_position()
	cherryTemp.tree_exited.connect(_on_cherry_tree_exited, CONNECT_ONE_SHOT)
	parent_node.add_child(cherryTemp)
	active_cherries += 1

func _on_cherry_tree_exited() -> void:
	active_cherries = max(active_cherries - 1, 0)
