extends HSlider

@export var bus_name: String
var bus_index: int

func _ready():
	var volume_value = Global.save_options.get_volume_value(bus_name)
	bus_index = AudioServer.get_bus_index(bus_name)
	
	if Global.save_options.get_defaults("Default") == -1:
		value = get_default_value(bus_name)
	else:
		value = volume_value

func _on_value_changed(new_value):
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(new_value))

func get_default_value(new_bus_name):
	match new_bus_name:
		"Master":
			return 1.0
		"SFX":
			return 0.5
		"BGM":
			return 0.25
