class_name Tower
extends StaticBody2D

signal tower_destroyed(tower: Tower)
signal health_changed(current: float, max: float)
signal repair_completed
signal repair_started
signal repair_interrupted

@export var max_health: float = 100.0
@export var min_distance_between_towers: float = 150.0

var current_health: float
var is_being_repaired: bool = false
var is_destroyed: bool = false

@onready var health_indicator = $HealthIndicator
@onready var repair_indicator = $RepairIndicator
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Polygon2D = $Polygon2D

func _ready():
	current_health = max_health
	update_health_indicator()
	repair_indicator.visible = false
	is_destroyed = false
	add_to_group("towers")

@export var repair_time: float = 4.0
var repair_progress: float = 0.0
var repair_amount: float = 0.0

func _process(delta: float):
	if is_being_repaired:
		repair_progress += delta / repair_time
		update_repair_indicator()
		
		if repair_progress >= 1.0:
			complete_repair()

func start_repair(amount: float):
	if current_health >= max_health:
		return false
		
	is_being_repaired = true
	repair_progress = 0.0
	repair_amount = amount
	repair_indicator.visible = true
	repair_started.emit()
	return true

func interrupt_repair():
	if is_being_repaired:
		is_being_repaired = false
		repair_indicator.visible = false
		repair_interrupted.emit()

func complete_repair():
	current_health = min(max_health, current_health + repair_amount)
	is_being_repaired = false
	repair_progress = 0.0
	repair_indicator.visible = false
	update_health_indicator()
	repair_completed.emit()

func update_repair_indicator():
	# Update circular progress indicator
	var progress_node = repair_indicator.get_node("Progress")
	progress_node.material.set_shader_parameter("progress", repair_progress)

func take_damage(amount: float):
	print("Tower Take Damage")
	if is_being_repaired:
		interrupt_repair()
		
	current_health = max(0, current_health - amount)
	print("Tower current health: ", current_health)
	update_health_indicator()
	
	if current_health <= 0 and !is_destroyed:
		destroy()

func update_health_indicator():
	var health_percent = current_health / max_health
	health_indicator.modulate = Color(
		1.0 - health_percent,  # More red as health decreases
		health_percent,        # More green as health increases
		0,
		1
	)
	health_changed.emit(current_health, max_health)

func destroy():
	if not is_destroyed:
		print("Tower destroyed!")
		is_destroyed = true
		remove_from_group("towers")
		tower_destroyed.emit(self)
		
		# Make tower visually destroyed
		modulate.a = 0.5
		collision_shape.set_deferred("disabled", true)
		
		# Let tower manager handle the cleanup
		var tower_manager = get_node("/root/GameWorld/TowerManager")
		if tower_manager:
			tower_manager._on_tower_destroyed()
		
		# Add a small delay before queue_free to allow effects to play
		await get_tree().create_timer(0.5).timeout
		queue_free()

static func is_valid_tower_position(position: Vector2, existing_towers: Array[Tower]) -> bool:
	for tower in existing_towers:
		if position.distance_to(tower.global_position) < tower.min_distance_between_towers:
			return false
	return true 
