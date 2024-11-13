extends Node

var last_game_mode_selected = -1

func _ready():
	if Engine.has_singleton("DiscordRPC"):
		var discord_rpc = Engine.get_singleton("DiscordRPC")
		discord_rpc.app_id = 1306284496894824502
		discord_rpc.state = "Popping bubbles"
		discord_rpc.large_image = "popit-large"
		discord_rpc.start_timestamp = int(Time.get_unix_time_from_system())
		update_discord_status()
	else:
		print("Discord RPC plugin not installed. Skipping Discord integration.")

func _process(_delta):
	if Global.game_mode_selected != last_game_mode_selected:
		update_discord_status()

func update_discord_status():
	if Engine.has_singleton("DiscordRPC"):
		var discord_rpc = Engine.get_singleton("DiscordRPC")
		
		match Global.game_mode_selected:
			0:
				discord_rpc.details = "Arcade"
			1:
				discord_rpc.details = "Arcade+"
			2:
				discord_rpc.details = "Memory"
			3:
				discord_rpc.details = "Fidget"
			_:
				discord_rpc.details = "Idle"

		discord_rpc.refresh()
		last_game_mode_selected = Global.game_mode_selected
