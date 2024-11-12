extends AudioStreamPlayer 

const BGM_JAZZY_MAIN_MENU = preload("res://sounds/main_menu.mp3")
const BGM_ARCADE = preload("res://sounds/Rush Hour Arcade.mp3")
const BGM_ARCADE_PLUS = preload("res://sounds/arcade_plus.mp3")
const BGM_MEMORY = preload("res://sounds/memory.mp3")
const BGM_FIDGET = preload("res://sounds/fidget.mp3")

func _play_music(music: AudioStream, volume = 0.0):
	if stream == music:
		return
	stream = music
	volume_db = volume
	play()
	
func play_bgm_menu():
	_play_music(BGM_JAZZY_MAIN_MENU)

func play_bgm_arcade():
	_play_music(BGM_ARCADE)

func play_bgm_arcade_plus():
	_play_music(BGM_ARCADE_PLUS)
	
func play_bgm_memory():
	_play_music(BGM_MEMORY)

func play_bgm_fidget():
	_play_music(BGM_FIDGET)
