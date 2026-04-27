extends Control

const SETTINGS_MENU_SCRIPT: GDScript = preload("res://scripts/ui/settings_menu.gd")

@onready var settings_button: BaseButton = $SettingsButtons

var settings_menu: CanvasLayer

func _ready():
	print("Game started")
	Utils.loadGame()
	SoundManager.play_music(&"main_menu", -6.0)
	_setup_settings_menu()
	if settings_button != null and settings_button.pressed.is_connected(_on_settings_pressed) == false:
		settings_button.pressed.connect(_on_settings_pressed)

func _on_quit_pressed() -> void:
	print("quiting...")
	Utils.saveGame()
	get_tree().quit()


func _on_play_pressed() -> void:
	if settings_menu != null and settings_menu.has_method("is_menu_open") and settings_menu.call("is_menu_open"):
		return
	set_process_input(false)
	Game.begin_startup_timer()
	Game.playerHP = Game.maxHP
	Utils.saveGame()
	print("loading")
	get_tree().change_scene_to_file("res://scenes/main/World.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		_on_quit_pressed()	
	
	if event.is_action_pressed("ui_accept"):
		_on_play_pressed()


func _setup_settings_menu() -> void:
	settings_menu = SETTINGS_MENU_SCRIPT.new() as CanvasLayer
	if settings_menu == null:
		return

	settings_menu.set("show_gear_button", false)
	settings_menu.set("block_game_input", false)
	add_child(settings_menu)


func _on_settings_pressed() -> void:
	if settings_menu == null:
		return
	if settings_menu.has_method("set_menu_open"):
		settings_menu.call("set_menu_open", true)
	
