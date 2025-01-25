extends Node2D

var enemy_spawner: EnemySpawner
@export var spawn_padding: float = 100.0  # Padding from viewport edges

@onready var tower_manager: TowerManager = $TowerManager
@onready var wave_manager: WaveManager = $WaveManager
@onready var combat_manager: CombatManager = $CombatManager
@onready var ui_manager: UIManager = $GameUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Reset game state
	get_tree().paused = false
	
	# Initialize enemy spawner
	#enemy_spawner = EnemySpawner.new()
	#add_child(enemy_spawner)
	
	
	# Set random position within viewport, accounting for padding
	#enemy_spawner.position = Vector2.ZERO

	SoundManager.sound_played.connect(_on_sound_played)

	# Connect signals
	tower_manager.all_towers_destroyed.connect(_on_all_towers_destroyed)
	
	# Initialize managers
	if wave_manager:
		wave_manager.start_wave_system()

func _on_sound_played(sound_name: String):
	print("Sound played: ", sound_name)
	# You can add additional game logic here based on sounds

func _on_all_towers_destroyed():
	if ui_manager:
		ui_manager._on_game_over()
