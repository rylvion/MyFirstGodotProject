extends Button

var cost: int = 0

func _ready() -> void:
	cost = Game.get_hp_upgrade_cost(Game.level)
	text = "+1 Level for $%d" % cost
	
	if Game.has_signal("level_changed"):
		Game.connect("level_changed", Callable(self, "_on_level_changed"))

func _on_level_changed(_new_level: int) -> void:
	cost = Game.get_hp_upgrade_cost(Game.level)
	text = "+1 Level for $%d" % cost

func _on_pressed() -> void:
	if Game.try_level_up():
		Utils.saveGame()
		cost = Game.get_hp_upgrade_cost(Game.level)
		text = "+1 Level for $%d" % cost
	else:
		text = "Not enough Gold"
		await get_tree().create_timer(2.0).timeout
		cost = Game.get_hp_upgrade_cost(Game.level)
		text = "+1 Level for $%d" % cost
