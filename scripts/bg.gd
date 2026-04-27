extends Parallax2D

@export var sky_speed := 30.0
@export var mountains_speed := 100.0
@export var houses_speed := 50.0

@export var sky_repeat_hint := 1152.0
@export var mountains_repeat_hint := 1172.0
@export var houses_repeat_hint := 1172.0

@export var viewport_padding := 64.0

@onready var sky_layer: Parallax2D = $Sky
@onready var mountains_layer: Parallax2D = $Mountains
@onready var houses_layer: Parallax2D = $Houses

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var viewport_width := get_viewport_rect().size.x
	_ensure_repeat(sky_layer, sky_repeat_hint, viewport_width)
	_ensure_repeat(mountains_layer, mountains_repeat_hint, viewport_width)
	_ensure_repeat(houses_layer, houses_repeat_hint, viewport_width)

func _ensure_repeat(layer: Parallax2D, hint: float, viewport_width: float) -> void:
	if layer == null:
		return
	var content_width: float = _compute_layer_width(layer)
	if content_width > 0.0:
		layer.repeat_size.x = content_width
	else:
		layer.repeat_size.x = max(hint, viewport_width + viewport_padding)

func _compute_layer_width(layer: Parallax2D) -> float:
	var min_x: float = INF
	var max_x: float = -INF
	var found: bool = false
	for child in layer.get_children():
		if child is Sprite2D:
			var sprite: Sprite2D = child
			var tex := sprite.texture
			if tex == null:
				continue
			var width: float = tex.get_size().x * abs(sprite.scale.x)
			var left: float = sprite.position.x - (width * 0.5 if sprite.centered else 0.0)
			var right: float = left + width
			min_x = min(min_x, left)
			max_x = max(max_x, right)
			found = true
	return max(1.0, max_x - min_x) if found else 0.0

func scroll_layer(layer: Parallax2D, speed: float, repeat: float, delta: float) -> void:
	if layer == null:
		return
	var period: float = repeat if repeat > 0.0 else layer.repeat_size.x
	if period <= 0.0:
		return
	layer.scroll_offset.x = fposmod(layer.scroll_offset.x - speed * delta, period)

func fposmod(value: float, modulus: float) -> float:
	var result := fmod(value, modulus)
	return result + modulus if result < 0.0 else result

func _on_viewport_size_changed() -> void:
	var viewport_width := get_viewport_rect().size.x
	_ensure_repeat(sky_layer, sky_repeat_hint, viewport_width)
	_ensure_repeat(mountains_layer, mountains_repeat_hint, viewport_width)
	_ensure_repeat(houses_layer, houses_repeat_hint, viewport_width)

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_on_viewport_size_changed()

func _process(delta: float) -> void:
	scroll_layer(sky_layer, sky_speed, sky_repeat_hint, delta)
	scroll_layer(mountains_layer, mountains_speed, mountains_repeat_hint, delta)
	scroll_layer(houses_layer, houses_speed, houses_repeat_hint, delta)
