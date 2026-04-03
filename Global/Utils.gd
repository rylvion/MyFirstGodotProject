extends Node

const SAVE_PATH = "user://savegame.bin"

func saveGame():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing")
		return
		
	var data: Dictionary = {
		"playerHP": Game.playerHP,
		"gold": Game.gold,
		"deaths": Game.deaths,
		"level": Game.level,
		"maxHP": Game.maxHP
	}
	
	var jstr = JSON.stringify(data)
	file.store_string(jstr)
	file.close()


func loadGame():	
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading")
		return
		
	var text = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(text)
	if data == null:
		push_error("Save file corrupted")
		return
	
	if typeof(data) == TYPE_DICTIONARY:
		Game.playerHP = clamp(data.get("playerHP", 10), 0, Game.maxHP)
		Game.gold = data.get("gold", 0)
		Game.deaths = data.get("deaths", 0)
		Game.level = data.get("level", 1)
		Game.maxHP = data.get("maxHP", 10)
