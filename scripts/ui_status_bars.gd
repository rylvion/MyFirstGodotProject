extends Control

@onready var health_bar: ProgressBar = $Panel/HealthBar
@onready var health_value_label: Label = $Panel/HealthValue
@onready var gold_bar: ProgressBar = $Panel/GoldBar
@onready var gold_value_label: Label = $Panel/GoldValue
@onready var level_value_label: Label = $Panel/LevelValue

var _target_health: float = 0.0
var _target_gold: float = 0.0

func _ready() -> void:
	health_bar.min_value = 0.0
	gold_bar.min_value = 0.0
	health_bar.value = 0.0
	gold_bar.value = 0.0

func _process(delta: float) -> void:
	var t: float = minf(1.0, delta * 10.0)
	health_bar.value = lerpf(health_bar.value, _target_health, t)
	gold_bar.value = lerpf(gold_bar.value, _target_gold, t)

func set_health(current_hp: int, max_hp: int) -> void:
	var safe_max: int = max(1, max_hp)
	health_bar.max_value = float(safe_max)
	_target_health = clampf(float(current_hp), 0.0, float(safe_max))
	health_bar.value = _target_health
	health_value_label.text = "HP %d/%d" % [max(current_hp, 0), safe_max]

func set_gold_progress(current_gold: float, target_gold: int) -> void:
	var safe_target: int = max(1, target_gold)
	gold_bar.max_value = float(safe_target)
	_target_gold = clampf(current_gold, 0.0, float(safe_target))
	gold_bar.value = _target_gold
	var percent: int = int(round((_target_gold / float(safe_target)) * 100.0))
	gold_value_label.text = "Gold to next level: %d/%d (%d%%)" % [int(current_gold), safe_target, percent]

func set_level(level: int) -> void:
	level_value_label.text = "Lvl %d" % max(level, 1)
