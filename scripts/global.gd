extends Node

var save_options : SaveOptions
var game_mode_selected

const resolutions : Dictionary = {
	"1280x720" : Vector2i(1280,720),
	"1920x1080" : Vector2i(1920,1080),
	"2560x1440" : Vector2i(2560,1440)
}

func _ready():
	save_options = SaveOptions.load_or_create()

	var defaults = save_options.get_defaults("Default")
	var fullscreen = save_options.get_defaults("Fullscreen")
	var resolution = save_options.get_defaults("Resolution")

	if defaults == -1:
		for bus_name in ["Master", "SFX", "BGM"]:
			var vol_db = get_default_db(bus_name)
			var vol_index = AudioServer.get_bus_index(bus_name)
			AudioServer.set_bus_volume_db(vol_index, vol_db)
	else:
		for bus_name in ["Master", "SFX", "BGM"]:
			var saved_vol = save_options.get_volume_value(bus_name)
			var vol_db = linear_to_db(saved_vol)
			var vol_index = AudioServer.get_bus_index(bus_name)
			AudioServer.set_bus_volume_db(vol_index, vol_db)

	if fullscreen == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	elif fullscreen == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

	if resolution == 0:
		DisplayServer.window_set_size(resolutions.values()[0])
		centre_window()
	elif resolution == 1:
		DisplayServer.window_set_size(resolutions.values()[1])
		centre_window()
	elif resolution == 2:
		DisplayServer.window_set_size(resolutions.values()[2])
		centre_window()

func get_default_db(bus_name):
	match bus_name:
		"Master":
			return linear_to_db(1.0)
		"SFX":
			return linear_to_db(0.5)
		"BGM":
			return linear_to_db(0.25)

func centre_window():
	var centre_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(centre_screen - window_size/2)
