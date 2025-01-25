class_name WaveManager
extends Node

signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

const WAVE_COUNTS = [20, 40, 50, 75, 100]
const WAVE_GAP_TIME = 5.0
const INITIAL_SPAWN_PERCENTAGE = 0.35
const CLUSTER_SPAWN_PERCENTAGE = 0.05

@export var enemy_scene_fast: PackedScene
@export var enemy_scene_slow: PackedScene

var current_wave: int = 0
var enemies_remaining: int = 0
var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0
var wave_gap_timer: float = 0.0
var is_wave_active: bool = false
var active_enemies: Array[Enemy] = []

@onready var tower_manager: TowerManager = $"../TowerManager"

func _ready():
    # Verify scenes are loaded
    if !enemy_scene_fast or !enemy_scene_slow:
        push_error("Enemy scenes not properly loaded in WaveManager")
        return
    start_next_wave()

func _process(delta: float):
    if not is_wave_active:
        wave_gap_timer += delta
        if wave_gap_timer >= WAVE_GAP_TIME:
            start_next_wave()
        return

    if enemies_to_spawn > 0:
        spawn_timer += delta
        if spawn_timer >= get_spawn_interval():
            spawn_enemies()
            spawn_timer = 0.0

func start_next_wave():
    if current_wave >= WAVE_COUNTS.size():
        all_waves_completed.emit()
        return

    current_wave += 1
    enemies_remaining = WAVE_COUNTS[current_wave - 1]
    enemies_to_spawn = enemies_remaining
    
    # Spawn initial percentage of enemies
    var initial_spawn_count = int(enemies_remaining * INITIAL_SPAWN_PERCENTAGE)
    spawn_initial_enemies(initial_spawn_count)
    
    enemies_to_spawn -= initial_spawn_count
    is_wave_active = true
    wave_gap_timer = 0.0
    
    wave_started.emit(current_wave, enemies_remaining)

func spawn_initial_enemies(count: int):
    for i in range(count):
        spawn_single_enemy()

func spawn_enemies():
    # Determine if this should be a cluster spawn
    if randf() < 0.5 and enemies_to_spawn >= 5:  # 50% chance for cluster
        var cluster_size = int(enemies_to_spawn * CLUSTER_SPAWN_PERCENTAGE)
        cluster_size = min(cluster_size, 5)  # Cap cluster size
        for i in range(cluster_size):
            spawn_single_enemy()
        enemies_to_spawn -= cluster_size
    else:
        spawn_single_enemy()
        enemies_to_spawn -= 1

func spawn_single_enemy():
    # Verify we have valid scenes before spawning
    if !enemy_scene_fast or !enemy_scene_slow:
        push_error("Cannot spawn enemy: scenes not loaded")
        return
        
    var enemy_scene = enemy_scene_fast if randf() < 0.6 else enemy_scene_slow
    var enemy = enemy_scene.instantiate() as Enemy
    if !enemy:
        push_error("Failed to instantiate enemy")
        return
        
    add_child(enemy)
    
    var spawn_position = get_random_spawn_position()
    enemy.global_position = spawn_position
    
    # Set target with null checks
    if randf() < 0.67 and tower_manager and tower_manager.towers.size() > 0:
        var target_tower = tower_manager.towers[randi() % tower_manager.towers.size()]
        enemy.set_target(target_tower)
    else:
        var player = get_node_or_null("../Player")
        if player:
            enemy.set_target(player)
        else:
            push_error("Could not find player node")
            enemy.queue_free()
            return
    
    active_enemies.append(enemy)
    enemy.enemy_destroyed.connect(_on_enemy_destroyed)

func get_random_spawn_position() -> Vector2:
    var viewport_rect = get_viewport().get_visible_rect()
    var margin = 100
    var side = randi() % 4  # 0: top, 1: right, 2: bottom, 3: left
    
    match side:
        0:  # Top
            return Vector2(randf_range(margin, viewport_rect.size.x - margin), -margin)
        1:  # Right
            return Vector2(viewport_rect.size.x + margin, randf_range(margin, viewport_rect.size.y - margin))
        2:  # Bottom
            return Vector2(randf_range(margin, viewport_rect.size.x - margin), viewport_rect.size.y + margin)
        _:  # Left
            return Vector2(-margin, randf_range(margin, viewport_rect.size.y - margin))

func get_spawn_interval() -> float:
    # Decrease spawn interval as wave progresses
    return max(0.5, 2.0 - (current_wave - 1) * 0.3)

func _on_enemy_destroyed(enemy: Enemy):
    active_enemies.erase(enemy)
    enemies_remaining -= 1
    
    if enemies_remaining <= 0 and enemies_to_spawn <= 0:
        wave_completed.emit(current_wave)
        is_wave_active = false 

func start_wave_system():
    # Reset wave variables
    current_wave = 0
    enemies_remaining = 0
    enemies_to_spawn = 0
    spawn_timer = 0.0
    wave_gap_timer = 0.0
    is_wave_active = false
    active_enemies.clear()
    
    # Start first wave
    start_next_wave() 