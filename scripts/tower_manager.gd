class_name TowerManager
extends Node

signal tower_destroyed(tower: Tower)
signal all_towers_destroyed

@export var tower_scene: PackedScene
@export var num_towers: int = 5
@export var min_distance_between_towers: float = 150.0  # Reduced from 200
@export var edge_margin: float = 50.0  # Reduced from 100

var towers: Array[Tower] = []
var viewport_rect: Rect2

func _ready():
	viewport_rect = get_viewport().get_visible_rect()
	spawn_initial_towers()

func spawn_initial_towers():
	var attempts = 100  # Maximum attempts for all towers
	var towers_placed = 0
	
	while towers_placed < num_towers and attempts > 0:
		var position = get_random_valid_position()
		if position != Vector2.ZERO:
			spawn_tower(position)
			towers_placed += 1
		attempts -= 1
	
	if towers_placed < num_towers:
		push_warning("Could only place " + str(towers_placed) + " out of " + str(num_towers) + " towers")

func get_random_valid_position() -> Vector2:
	var attempts = 50  # Maximum attempts per position
	
	while attempts > 0:
		var x = randf_range(edge_margin, viewport_rect.size.x - edge_margin)
		var y = randf_range(edge_margin, viewport_rect.size.y - edge_margin)
		var test_position = Vector2(x, y)
		
		var valid = true
		for tower in towers:
			if is_instance_valid(tower) and test_position.distance_to(tower.global_position) < min_distance_between_towers:
				valid = false
				break
		
		if valid:
			return test_position
			
		attempts -= 1
	
	return Vector2.ZERO

func spawn_tower(position: Vector2) -> Tower:
	var tower = tower_scene.instantiate() as Tower
	add_child(tower)
	tower.global_position = position
	towers.append(tower)
	tower.tower_destroyed.connect(_on_tower_destroyed)
	return tower

func _on_tower_destroyed(tower: Tower):
	towers.erase(tower)
	tower_destroyed.emit(tower)
	
	# Only emit all_towers_destroyed if ALL towers are actually gone
	if towers.is_empty():
		print("All towers destroyed - triggering game over")
		all_towers_destroyed.emit()
