extends Node

# state variables
var maxHP: int = 10
var playerHP: int = 10
var gold: float = 0.0
var deaths: int = 0
var _level: int = 1

# signals
signal level_changed(new_level: int)
signal hp_changed(new_hp: int)
signal gold_changed(new_gold: float)

func get_hp_upgrade_cost(level: int) -> int:
	var base_cost = 10
	var growth = 1.15
	return int(base_cost * pow(growth, level - 1))

func get_max_hp(level: int) -> int:
	var base_hp: int = 10
	var growth = 1.1
	return int(base_hp * pow(growth, level - 1))

# level property with stat recalculation
var level: int:
	get:
		return _level
	set(value):
		if value != _level:
			var old_max = maxHP
			_level = value
			
			maxHP = get_max_hp(_level)
			playerHP += (maxHP - old_max)
			
			level_changed.emit(value)
			hp_changed.emit(playerHP)
