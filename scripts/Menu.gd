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

func _on_level_editor_pressed():
	play_click()
	#last_pressed_button = "level_editor"

func _on_quit_pressed():
	play_click()
	last_pressed_button = "quit"

func _on_play_mouse_entered():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_play_mouse_exited():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_options_mouse_entered():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_level_editor_mouse_entered():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_level_editor_mouse_exited():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_options_mouse_exited():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_quit_mouse_entered():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_quit_mouse_exited():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func play_click():
	timer.start()
	btn_click.play()

func _on_timer_timeout():
	if last_pressed_button == "play":
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	elif last_pressed_button == "options":
		get_tree().change_scene_to_file("res://scenes/menu_scenes/options_menu.tscn")
	elif last_pressed_button == "level_editor":
		get_tree().change_scene_to_file("res://scenes/menu_scenes/level_editor.tscn")
		print('test')
	elif last_pressed_button == "quit":
		get_tree().quit()
