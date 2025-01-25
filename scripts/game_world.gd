extends Node2D

var enemy_spawner: EnemySpawner
@export var spawn_padding: float = 100.0  # Padding from viewport edges

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize enemy spawner
	enemy_spawner = EnemySpawner.new()
	add_child(enemy_spawner)
	
	
	# Set random position within viewport, accounting for padding
	enemy_spawner.position = Vector2.ZERO

	SoundManager.sound_played.connect(_on_sound_played)

func _on_sound_played(sound_name: String):
	print("Sound played: ", sound_name)
	# You can add additional game logic here based on sounds
