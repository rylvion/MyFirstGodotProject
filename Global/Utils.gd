extends Node

const SAVE_PATH = "res://savegame.bin"

func saveGame():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var data: Dictionary = {
		"playerHP": Game.playerHP,
		"gold": Game.gold,
		"deaths": Game.deaths,
		"level": Game.level,
		"maxHP": Game.maxHP
	}
	var jstr = JSON.stringify(data)
	file.store_line(jstr)
	
	
func loadGame():	
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	if typeof(data) == TYPE_DICTIONARY:
		Game.playerHP = max(data.get("playerHP", 10), 0)
		Game.gold = data.get("gold", 0)
		Game.deaths = data.get("deaths", 0)
		Game.level = data.get("level", 1)
		Game.maxHP = data.get("maxHP", 10)
