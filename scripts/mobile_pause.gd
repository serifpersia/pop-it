extends Control

@onready var animation_player = $AnimationPlayer
@onready var button: Button = $MarginContainer/Button

@onready var btn_click: AudioStreamPlayer = $btn_click
@onready var timer: Timer = $Timer

@onready var pause: Node2D = $"../Pause"

func _ready():
	animation_player.play("mobile_pause_button")
	await get_tree().create_timer(1).timeout


func _on_button_pressed() -> void:
	play_click()


func play_click():
	timer.start()
	btn_click.play()

func _on_timer_timeout():
	pause.get_child(0).show()
	get_tree().paused = true
	
