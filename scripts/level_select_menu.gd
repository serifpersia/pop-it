extends Control

@onready var timer = $Timer
@onready var btn_click = $btn_click

var last_pressed_button = null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioPlayer.play_bgm_menu()

func play_click():
	timer.start()
	btn_click.play()

# Button press handlers
func _on_arcade_mode_pressed() -> void:
	play_click()
	last_pressed_button = "arcade"

func _on_arcade_plus_mode_pressed() -> void:
	play_click()
	last_pressed_button = "arcade_plus"

func _on_memory_mode_pressed() -> void:
	play_click()
	last_pressed_button = "memory"

func _on_fidget_mode_pressed() -> void:
	play_click()
	last_pressed_button = "fidget"

func _on_main_menu_pressed():
	play_click()
	last_pressed_button = "main_menu"
	
func _on_timer_timeout():
	if last_pressed_button == "main_menu":
		get_tree().change_scene_to_file("res://scenes/menu_scenes/menu.tscn")
	else:
		match last_pressed_button:
			"arcade":
				Global.game_mode_selected = 0
			"arcade_plus":
				Global.game_mode_selected = 1
			"memory":
				Global.game_mode_selected = 2
			"fidget":
				Global.game_mode_selected = 3

		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
