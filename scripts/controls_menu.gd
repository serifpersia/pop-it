extends Control

@onready var timer = $Timer
@onready var btn_click = $btn_click

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func play_click():
	timer.start()
	btn_click.play()

func _on_main_menu_pressed():
	play_click()

func _on_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/menu_scenes/menu.tscn")
