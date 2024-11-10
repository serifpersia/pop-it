extends Node3D

const INPUT_KEYS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]

var key_states := {}
var current_pressed_keys := 0

const MAX_SIMULTANEOUS_PRESSES = 6

@onready var test_key_mesh: MeshInstance3D = $"2/1_004"

var current_hue := 0.0  # Track the hue for color change

func _ready() -> void:
	_reset_key_states()
	_set_key_Lights()

func _set_key_Lights()-> void:
	print('t')
	
	var omni_light = OmniLight3D.new()
	
	var light_pos = Vector3(test_key_mesh.position.x,test_key_mesh.position.y - 0.12,test_key_mesh.position.z)
	omni_light.position = light_pos
	
	omni_light.omni_range = 0.089
	omni_light.omni_attenuation = 0.883
	#omni_light.light_color = Color(0, 0.949, 1)
	omni_light.light_color = Color.from_hsv(current_hue, 1, 1)  # Set initial color with HSV
	omni_light.light_energy = 0
	
	for key in INPUT_KEYS:
		print(key)
	
	test_key_mesh.add_child(omni_light)

func _unhandled_key_input(event: InputEvent) -> void:
	for i in INPUT_KEYS.size():
		var key: String = INPUT_KEYS[i]
		if event.is_action_pressed(key) and not key_states[key]:
			if current_pressed_keys < MAX_SIMULTANEOUS_PRESSES:
				current_pressed_keys += 1
				_handle_key_press(i)
		elif event.is_action_released(key) and key_states[key]:
			current_pressed_keys -= 1
			_handle_key_release(i)

func _change_light_color() -> void:
	# Increment hue for each press (wrap around if it exceeds 1.0)
	current_hue = fmod(current_hue + 0.1, 1.0)

		
	# Update the light color with the new hue
	var new_color = Color.from_hsv(current_hue, 1, 1)  # Set high saturation and value
	test_key_mesh.get_child(0).light_color = new_color
	print("New light color hue:", current_hue)
	
func _handle_key_press(index: int):

	_change_light_color()

	key_states[INPUT_KEYS[index]] = true
	if INPUT_KEYS[index] == "1":
		print("Key '1' is pressed:", key_states[INPUT_KEYS[index]])
		
		var tween = create_tween()
		tween.tween_property(test_key_mesh.get_child(0), "light_energy", 2.25, 0.05)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_LINEAR)
		
func _handle_key_release(index: int):
	key_states[INPUT_KEYS[index]] = false
	if INPUT_KEYS[index] == "1":
		print("Key '1' is released:", key_states[INPUT_KEYS[index]])
		
		var tween = create_tween()
		tween.tween_property(test_key_mesh.get_child(0), "light_energy", 0.0, 0.06)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_LINEAR)


func _reset_key_states() -> void:
	key_states.clear()
	current_pressed_keys = 0
	for key in INPUT_KEYS:
		key_states[key] = false
