extends Control

@onready var timer = $Timer
@onready var btn_click = $btn_click

var last_pressed_button = null

func _on_restart_pressed() -> void:
	play_click()
	last_pressed_button = "restart"

func _on_game_mode_select_pressed() -> void:
	play_click()
	last_pressed_button = "game_mode_select"

func _on_main_menu_pressed():
	play_click()
	last_pressed_button = "mainmenu"

func play_click():
	timer.start()
	btn_click.play()

func _on_timer_timeout():
	if get_tree().paused:
		get_tree().paused = false
		
	if last_pressed_button == "restart":
		get_tree().reload_current_scene()
	elif last_pressed_button == "game_mode_select":
		get_tree().change_scene_to_file("res://scenes/menu_scenes/level_selector_menu.tscn")
	elif last_pressed_button == "mainmenu":
		get_tree().change_scene_to_file("res://scenes/menu_scenes/menu.tscn")
