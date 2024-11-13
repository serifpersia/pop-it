extends Node3D

@export var transl_mat: StandardMaterial3D

@onready var finish_level_scene: Control = $"../FinishLevelScene"
@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
@onready var high_score: Label = $"../FinishLevelScene/MarginContainer/HBoxContainer/VBoxContainer/Score"

@onready var level_100: ColorRect = $"../CanvasLayer/Score_Display/level_100"
@onready var level_10: ColorRect = $"../CanvasLayer/Score_Display/level_10"
@onready var level_1: ColorRect = $"../CanvasLayer/Score_Display/level_1"

@onready var _1000000: ColorRect = $"../CanvasLayer/Score_Display/1000000"
@onready var _100000: ColorRect = $"../CanvasLayer/Score_Display/100000"
@onready var _10000: ColorRect = $"../CanvasLayer/Score_Display/10000"
@onready var _1000: ColorRect = $"../CanvasLayer/Score_Display/1000"
@onready var _100: ColorRect = $"../CanvasLayer/Score_Display/100"
@onready var _10: ColorRect = $"../CanvasLayer/Score_Display/10"
@onready var _1: ColorRect = $"../CanvasLayer/Score_Display/1"

const INPUT_KEYS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
const MAX_SOUND_HISTORY = 2
const START_BUBBLES = 3
const MAX_BUBBLES = 8
const MAX_SIMULTANEOUS_PRESSES = 6
const BUBBLE_DISPLAY_TIME = 1.0
const SEQUENCE_DELAY = 0.25

var row_config := {
	"row1": PackedInt32Array([0, 1, 2]),
	"row2": PackedInt32Array([3, 4, 5, 6]),
	"row3": PackedInt32Array([7, 8, 9])
}

var game_over := false
var key_states := {}
var current_level := 1
var score := 0
var level_config := {}
var bubble_nodes: Array[Node3D] = []
var sound_pool: Array[AudioStream] = []
var sound_memory_pool: Array[AudioStream] = []
var last_played_sounds: PackedInt32Array = []
var current_pressed_keys := 0
var level_completion_sound: AudioStream = load("res://sounds/mem_victory.wav")
var is_transitioning := false
var combo := 0
var current_hue : float
var sequence_to_match: Array = []
var player_sequence: Array = []
var is_showing_sequence := false
var can_input := false
var increase_bubbles_every := 3
var bubble_increase_interval := 1

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout

	randomize()
	current_hue = randf()
	_cache_bubble_nodes()
	generate_level_config()
	preload_pop_sounds()
	reset_key_states()
	
	initialize_bubble_lights()
	
	start_new_round()

func initialize_bubble_lights() -> void:
	for bubble_node in bubble_nodes:
		var bubble_mesh_instance = bubble_node.get_child(0)
		var omni_light = OmniLight3D.new()
		
		var light_pos = Vector3(bubble_mesh_instance.position.x, bubble_mesh_instance.position.y - 0.114, bubble_mesh_instance.position.z)
		omni_light.position = light_pos
		omni_light.omni_range = 0.088
		omni_light.omni_attenuation = 0.82
		omni_light.light_color = Color.from_hsv(current_hue, 1, 1)
		omni_light.light_energy = 0

		bubble_mesh_instance.add_child(omni_light)
		
func handle_game_over() -> void:
	await get_tree().create_timer(1.0).timeout
	hide()
	canvas_layer.hide()
	finish_level_scene.show()
	high_score.text = "High Score: " + str(score)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _update_score_display(get_score: int) -> void:
	var score_str = str(get_score).pad_zeros(7)
	
	var millions = int(score_str[0])
	var hundreds_thousands = int(score_str[1])
	var tens_thousands = int(score_str[2])
	var thousands = int(score_str[3])
	var hundreds = int(score_str[4])
	var tens = int(score_str[5])
	var units = int(score_str[6])

	_1000000.material.set_shader_parameter("Number", millions)
	_100000.material.set_shader_parameter("Number", hundreds_thousands)
	_10000.material.set_shader_parameter("Number", tens_thousands)
	_1000.material.set_shader_parameter("Number", thousands)
	_100.material.set_shader_parameter("Number", hundreds)
	_10.material.set_shader_parameter("Number", tens)
	_1.material.set_shader_parameter("Number", units)

func _update_level_display(get_level: int) -> void:
	var level_str = str(get_level).pad_zeros(3)
	
	var hundreds = int(level_str[0])
	var tens = int(level_str[1])
	var units = int(level_str[2])

	level_100.material.set_shader_parameter("Number", hundreds)
	level_10.material.set_shader_parameter("Number", tens)
	level_1.material.set_shader_parameter("Number", units)
	
