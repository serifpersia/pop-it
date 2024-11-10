extends Node3D

const INPUT_KEYS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
const MAX_SOUND_HISTORY = 2
const START_BUBBLES = 3
const MAX_BUBBLES = 10

var key_states := {}
var active_bubbles: PackedInt32Array = []
var previous_bubbles: PackedInt32Array = []
var current_level := 1
var score := 0
var total_levels := 35

var level_config := {}
var bubble_nodes: Array[Node3D] = []
var sound_pool: Array[AudioStream] = []
var last_played_sounds: PackedInt32Array = []
var active_tweens := {}

var row_config := {
	"row1": PackedInt32Array([0, 1, 2]),
	"row2": PackedInt32Array([3, 4, 5, 6]),
	"row3": PackedInt32Array([7, 8, 9])
}

var current_pressed_keys := 0
const MAX_SIMULTANEOUS_PRESSES = 6

var level_completion_sound: AudioStream = load("res://sounds/pop-it_Insert 15.wav")

var popped_bubbles: PackedInt32Array = []
var is_transitioning := false

var combo := 0

@onready var combo_label: Label = $"../CanvasLayer/Combo_Label"

@export var transl_mat: StandardMaterial3D

var current_hue : float

@onready var _10000: ColorRect = $"../CanvasLayer/Score_Display/10000"
@onready var _1000: ColorRect = $"../CanvasLayer/Score_Display/1000"
@onready var _100: ColorRect = $"../CanvasLayer/Score_Display/100"
@onready var _10: ColorRect = $"../CanvasLayer/Score_Display/10"
@onready var _1: ColorRect = $"../CanvasLayer/Score_Display/1"

func _ready() -> void:
	randomize()
	current_hue = randf()
	_cache_bubble_nodes()
	generate_level_config()
	preload_pop_sounds()
	reset_key_states()
	start_new_round()

func update_score_display(get_score: int) -> void:
	var score_str = str(get_score).pad_zeros(5)
	var tens_thousands = int(score_str[0])
	var thousands = int(score_str[1])
	var hundreds = int(score_str[2])
	var tens = int(score_str[3])
	var units = int(score_str[4])

	_10000.material.set_shader_parameter("Number", tens_thousands)
	_1000.material.set_shader_parameter("Number", thousands)
	_100.material.set_shader_parameter("Number", hundreds)
	_10.material.set_shader_parameter("Number", tens)
	_1.material.set_shader_parameter("Number", units)

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
	add_child(audio)
	audio.position = mesh_position
	audio.play()
	audio.finished.connect(func(): audio.queue_free())

func preload_pop_sounds() -> void:
	for i in range(1, 15):
		var sound_path := "res://sounds/pop-it_Insert %d.wav" % i
		sound_pool.append(load(sound_path))

func generate_level_config() -> void:
	for level in range(1, total_levels + 1):
		var bubbles := START_BUBBLES + roundi(((MAX_BUBBLES - START_BUBBLES) * float(level - 1)) / float(total_levels - 1))
		bubbles = clampi(bubbles, START_BUBBLES, MAX_BUBBLES)
		var spacing := maxi(roundi(3.0 - float(level) / (float(total_levels) / 10.0)), 1)
		level_config[level] = {"bubbles": bubbles, "spacing": spacing}

func get_valid_bubble_positions() -> PackedInt32Array:
	var current_config: Dictionary = level_config[current_level]
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
	remove_existing_lights()
	
	active_bubbles = get_valid_bubble_positions()
	previous_bubbles = active_bubbles.duplicate()
	
	current_hue = randf()
	
	for bubble_idx in active_bubbles:
		light_up_bubble(bubble_idx)

func light_up_bubble(index: int) -> void:
	var bubble_mesh: MeshInstance3D = bubble_nodes[index]
	var bubble_mesh_instance = bubble_mesh.get_child(0)
	bubble_mesh_instance.material_override = transl_mat

	_set_key_Lights(bubble_mesh_instance)
	_handle_bubble_light_up(bubble_mesh_instance)

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

func _handle_key_press(index: int) -> void:
	if is_transitioning or index >= bubble_nodes.size():
		return
		
	key_states[INPUT_KEYS[index]] = true
	var cap_mesh: MeshInstance3D = bubble_nodes[index].get_child(0)
	
	if not (index in popped_bubbles):

		if index in active_bubbles:
			var base_score = 15
			var multiplier = get_multiplier()
			var score_increase = base_score * multiplier
			score += score_increase
			
			update_score_display(score)
			update_combo(true)

			var new_active_bubbles := PackedInt32Array([])
			for bubble in active_bubbles:
				if bubble != index:
					new_active_bubbles.append(bubble)
			active_bubbles = new_active_bubbles
			
			popped_bubbles.append(index)
			play_random_sound(bubble_nodes[index].position)
			
			if index in active_tweens and active_tweens[index] != null:
				active_tweens[index].kill()
			
			var tween = create_tween()
			active_tweens[index] = tween
			tween.tween_property(cap_mesh, "blend_shapes/popped", 1.0, 0.1)\
				.set_ease(Tween.EASE_OUT)\
				.set_trans(Tween.TRANS_CUBIC)
			
			var material_tween = create_tween()
			material_tween.tween_callback(func():
				transl_mat.roughness = 0.5
				cap_mesh.material_override = transl_mat
			).set_delay(0.1)
			
			if active_bubbles.is_empty():
				await get_tree().create_timer(0.2).timeout
				advance_level()
		elif not (index in previous_bubbles):
			update_combo(false)

