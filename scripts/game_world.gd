extends Node2D

var enemy_spawner: EnemySpawner
var game_over: bool = false
@export var spawn_padding: float = 100.0  # Padding from viewport edges

@onready var tower_manager: TowerManager = $TowerManager
@onready var wave_manager: WaveManager = $WaveManager
@onready var combat_manager: CombatManager = $CombatManager
@onready var ui_manager: UIManager = $GameUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure we start in the correct state
	if get_tree():
		get_tree().paused = false
	game_over = false
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Initialize managers first
	if wave_manager:
		wave_manager.start_wave_system()
		wave_manager.wave_completed.connect(_on_wave_completed)
	
	# Initialize UI connections
	if wave_manager and ui_manager:
		# Disconnect existing connections first
		if wave_manager.wave_completed.is_connected(ui_manager._on_wave_completed):
			wave_manager.wave_completed.disconnect(ui_manager._on_wave_completed)
			
		if wave_manager.wave_started.is_connected(ui_manager._on_wave_started):
			wave_manager.wave_started.disconnect(ui_manager._on_wave_started)
			
		if wave_manager.enemy_count_updated.is_connected(ui_manager._on_enemy_count_updated):
			wave_manager.enemy_count_updated.disconnect(ui_manager._on_enemy_count_updated)
		
		# Connect signals
		wave_manager.wave_completed.connect(ui_manager._on_wave_completed)
		wave_manager.wave_started.connect(ui_manager._on_wave_started)
		wave_manager.enemy_count_updated.connect(ui_manager._on_enemy_count_updated)
	
	# Connect signals after initialization and tower placement
	if tower_manager:
		await get_tree().create_timer(0.2).timeout  # Give time for towers to initialize
		if tower_manager.towers.size() > 0:
			if tower_manager.all_towers_destroyed.is_connected(_on_all_towers_destroyed):
				tower_manager.all_towers_destroyed.disconnect(_on_all_towers_destroyed)
			tower_manager.all_towers_destroyed.connect(_on_all_towers_destroyed)
		else:
			push_error("No towers were placed!")
			return
	else:
		push_error("Tower Manager not found!")
		return
	
	# Connect sound manager
	if !SoundManager.sound_played.is_connected(_on_sound_played):
		SoundManager.sound_played.connect(_on_sound_played)

func _on_sound_played(sound_name: String):
	print("Sound played: ", sound_name)
	# You can add additional game logic here based on sounds

func _on_all_towers_destroyed():
	# Add validation
	if tower_manager and tower_manager.towers.is_empty():
		if ui_manager and !ui_manager.game_over:
			ui_manager._on_game_over()

func _on_wave_completed(wave_number: int) -> void:
	if tower_manager:
		tower_manager.restore_towers_health()
