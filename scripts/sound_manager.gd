extends Node

signal sound_played(sound_name: String)

# Dictionary to store audio streams
var sounds: Dictionary = {}
var audio_players: Array[AudioStreamPlayer] = []
const NUM_PLAYERS = 8  # Number of audio players in the pool

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    _initialize_audio_players()
    _load_sounds()

func _initialize_audio_players():
    for i in NUM_PLAYERS:
        var player = AudioStreamPlayer.new()
        add_child(player)
        audio_players.append(player)

func _load_sounds():
    # Combat sounds
    sounds["enemy_hit"] = preload("res://assets/sounds/enemy_hit.wav")
    sounds["enemy_death"] = preload("res://assets/sounds/enemy_death.wav")
    sounds["tower_hit"] = preload("res://assets/sounds/tower_hit.wav")
    sounds["tower_destroyed"] = preload("res://assets/sounds/tower_destroyed.wav")
    sounds["player_hit"] = preload("res://assets/sounds/player_hit.wav")
    
    # UI and game state sounds
    sounds["game_over"] = preload("res://assets/sounds/game_over.wav")
    sounds["wave_start"] = preload("res://assets/sounds/wave_start.wav")
    sounds["wave_complete"] = preload("res://assets/sounds/wave_complete.wav")
    sounds["upgrade_available"] = preload("res://assets/sounds/upgrade_available.wav")
    sounds["upgrade_selected"] = preload("res://assets/sounds/upgrade_selected.wav")
    
    # Ability sounds
    sounds["repair_start"] = preload("res://assets/sounds/repair_start.wav")
    sounds["repair_complete"] = preload("res://assets/sounds/repair_complete.wav")
    sounds["ability_ready"] = preload("res://assets/sounds/ability_ready.wav")
    sounds["ability_used"] = preload("res://assets/sounds/water_bomb.mp3")
    
    # Resource sounds
    sounds["resource_pickup"] = preload("res://assets/sounds/resource_pickup.wav")
    sounds["resource_full"] = preload("res://assets/sounds/resource_full.wav")

func play_sound(sound_name: String) -> void:
    if !sounds.has(sound_name):
        push_warning("Sound not found: " + sound_name)
        return
        
    # Find an available audio player
    for player in audio_players:
        if !player.playing:
            player.stream = sounds[sound_name]
            player.play()
            sound_played.emit(sound_name)
            return
            
    push_warning("No available audio players to play sound: " + sound_name)

func stop_all_sounds() -> void:
    for player in audio_players:
        player.stop() 