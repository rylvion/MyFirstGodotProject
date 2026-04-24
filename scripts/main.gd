extends Node2D

@onready var reset_dialog = $ResetDialog

func _ready():
	print("Game started")
	Utils.loadGame()

func _on_quit_pressed() -> void:
	print("quiting...")
	Utils.saveGame()
	get_tree().quit()


func _on_play_pressed() -> void:
	set_process_input(false)
	Game.begin_startup_timer()
	Game.playerHP = Game.maxHP
	Utils.saveGame()
	print("loading")
	get_tree().change_scene_to_file("res://scenes/main/World.tscn")

func _on_reset_button_pressed() -> void:
	reset_dialog.popup_centered()	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		_on_quit_pressed()	
	
	if event.is_action_pressed("ui_accept"):
		_on_play_pressed()


func _on_reset_dialogue_confirmed() -> void:
	print("resetting save...")

	Game.playerHP = Game.maxHP
	Game.gold = 0
	Game.level = 1
	Game.reset_tutorial_progress()

	Utils.saveGame()
	
