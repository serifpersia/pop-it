extends OptionButton

func _ready():
	var savedFullscreen = Global.save_options.get_defaults("Fullscreen")
	if savedFullscreen == -1:
		selected = 0
	else:
		selected = savedFullscreen

func _on_item_selected(index):
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
