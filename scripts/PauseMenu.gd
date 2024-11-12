extends Node2D

@onready var timer: Timer = $CanvasLayer/PauseMenu/Timer
@onready var btn_click: AudioStreamPlayer = $CanvasLayer/PauseMenu/btn_click
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var last_pressed_button = null

func _ready():
	canvas_layer.hide()

func resume():
	get_tree().paused = false
	canvas_layer.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func pause():
	get_tree().paused = true
	canvas_layer.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		togglePause()

func togglePause():
	if get_tree().paused:
		resume()
	else:
		pause()

func _on_resume_pressed():
	play_click()
	last_pressed_button = "resume"

func _on_restart_pressed() -> void:
	play_click()
	last_pressed_button = "restart"


func _on_main_menu_pressed():
	play_click()
	last_pressed_button = "mainmenu"

func play_click():
	timer.start()
	btn_click.play()

func _on_timer_timeout():
	if last_pressed_button == "resume":
		resume()
	elif last_pressed_button == "restart":
		resume()
		get_tree().reload_current_scene()
	elif last_pressed_button == "mainmenu":
		resume()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/menu_scenes/menu.tscn")