func reset_key_states() -> void:
	key_states.clear()
	current_pressed_keys = 0
	for key in INPUT_KEYS:
		key_states[key] = false

func _cache_bubble_nodes() -> void:
	bubble_nodes.clear()
	for i in 10:
		bubble_nodes.append(get_child(i))

func play_random_sound(mesh_position: Vector3) -> void:
	if sound_pool.is_empty():
		return

	var sound_idx := randi() % sound_pool.size()
	while sound_idx in last_played_sounds:
		sound_idx = randi() % sound_pool.size()

	last_played_sounds.append(sound_idx)
	if last_played_sounds.size() > MAX_SOUND_HISTORY:
		last_played_sounds.remove_at(0)

	var audio := AudioStreamPlayer3D.new()
	audio.stream = sound_pool[sound_idx]
	audio.set_bus("SFX")
	add_child(audio)
	audio.position = mesh_position
	audio.play()
	audio.finished.connect(func(): audio.queue_free())

func play_memory_sound(index: int, mesh_position: Vector3) -> void:
	if sound_memory_pool.is_empty():
		return

	var audio := AudioStreamPlayer3D.new()
	audio.stream = sound_memory_pool[index]
	audio.set_bus("SFX")
	add_child(audio)
	audio.position = mesh_position
	audio.play()

	audio.finished.connect(func(): audio.queue_free())



func preload_pop_sounds() -> void:
	for i in range(1, 11):
		var sound_path := "res://sounds/s%d.wav" % i
		sound_memory_pool.append(load(sound_path))

func generate_level_config() -> void:
	for level in range(1, 101):
		var bubbles := START_BUBBLES + roundi(((MAX_BUBBLES - START_BUBBLES) * float(level - 1)) / 99.0)
		bubbles = clampi(bubbles, START_BUBBLES, MAX_BUBBLES)
		var spacing := maxi(roundi(1.0 - float(level) / 10.0), 1)
		level_config[level] = {"bubbles": bubbles, "spacing": spacing}

func get_level_config(level: int) -> Dictionary:
	if not level_config.has(level):
		var bubbles := START_BUBBLES + roundi(((MAX_BUBBLES - START_BUBBLES) * float(level - 1)) / 99.0)
		bubbles = clampi(bubbles, START_BUBBLES, MAX_BUBBLES)
		var spacing := maxi(roundi(2.0 - float(level) / 10.0), 1)
		level_config[level] = {"bubbles": bubbles, "spacing": spacing}
	return level_config[level]
	
func get_valid_bubble_positions() -> PackedInt32Array:
	var current_config: Dictionary = get_level_config(current_level)
	var valid_positions := PackedInt32Array([])
	var spacing: int = current_config["spacing"]
	var iteration_count := 0
	const MAX_ITERATIONS := 100

	while valid_positions.size() < current_config["bubbles"] and iteration_count < MAX_ITERATIONS:
		iteration_count += 1
		var possible_position := randi() % 10
		
		if _is_valid_position(possible_position, valid_positions, spacing):
			valid_positions.append(possible_position)
	
	return valid_positions

func _is_valid_position(pos: int, existing: PackedInt32Array, spacing: int) -> bool:
	if pos in existing:
		return false
		
	for existing_pos in existing:
		if absi(pos - existing_pos) < spacing:
			return false
			
		for row in row_config.values():
			if pos in row and existing_pos in row:
				var pos_idx: int = row.find(pos)
				var existing_idx: int = row.find(existing_pos)
				if pos_idx != -1 and existing_idx != -1 and absi(pos_idx - existing_idx) < spacing:
					return false
	
	return true

func start_new_round() -> void:
	current_hue = randf()
	player_sequence.clear()
	sequence_to_match.clear()
	can_input = false	
	
	var num_bubbles = get_bubble_count_for_level(current_level)
	for _i in range(num_bubbles):
		sequence_to_match.append(randi() % 10)

	update_light_colors()

	show_sequence()

func update_light_colors() -> void:
	for bubble_node in bubble_nodes:
		var bubble_mesh_instance = bubble_node.get_child(0)
		var omni_light = bubble_mesh_instance.get_child(0) as OmniLight3D
		
		if is_instance_valid(omni_light):
			omni_light.light_color = Color.from_hsv(current_hue, 1, 1)



func get_bubble_count_for_level(level: int) -> int:
	var level_group = float(level - 1) / float(increase_bubbles_every)
	return min(START_BUBBLES + int(level_group), MAX_BUBBLES)

