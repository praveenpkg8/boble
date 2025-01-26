class_name WaveManager
extends Node

signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int)
signal all_waves_completed
signal enemy_count_updated(count: int)
signal wave_cleanup_completed

const WAVE_COUNTS = [20, 40, 50, 75, 100]
const WAVE_GAP_TIME = 5.0
const INITIAL_SPAWN_PERCENTAGE = 0.35
const SKIP_HEALTH_INCREASE = 0.05
const SKIP_DAMAGE_INCREASE = 0.03

const WORLD_BOUNDS = {
	"left": 0,
	"right": 1280,
	"top": 0,
	"bottom": 720
}

@export var enemy_scene_fast: PackedScene
@export var enemy_scene_slow: PackedScene

var current_wave: int = 0
var enemies_remaining: int = 0
var enemies_to_spawn: int = 0
var is_wave_active: bool = false
var active_enemies: Array[Enemy] = []
var difficulty_multiplier: float = 1.0
var is_cleaning_up: bool = false

@onready var tower_manager: TowerManager = get_node_or_null("../TowerManager")
@onready var upgrade_manager: UpgradeManager = get_node_or_null("../UpgradeManager")

func _ready():
	if !enemy_scene_fast or !enemy_scene_slow:
		push_error("Enemy scenes not properly loaded in WaveManager")
		return
		
	if !upgrade_manager:
		push_error("UpgradeManager not found!")
		return
		
	start_wave_system()

func start_wave_system():
	current_wave = 0
	start_next_wave()

func start_next_wave():
	current_wave += 1
	if current_wave <= WAVE_COUNTS.size():
		enemies_remaining = WAVE_COUNTS[current_wave - 1]
		enemies_to_spawn = enemies_remaining
		wave_started.emit(current_wave, enemies_remaining)
		
		# Spawn initial wave of enemies
		var initial_spawn = ceil(enemies_to_spawn * INITIAL_SPAWN_PERCENTAGE)
		for i in range(initial_spawn):
			spawn_wave_enemies()
			enemies_to_spawn -= 1

func cleanup():
	is_cleaning_up = true
	# Clear all active enemies
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	enemies_remaining = 0
	enemies_to_spawn = 0
	is_wave_active = false
	wave_cleanup_completed.emit()
	is_cleaning_up = false

func _on_enemy_destroyed(enemy: Enemy):
	enemies_remaining = max(0, enemies_remaining - 1)
	enemy_count_updated.emit(enemies_remaining)
	print("Enemy destroyed. Remaining: ", enemies_remaining)
	
	# Check if wave is complete
	if enemies_remaining == 0 and enemies_to_spawn == 0:
		print("Wave completed!")
		wave_completed.emit(current_wave)
		
		# Check if this was the last wave
		if current_wave >= WAVE_COUNTS.size():
			print("All waves completed!")
			all_waves_completed.emit()
		else:
			# Start next wave after delay
			await get_tree().create_timer(WAVE_GAP_TIME).timeout
			start_next_wave()

func spawn_wave_enemies():
	if !enemy_scene_fast or !enemy_scene_slow:
		push_error("Enemy scenes not properly loaded in WaveManager")
		return
		
	var spawn_position = get_random_spawn_position()
	if spawn_position == Vector2.ZERO:
		push_warning("Could not find valid spawn position")
		return
		
	var enemy_scene = enemy_scene_fast if randf() > 0.3 else enemy_scene_slow
	var enemy = enemy_scene.instantiate()
	if !enemy:
		push_error("Failed to instantiate enemy")
		return
		
	enemy.global_position = spawn_position
	
	# Apply difficulty scaling
	enemy.health *= difficulty_multiplier
	enemy.damage *= difficulty_multiplier
	
	# Add visual indicator for increased difficulty
	if difficulty_multiplier > 1.0:
		var glow = enemy.get_node_or_null("Polygon2D")
		if glow:
			var intensity = (difficulty_multiplier - 1.0) * 2.0
			glow.modulate = Color(1.0 + intensity, 1.0, 1.0, 1.0)
	
	add_child(enemy)
	active_enemies.append(enemy)
	
	# Connect the enemy's destroyed signal
	enemy.enemy_destroyed.connect(_on_enemy_destroyed.bind(enemy))
	enemy.tree_exiting.connect(func(): _on_enemy_destroyed(enemy)) # Backup connection
	
	print("Enemy spawned. Remaining enemies: ", enemies_remaining) # Debug print

func get_random_spawn_position() -> Vector2:
	var margin = 50  # Distance outside the visible area to spawn
	var side = randi() % 4  # 0: top, 1: right, 2: bottom, 3: left
	
	match side:
		0:  # Top
			return Vector2(
				randf_range(WORLD_BOUNDS.left + margin, WORLD_BOUNDS.right - margin),
				WORLD_BOUNDS.top - margin
			)
		1:  # Right
			return Vector2(
				WORLD_BOUNDS.right + margin,
				randf_range(WORLD_BOUNDS.top + margin, WORLD_BOUNDS.bottom - margin)
			)
		2:  # Bottom
			return Vector2(
				randf_range(WORLD_BOUNDS.left + margin, WORLD_BOUNDS.right - margin),
				WORLD_BOUNDS.bottom + margin
			)
		3:  # Left
			return Vector2(
				WORLD_BOUNDS.left - margin,
				randf_range(WORLD_BOUNDS.top + margin, WORLD_BOUNDS.bottom - margin)
			)
	
	return Vector2.ZERO

func update_difficulty(skips: int) -> void:
	difficulty_multiplier = 1.0 + (skips * SKIP_HEALTH_INCREASE)
