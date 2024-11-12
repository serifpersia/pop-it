class_name SaveOptions extends Resource

@export var volume_values = {}
@export var use_defaults = {}

const SAVE_PATH : String = "user://options.tres"

func save() -> void:
	ResourceSaver.save(self, SAVE_PATH)

static func load_or_create() -> SaveOptions:
	var res: SaveOptions
	if FileAccess.file_exists(SAVE_PATH):
		res = load(SAVE_PATH) as SaveOptions
	else:
		res = SaveOptions.new()
	return res

func save_volume_for_bus(volume_name: String, volume_value: float) -> void:
	volume_values[volume_name] = volume_value
	save()

func save_defaults(defaultsName: String, defaultsValue: int) -> void:
	use_defaults[defaultsName] = defaultsValue
	save()

func get_defaults(defaultsName: String) -> int:
	if use_defaults.has(defaultsName):
		return use_defaults[defaultsName]
	else:
		return -1

func get_volume_value(volume_name: String) -> float:
	if volume_values.has(volume_name):
		return volume_values[volume_name]
	else:
		return 0
