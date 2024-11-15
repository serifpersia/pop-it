extends Node3D

const INPUT_KEYS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
const MAX_SOUND_HISTORY = 2
const START_BUBBLES = 3
const MAX_BUBBLES = 8

var game_over := false
var progress_tween: Tween

@onready var time_bar: ProgressBar = $"../CanvasLayer/Time_Bar/Time_Bar"
@onready var finish_level_scene: Control = $"../FinishLevelScene"
@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
@onready var high_score: Label = $"../FinishLevelScene/MarginContainer/HBoxContainer/VBoxContainer/Score"
@onready var total_time: Label = $"../FinishLevelScene/MarginContainer/HBoxContainer/VBoxContainer/Time"

var base_decrease_time := 15.0
var difficulty_multiplier := 1.0

var key_states := {}
var active_bubbles: PackedInt32Array = []
var previous_bubbles: PackedInt32Array = []
var current_level := 1
var score := 0
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

@onready var c_mult_10: ColorRect = $"../CanvasLayer/Score_Display/c_mult_10"
@onready var c_mult_1: ColorRect = $"../CanvasLayer/Score_Display/c_mult_1"

var start_time
var remaining_bubbles: PackedInt32Array = []

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	
	randomize()
	current_hue = randf()
	start_time = Time.get_ticks_msec()
	_cache_bubble_nodes()
	generate_level_config()
	preload_pop_sounds()
	reset_key_states()
	setup_progress_bar()
	start_new_round()

func setup_progress_bar() -> void:
	time_bar.min_value = 0
	time_bar.max_value = 100
	time_bar.value = 100
	_start_decrease_tween()
	
func _start_decrease_tween() -> void:
	if progress_tween:
		progress_tween.kill()
	
	var decrease_time = base_decrease_time / pow(difficulty_multiplier, 0.7)
	progress_tween = create_tween()
	progress_tween.tween_property(time_bar, "value", 0, decrease_time)
	progress_tween.set_trans(Tween.TRANS_LINEAR)

func _process(_delta: float) -> void:
	if time_bar.value <= 0 and not game_over:
		game_over = true
		handle_game_over()

func handle_game_over() -> void:
	var elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0
	var minutes = int(elapsed_time / 60.0)
	var seconds = int(elapsed_time) % 60

	var formatted_time = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
	
	await get_tree().create_timer(1.0).timeout
	hide()
	canvas_layer.hide()
	finish_level_scene.show()
	high_score.text = "High Score: " + str(score)
	total_time.text = "Total Time: " + formatted_time
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
	
func _update_combo_multiplier_display(get_combo: int) -> void:
	var combo_m_str = str(get_combo).pad_zeros(2)
	
	var tens = int(combo_m_str[0])
	var units = int(combo_m_str[1])

	c_mult_10.material.set_shader_parameter("Number", tens)
	c_mult_1.material.set_shader_parameter("Number", units)
	
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

func preload_pop_sounds() -> void:
	for i in range(1, 15):
		var sound_path := "res://sounds/pop-it_Insert %d.wav" % i
		sound_pool.append(load(sound_path))

func generate_level_config() -> void:
	for level in range(1, 101):
		var bubbles := START_BUBBLES + roundi(((MAX_BUBBLES - START_BUBBLES) * float(level - 1)) / 99.0)
		bubbles = clampi(bubbles, START_BUBBLES, MAX_BUBBLES)
		var spacing := maxi(roundi(1.5 - float(level) / 10.0), 1)
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
	remove_existing_lights()

	active_bubbles = get_valid_bubble_positions()
	
	remaining_bubbles = []
	for i in range(10):
		if i not in active_bubbles:
			remaining_bubbles.append(i)

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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_touch(event.position)
		
