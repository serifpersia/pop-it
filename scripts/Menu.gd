extends Control

@onready var timer = $Timer
@onready var btn_click = $btn_click

var last_pressed_button = null

func _ready():
	AudioPlayer.play_bgm_menu()

func _on_play_pressed():
	play_click()
	last_pressed_button = "play"

func _on_options_pressed():
	play_click()
	last_pressed_button = "options"

func _on_controls_pressed() -> void:
	play_click()
	last_pressed_button = "controls"

func _on_quit_pressed():
	play_click()
	last_pressed_button = "quit"

func play_click():
	timer.start()
	btn_click.play()

func _on_timer_timeout():
	if last_pressed_button == "play":
		get_tree().change_scene_to_file("res://scenes/menu_scenes/level_selector_menu.tscn")
	elif last_pressed_button == "options":
		get_tree().change_scene_to_file("res://scenes/menu_scenes/options_menu.tscn")
	elif last_pressed_button == "controls":
		get_tree().change_scene_to_file("res://scenes/menu_scenes/controls_menu.tscn")
	elif last_pressed_button == "quit":
		get_tree().quit()
