class_name TowerManager
extends Node

signal all_towers_destroyed

@export var tower_scene: PackedScene
const NUM_TOWERS = 3
const TOWER_SPACING = 200.0

var towers: Array[Tower] = []

func _ready():
	if !tower_scene:
		push_error("Tower scene not set in TowerManager!")
		return
	
	var towers_placed = place_initial_towers()
	if !towers_placed:
		push_error("Failed to place initial towers!")
		return

func place_initial_towers() -> bool:
	var viewport_size = get_tree().root.get_viewport().get_visible_rect().size
	var start_x = viewport_size.x * 0.5 - (NUM_TOWERS - 1) * TOWER_SPACING * 0.5
	var y_position = viewport_size.y * 0.8
	var towers_placed = 0
	
	for i in NUM_TOWERS:
		var tower = tower_scene.instantiate() as Tower
		if tower:
			tower.position = Vector2(start_x + i * TOWER_SPACING, y_position)
			add_child(tower)
			towers.append(tower)
			tower.tree_exiting.connect(_on_tower_destroyed)
			towers_placed += 1
	
	return towers_placed > 0

func restore_towers_health():
	# Filter out any invalid towers first
	var valid_towers = towers.filter(func(tower): return is_instance_valid(tower))
	
	for tower in valid_towers:
		if tower and !tower.is_destroyed:
			# Use the proper way to set health through the tower's method
			tower.current_health = tower.max_health
			tower.update_health_indicator()
			print("Restored health for tower at position: ", tower.position)
	
	print("Restored health for ", valid_towers.size(), " towers")

func get_damaged_towers() -> Array[Tower]:
	return towers.filter(func(tower): 
		return is_instance_valid(tower) and tower.current_health < tower.max_health
	)

func has_damaged_towers() -> bool:
	return get_damaged_towers().size() > 0

func _on_tower_destroyed():
	# Add a delay to ensure proper cleanup
	await get_tree().create_timer(0.1).timeout
	
	# Filter out invalid towers and destroyed towers
	towers = towers.filter(func(tower): 
		return is_instance_valid(tower) and !tower.is_destroyed
	)
	
	print("Towers remaining: ", towers.size())
	
	# Only emit if all towers are actually destroyed
	if towers.is_empty():
		print("All towers destroyed - emitting signal")
		all_towers_destroyed.emit()
