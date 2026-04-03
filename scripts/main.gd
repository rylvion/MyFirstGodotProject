extends Node2D

@onready var reset_dialog = $ResetDialog

func _ready():
	print("[main] Game started")
	Utils.loadGame()

func _on_quit_pressed() -> void:
	print("[main] [func _on_quit_pressed] Quiting...")
	get_tree().quit()


func _on_play_pressed() -> void:
	set_process_input(false)
	if Game.playerHP <= 0:
		Game.deaths += 1
		Game.playerHP = Game.maxHP
		Utils.saveGame()
	print("[main] [func _on_play_pressed] Transitioning to world.tscn")
	get_tree().change_scene_to_file("res://scenes/main/World.tscn")

func _on_reset_button_pressed() -> void:
	reset_dialog.popup_centered()	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		print("[main] Quiting...")
		get_tree().quit()
	
	if event.is_action_pressed("ui_accept"):
		_on_play_pressed()
	


func _on_reset_dialogue_confirmed() -> void:
	print("[main] Resetting save...")

	Game.playerHP = Game.maxHP
	Game.gold = 0
	Game.deaths = 0
	Game.level = 1

	Utils.saveGame()
	
