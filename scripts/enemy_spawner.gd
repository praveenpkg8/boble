class_name EnemySpawner
extends Node2D

@export var spawn_interval: float = 3.0  # Time between spawns
@export var max_enemies: int = 5
@export var spawn_radius: float = 500.0  # Distance from spawner to spawn points

var enemy_scene: PackedScene
var spawn_timer: float = 0.0
var current_enemies: int = 0

func _ready():
	# Make sure this path matches your enemy scene location
	enemy_scene = preload("res://scenes/enemy.tscn")

func _process(delta: float) -> void:
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and current_enemies < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	if enemy_scene == null:
		print("Error: Enemy scene not loaded")
		return
		
	var enemy = enemy_scene.instantiate()
	if enemy == null:
		print("Error: Failed to instantiate enemy")
		return
		
	# Get viewport size
	var viewport_size = get_viewport_rect().size
	
	# Generate random position within viewport
	var spawn_position = Vector2(
		randf_range(0, viewport_size.x),
		randf_range(0, viewport_size.y)
	)
	
	add_child(enemy)
	enemy.global_position = spawn_position  # Use global_position instead of position
	current_enemies += 1
	
	print("Enemy spawned at: ", spawn_position)  # Debug print
	
	enemy.tree_exiting.connect(_on_enemy_destroyed)

func _on_enemy_destroyed():
	current_enemies -= 1 
