extends Node

signal sound_played(sound_name: String)

# Sound effect paths
const SOUNDS = {
	"player_hit": "res://assets/sounds/player_hit.wav",
    "player_death": "res://assets/sounds/player_death.mp3",
	"enemy_hit": "res://assets/sounds/enemy_hit.wav",
	"weapon_swing": "res://assets/sounds/weapon_swing.wav",
	"shoot": "res://assets/sounds/shoot.wav",
	"enemy_death": "res://assets/sounds/enemy_death.wav",
    "general_world_sound": "res://assets/sounds/general_world_sound.mp3",
}

# Audio players pool for sound effects
var available_players: Array[AudioStreamPlayer] = []
var active_players: Array[AudioStreamPlayer] = []
const POOL_SIZE = 16

func _ready():
	# Initialize pool of audio players
	for i in POOL_SIZE:
		var player = AudioStreamPlayer.new()
		add_child(player)
		available_players.append(player)
		# Connect to finished signal to return player to pool
		player.finished.connect(_on_audio_finished.bind(player))

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if not SOUNDS.has(sound_name):
		push_error("Sound not found: " + sound_name)
		return
		
	# Clean up finished players that weren't properly released
	for player in active_players:
		if not player.playing:
			_on_audio_finished(player)
	
	var player = _get_available_player()
	if not player:
		# Try to forcibly free up a player
		if active_players.size() > 0:
			var oldest_player = active_players[0]
			oldest_player.stop()
			_on_audio_finished(oldest_player)
			player = _get_available_player()
	
	if player:
		var stream = load(SOUNDS[sound_name])
		if stream:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch_scale
			player.play()
			sound_played.emit(sound_name)
		else:
			push_error("Could not load sound: " + SOUNDS[sound_name])
			_on_audio_finished(player)
	else:
		push_error("No available audio players!")

func _get_available_player() -> AudioStreamPlayer:
	if available_players.size() > 0:
		var player = available_players.pop_front()
		active_players.append(player)
		return player
	return null

func _on_audio_finished(player: AudioStreamPlayer):
	# Return player to available pool
	if active_players.has(player):
		active_players.erase(player)
		available_players.append(player)