func _unhandled_key_input(event: InputEvent) -> void:
	if game_over:
		return
		
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
	if game_over or is_transitioning or index >= bubble_nodes.size():
		return

	key_states[INPUT_KEYS[index]] = true
	var cap_mesh: MeshInstance3D = bubble_nodes[index].get_child(0)

	if not (index in popped_bubbles):
		if index in active_bubbles:
			var base_score = 100
			var multiplier = get_multiplier()
			var score_increase = base_score * multiplier
			score += score_increase
			var time_bonus = 2.0 + (combo * 0.1)
			time_bar.value = min(time_bar.value + time_bonus, time_bar.max_value)
			_update_score_display(score)
			_update_combo(true)
			_update_combo_multiplier_display(multiplier)

			var new_active_bubbles = []
			for i in active_bubbles:
				if i != index:
					new_active_bubbles.append(i)
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

			Input.vibrate_handheld(25, 0.45)

			if remaining_bubbles.size() > 0:
				var new_bubble = remaining_bubbles[randi() % remaining_bubbles.size()]
				var new_remaining_bubbles = []
				for i in remaining_bubbles:
					if i != new_bubble:
						new_remaining_bubbles.append(i)
				remaining_bubbles = new_remaining_bubbles

				active_bubbles.append(new_bubble)
				light_up_bubble(new_bubble)

			if active_bubbles.is_empty() and remaining_bubbles.is_empty():
				await get_tree().create_timer(0.2).timeout
				advance_level()
		elif not (index in previous_bubbles):
			_update_combo(false)
			_update_combo_multiplier_display(1)

func _handle_key_release(index: int) -> void:
	key_states[INPUT_KEYS[index]] = false

func advance_level() -> void:
	if is_transitioning or game_over:
		return
	
	is_transitioning = true
	
	difficulty_multiplier += 0.03
	
	var time_bonus = time_bar.value * 0.3
	time_bar.value = min(time_bar.value + time_bonus, time_bar.max_value)
	
	_start_decrease_tween()
	
	for tween in active_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	active_tweens.clear()
	
	play_level_completion_sound()
	current_level += 1
	_update_level_display(current_level)
	
	var reset_tween = create_tween()
	reset_tween.set_parallel(true)
	
	remove_existing_lights()
	
	for bubble_idx in range(bubble_nodes.size()):
		var cap_mesh: MeshInstance3D = bubble_nodes[bubble_idx].get_child(0)
		if cap_mesh:
			reset_tween.tween_property(cap_mesh, "blend_shapes/popped", 0.0, 0.1)\
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
		audio.set_bus("SFX")
		add_child(audio)
		audio.position = Vector3(-0.3, 0.5, 0)
		audio.play()
		audio.finished.connect(func(): audio.queue_free())

var active_combo_tween: Tween = null

func get_multiplier() -> int:
	if combo > 120:
		combo_label.set_modulate(Color(1, 1, 1))
		return 12
	elif combo > 80:
		combo_label.set_modulate(Color(1.0, 0.6, 0.0))
		return 8
	elif combo > 50:
		combo_label.set_modulate(Color(1.0, 1.0, 0.0))
		return 6
	elif combo > 30:
		combo_label.set_modulate(Color(0.0, 1.0, 0.4))
		return 4
	elif combo > 10:
		combo_label.set_modulate(Color(0.3, 0.6, 1))
		return 2
	else:
		combo_label.set_modulate(Color(0.7, 0.7, 0.7))
		return 1

func _update_combo(increase: bool) -> void:
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
	
	var mesh_light = mesh.get_child(1)
	
	if mesh_light:
		tween.tween_property(mesh_light, "light_energy", 2.15, 0.15)\
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


func _handle_touch(touch_position: Vector2) -> void:
	var camera = get_viewport().get_camera_3d()
	if camera:
		var from = camera.project_ray_origin(touch_position)
		var to = from + camera.project_ray_normal(touch_position) * 1000.0
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result:
			var collider = result.collider
			
			if collider is StaticBody3D:
				var parent_node = collider.get_parent()
				
				if parent_node is MeshInstance3D:
					var grandparent_node = parent_node.get_parent()
					
					var grandparent_name = grandparent_node.name
					var index = int(String(grandparent_name))
					
					if index > 0:
						_handle_key_press(index - 1)
