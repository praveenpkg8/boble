class_name WaveManager
extends Node

signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

const WAVE_COUNTS = [20, 40, 50, 75, 100]
const WAVE_GAP_TIME = 5.0
const WAVE_TIME_LIMIT = 120.0  # 2 minutes per wave
const INITIAL_SPAWN_PERCENTAGE = 0.35
const CLUSTER_SPAWN_PERCENTAGE = 0.05

@export var enemy_scene_fast: PackedScene
@export var enemy_scene_slow: PackedScene

var current_wave: int = 0
var enemies_remaining: int = 0
var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0
var wave_gap_timer: float = 0.0
var wave_timer: float = 0.0
var is_wave_active: bool = false
var active_enemies: Array[Enemy] = []

@onready var tower_manager: TowerManager = $"../TowerManager"

func _ready():
	if !enemy_scene_fast or !enemy_scene_slow:
		push_error("Enemy scenes not properly loaded in WaveManager")
		return
	start_wave_system()

func start_wave_system():
	current_wave = 0
	start_next_wave()

func start_next_wave():
	if current_wave >= WAVE_COUNTS.size():
		all_waves_completed.emit()
		return
		
	current_wave += 1
	enemies_to_spawn = WAVE_COUNTS[current_wave - 1]
	enemies_remaining = enemies_to_spawn
	wave_timer = 0.0
	
	# Initial spawn
	var initial_spawn_count = int(enemies_to_spawn * INITIAL_SPAWN_PERCENTAGE)
	for i in initial_spawn_count:
		spawn_enemy(randf() > 0.3)
	enemies_to_spawn -= initial_spawn_count
	
	is_wave_active = true
	wave_gap_timer = 0.0
	spawn_timer = 0.0
	
	print("Wave ", current_wave, " started with ", enemies_remaining, " enemies")
	wave_started.emit(current_wave, enemies_remaining)

func _process(delta: float):
	if not is_wave_active:
		wave_gap_timer += delta
		if wave_gap_timer >= WAVE_GAP_TIME:
			start_next_wave()
		return

	# Update wave timer
	wave_timer += delta
	if wave_timer >= WAVE_TIME_LIMIT:
		print("Wave time limit reached!")
		complete_current_wave()
		return

	if enemies_to_spawn > 0:
		spawn_timer += delta
		if spawn_timer >= 0.5:  # Spawn every 0.5 seconds
			spawn_timer = 0.0
			spawn_enemy(randf() > 0.3)
			enemies_to_spawn -= 1

func complete_current_wave():
	print("Wave ", current_wave, " completed (Time or all enemies killed)")
	is_wave_active = false
	
	# Clear any remaining enemies
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.destroy()
	
	active_enemies.clear()
	enemies_remaining = 0
	enemies_to_spawn = 0
	
	wave_completed.emit(current_wave)

func _on_enemy_destroyed(enemy: Enemy):
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		enemies_remaining = max(0, enemies_remaining - 1)
		print("Enemy destroyed. Remaining: ", enemies_remaining)
		
		if enemies_remaining <= 0 and enemies_to_spawn <= 0:
			print("Wave ", current_wave, " completed")
			is_wave_active = false
			wave_completed.emit(current_wave)

func spawn_enemy(is_fast: bool = true):
	var enemy_scene = enemy_scene_fast if is_fast else enemy_scene_slow
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	
	# Set random spawn position
	var viewport_size = get_viewport().get_visible_rect().size
	var spawn_position = Vector2.ZERO
	var side = randi() % 4  # 0: top, 1: right, 2: bottom, 3: left
	
	match side:
		0:  # Top
			spawn_position = Vector2(randf_range(0, viewport_size.x), -50)
		1:  # Right
			spawn_position = Vector2(viewport_size.x + 50, randf_range(0, viewport_size.y))
		2:  # Bottom
			spawn_position = Vector2(randf_range(0, viewport_size.x), viewport_size.y + 50)
		3:  # Left
			spawn_position = Vector2(-50, randf_range(0, viewport_size.y))
	
	enemy.position = spawn_position
	active_enemies.append(enemy)
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	
	return enemy 
