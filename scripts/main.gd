extends Node

func _ready() -> void:
	var scene_to_load = null
	
	match Global.game_mode_selected:
		0:
			scene_to_load = load("res://scenes/pop-it-arcade1.tscn")
		1:
			scene_to_load = load("res://scenes/pop-it-arcade2.tscn")
		2:
			scene_to_load = load("res://scenes/pop-it-memory.tscn")
		3:
			scene_to_load = load("res://scenes/pop-it-fidget.tscn")

	if scene_to_load:
		var instance = scene_to_load.instantiate()
		add_child(instance)
