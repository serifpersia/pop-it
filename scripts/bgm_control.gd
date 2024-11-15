extends Node3D

func _ready():
	match name:
		"popit_arcade":
			AudioPlayer.play_bgm_arcade()
		"popit_arcade_plus":
			AudioPlayer.play_bgm_arcade_plus()
		"popit_memory":
			AudioPlayer.play_bgm_memory()
		"popit_fidget":
			AudioPlayer.play_bgm_fidget()
			
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