func show_sequence() -> void:
	is_showing_sequence = true
	var sequence_tween = create_tween()
	
	sequence_tween.finished.connect(func(): sequence_tween.kill())
	
	for i in range(sequence_to_match.size()):
		var bubble_idx = sequence_to_match[i]
		
		sequence_tween.tween_callback(func():
			if not is_instance_valid(self):
				return
			remove_existing_lights()
			
			await get_tree().create_timer(0.5).timeout

			light_up_bubble(bubble_idx)
			play_memory_sound(bubble_idx, bubble_nodes[bubble_idx].position)
		)
		
		sequence_tween.tween_interval(BUBBLE_DISPLAY_TIME)
	
	sequence_tween.tween_callback(func():
		if not is_instance_valid(self):
			return
		remove_existing_lights()
		is_showing_sequence = false
		can_input = true
	)

func light_up_bubble(index: int) -> void:
	if index < 0 or index >= bubble_nodes.size():
		return

	var bubble_mesh: MeshInstance3D = bubble_nodes[index]
	if not is_instance_valid(bubble_mesh):
		return

	var bubble_mesh_instance = bubble_mesh.get_child(0)
	if not is_instance_valid(bubble_mesh_instance):
		return

	var omni_light = bubble_mesh_instance.get_child(0) as OmniLight3D
	if not is_instance_valid(omni_light):
		return


	bubble_mesh_instance.material_override = transl_mat
	
	omni_light.light_energy = 2.15
	_handle_bubble_light_up(bubble_mesh_instance)



func player_light_up_bubble(index: int) -> void:
	var bubble_mesh: MeshInstance3D = bubble_nodes[index]
	var bubble_mesh_instance = bubble_mesh.get_child(0)
	bubble_mesh_instance.material_override = transl_mat

	_handle_player_bubble_light_up(bubble_mesh_instance)

func _unhandled_key_input(event: InputEvent) -> void:
	if game_over or is_showing_sequence or not can_input:
		return
	
	for i in INPUT_KEYS.size():
		var key: String = INPUT_KEYS[i]
		if event.is_action_pressed(key) and not key_states[key]:
			_handle_key_press(i)

func _handle_key_press(index: int) -> void:
	if game_over or is_showing_sequence or not can_input:
		return
	
	key_states[INPUT_KEYS[index]] = true
	player_sequence.append(index)

	reset_key_states()

	player_light_up_bubble(index)
	play_memory_sound(index, bubble_nodes[index].position)
	
	var current_pos = player_sequence.size() - 1
	if index != sequence_to_match[current_pos]:
		game_over = true
		handle_game_over()
		return
	
	if player_sequence.size() == sequence_to_match.size():
		can_input = false
		await get_tree().create_timer(0.5).timeout
		advance_level()

func advance_level() -> void:
	if is_transitioning or game_over:
		return
	
	is_transitioning = true
	
	play_level_completion_sound()
	
	await get_tree().create_timer(0.5).timeout
	
	current_level += 1
	_update_level_display(current_level)
	score += 100 * current_level
	_update_score_display(score)
	
	remove_existing_lights()
	reset_key_states()
	
	is_transitioning = false
	start_new_round()
	
func play_level_completion_sound() -> void:
	if level_completion_sound:
		var audio := AudioStreamPlayer3D.new()
		audio.stream = level_completion_sound
		audio.set_bus("SFX")
		add_child(audio)
		audio.play()
		audio.finished.connect(func(): audio.queue_free())

func _handle_bubble_light_up(mesh: MeshInstance3D):
	if not is_instance_valid(mesh):
		return
		
	var tween = create_tween()
	if not tween:
		return
		
	var mesh_light = mesh.get_child(0)
	if not is_instance_valid(mesh_light):
		return
	
	tween.finished.connect(func(): tween.kill())
	tween.tween_property(mesh_light, "light_energy", 2.15, 0.15)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_LINEAR)

func _handle_player_bubble_light_up(mesh: MeshInstance3D):
	if not is_instance_valid(mesh):
		return
		
	var tween = create_tween()
	if not tween:
		return
		
	var mesh_light = mesh.get_child(0)
	if not is_instance_valid(mesh_light):
		return
	
	tween.finished.connect(func(): tween.kill())
	tween.tween_property(mesh_light, "light_energy", 2.15, 0.15)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_LINEAR)
			
	tween.tween_property(mesh_light, "light_energy", 0.0, 0.15)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_LINEAR)

	
func remove_existing_lights() -> void:
	for bubble_idx in range(bubble_nodes.size()):
		var bubble_mesh: MeshInstance3D = bubble_nodes[bubble_idx]
		var bubble_mesh_instance = bubble_mesh.get_child(0)
		
		var omni_light = bubble_mesh_instance.get_child(0) as OmniLight3D
		if is_instance_valid(omni_light):
			omni_light.light_energy = 0