func _handle_key_release(index: int) -> void:
	key_states[INPUT_KEYS[index]] = false

func advance_level() -> void:
	if is_transitioning:
		return
		
	is_transitioning = true
	
	for tween in active_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	active_tweens.clear()
	
	play_level_completion_sound()
	current_level = (current_level % total_levels) + 1
	if current_level == 1:
		score = 0
		combo = 0
		update_score_display(score)
	print(current_level)
	
	var reset_tween = create_tween()
	reset_tween.set_parallel(true)
	
	remove_existing_lights()
	
	for bubble_idx in range(bubble_nodes.size()):
		var cap_mesh: MeshInstance3D = bubble_nodes[bubble_idx].get_child(0)
		if cap_mesh:
			reset_tween.tween_property(cap_mesh, "blend_shapes/popped", 0.0, 0.2)\
				.set_ease(Tween.EASE_OUT)\
				.set_trans(Tween.TRANS_CUBIC)
			
			var default_material := StandardMaterial3D.new()
			default_material.roughness = 0.5
			default_material.albedo_color = Color(0.792, 0.808, 0.973)
			cap_mesh.material_override = default_material
			bubble_nodes[bubble_idx].material_override = default_material
	
	await reset_tween.finished
	
	reset_key_states()
	popped_bubbles.clear()
	is_transitioning = false
	start_new_round()

func play_level_completion_sound() -> void:
	if level_completion_sound:
		var audio := AudioStreamPlayer3D.new()
		audio.stream = level_completion_sound
		add_child(audio)
		audio.position = Vector3(-0.3, 0.5, 0)
		audio.play()
		audio.finished.connect(func(): audio.queue_free())

var active_combo_tween: Tween = null

func get_multiplier() -> int:
	if combo > 100:
		combo_label.set_modulate(Color(1, 1, 1))
		return 10
	elif combo > 55:
		combo_label.set_modulate(Color(1.0, 0.6, 0.0))
		return 8
	elif combo > 30:
		combo_label.set_modulate(Color(1.0, 1.0, 0.0))
		return 4
	elif combo > 20:
		combo_label.set_modulate(Color(0.0, 1.0, 0.4))
		return 3
	elif combo > 5:
		combo_label.set_modulate(Color(0.3, 0.6, 1))
		return 2
	else:
		combo_label.set_modulate(Color(0.7, 0.7, 0.7))
		return 1

func update_combo(increase: bool) -> void:
	if increase:
		combo += 1
		combo_label.set_text(str(combo))
		
		if active_combo_tween and active_combo_tween.is_valid():
			active_combo_tween.kill()
			
		active_combo_tween = create_tween()
		
		combo_label.scale = Vector2.ONE
		
		active_combo_tween.tween_property(combo_label, "scale", Vector2(1.1, 1.1), 0.1)
		active_combo_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		
		active_combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.1).set_delay(0.1)
		active_combo_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	else:
		combo = 0
		combo_label.set_text("")

func _handle_bubble_light_up(mesh: MeshInstance3D):
	var tween = create_tween()
	
	var mesh_light = mesh.get_child(0)
	
	if mesh_light:
		tween.tween_property(mesh_light, "light_energy", 2.15, 0.1)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_LINEAR)


func _set_key_Lights(mesh_instance: MeshInstance3D)-> void:
	
	var omni_light = OmniLight3D.new()
	
	var light_pos = Vector3(mesh_instance.position.x,mesh_instance.position.y - 0.114, mesh_instance.position.z)
	omni_light.position = light_pos
	
	omni_light.omni_range = 0.088
	omni_light.omni_attenuation = 0.82
	omni_light.light_color = Color.from_hsv(current_hue, 1, 1)
	omni_light.light_energy = 0
	
	mesh_instance.add_child(omni_light)

func remove_existing_lights() -> void:
	for bubble_idx in range(bubble_nodes.size()):
		var bubble_mesh: MeshInstance3D = bubble_nodes[bubble_idx]
		var bubble_mesh_instance = bubble_mesh.get_child(0)
		
		for child in bubble_mesh_instance.get_children():
			if child is OmniLight3D:
				child.queue_free()
