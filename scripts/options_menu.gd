extends Control

@onready var timer = $Timer
@onready var btn_click = $btn_click

@onready var master_vol = $MarginContainer/HBoxContainer/VBoxContainer/BoxContainer/master_vol
@onready var sfx_vol = $MarginContainer/HBoxContainer/VBoxContainer/BoxContainer/sfx_vol
@onready var bgm_vol = $MarginContainer/HBoxContainer/VBoxContainer/BoxContainer/bgm_vol
@onready var fullscreen_toggle = $MarginContainer/HBoxContainer/VBoxContainer/GridContainer5/fullscreenToggle
@onready var resolution_selected = $MarginContainer/HBoxContainer/VBoxContainer/GridContainer/resolutionSelected

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func play_click():
	save_vol_options(master_vol)
	save_vol_options(sfx_vol)
	save_vol_options(bgm_vol)
	save_display_options()
	
	timer.start()
	btn_click.play()

func save_vol_options(vol):
	Global.save_options.save_volume_for_bus(vol.bus_name, vol.value)

func save_display_options():
	Global.save_options.save_defaults("Default", 0)
	Global.save_options.save_defaults("Fullscreen", fullscreen_toggle.selected)
	Global.save_options.save_defaults("Resolution", resolution_selected.selected)

func _on_main_menu_pressed():
	play_click()

func _on_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/menu_scenes/menu.tscn")
