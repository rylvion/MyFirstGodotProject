extends Button

var cost: int = 0

func get_hp_upgrade_cost(level: int) -> int:
	var base_cost = 10
	var growth = 1.15
	return int(base_cost * pow(growth, level - 1))

func get_max_hp(level: int) -> int:
	var base_hp: int = 10
	var growth = 1.1
	return int(base_hp * pow(growth, level - 1))

func _ready() -> void:
	cost = get_hp_upgrade_cost(Game.level)
	text = "+1 Level for $%d" % cost

func _on_pressed() -> void:
	if Game.gold >= cost:
		Game.gold -= cost
		Game.level += 1
		Game.maxHP = get_max_hp(Game.level)
		Game.playerHP += int(get_max_hp(Game.level) - get_max_hp(Game.level - 1))
		
		cost = get_hp_upgrade_cost(Game.level)
		text = "+1 Level for $%d" % cost
	else:
		text = "Not enough Gold"
		await get_tree().create_timer(2.0).timeout
		cost = get_hp_upgrade_cost(Game.level)
		text = "+1 Level for $%d" % cost
