extends OptionButton

const resolutions : Dictionary = {
	"1280x720" : Vector2i(1280,720),
	"1920x1080" : Vector2i(1920,1080),
	"2560x1440" : Vector2i(2560,1440)
}

func _ready():
	var savedResolution = Global.save_options.get_defaults("Resolution")
	if savedResolution == -1:
		selected = 0
	else:
		selected = savedResolution
	
func _on_item_selected(index):
	DisplayServer.window_set_size(resolutions.values()[index])
	centre_window()

func centre_window():
	var centre_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(centre_screen - window_size/2)
