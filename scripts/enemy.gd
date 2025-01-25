class_name Enemy
extends CharacterBody2D

signal enemy_destroyed(enemy: Enemy)

@export var speed: float = 100.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0  # Time between attacks
@export var is_fast_enemy: bool = true
@export var area_damage_radius: float = 0.0  # Set > 0 for area damage enemies
var attacking_force = 100
var target: Node2D
var can_attack: bool = true
var attack_timer: float = 0.0
var health: float = 50.0
var is_destroyed: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	if is_fast_enemy:
		speed *= 1.5
		damage *= 0.7
		health *= 0.8
	else:
		speed *= 0.7
		damage *= 1.5
		health *= 1.2

func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0

	if is_destroyed or not target or not is_instance_valid(target):
		find_new_target()
		return
		
	var direction = global_position.direction_to(target.global_position)
	velocity = direction * speed
	
	# Rotate to face movement direction
	rotation = lerp_angle(rotation, direction.angle(), 10.0 * delta)
	
	move_and_slide()
	
	# Check for collision with target
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider == target and can_attack:
			if area_damage_radius > 0:
				apply_area_damage(target)
			else:
				apply_single_damage(target)
			can_attack = false
			attack_timer = 0.0

func _on_body_entered(body: Node2D):
	print("Character body enetered")
	if body.has_method("take_damage") and can_attack:
		body.take_damage(damage)
		can_attack = false
		attack_timer = 0.0

func take_damage(amount: float):
	print("Enemy taking damage: ", amount)
	health -= amount
	
	# Optional: Add visual feedback
	modulate = Color(1, 0.5, 0.5, 1)  # Flash red
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	
	if health <= 0:
		print("Enemy destroyed by damage")
		destroy()

func _on_health_depleted():
	SoundManager.play_sound("enemy_death")
	print("Enemy destroyed!")
	queue_free() 

func move_towards_player(
	global_position: Vector2,
	player: CharacterBody2D,
	delta: float
):
	if player:
		# Calculate direction to player
		var direction = global_position.direction_to(player.global_position)
		
		# Set velocity instead of directly modifying position
		velocity = direction * attacking_force
		
		# Optional: rotate enemy to face player
		rotation = lerp_angle(rotation, direction.angle(), 0.1)
		
		# Use move_and_slide to handle movement with physics
		move_and_slide()
		
		# If you need the position, return it
		return global_position

func _on_follow_through_area_body_entered(body: Node2D) -> void:
	target = body
	print("player in enemy zone")
	pass # Replace with function body.

func _on_attack_area_body_entered(body: Node2D) -> void:
	print("player attack zone")
	pass # Replace with function body.

func _on_follow_through_area_body_exited(body: Node2D) -> void:
	target = null
	print("player out of enemy zone")
	pass # Replace with function body.

func _on_attack_area_body_exited(body: Node2D) -> void:
	print("player out of attack zone")
	pass # Replace with function body.

func set_target(new_target: Node2D):
	target = new_target

func find_new_target():
	var tower_manager = get_node("../TowerManager")
	if tower_manager and tower_manager.towers.size() > 0 and randf() < 0.67:
		target = tower_manager.towers[randi() % tower_manager.towers.size()]
	else:
		var player = get_node_or_null("../Player")
		if player:
			target = player
		else:
			push_error("Could not find player node")

func destroy():
	if not is_destroyed:
		is_destroyed = true
		enemy_destroyed.emit(self)
		queue_free()

func _on_hitbox_area_entered(area: Area2D):
	if not can_attack:
		return
		
	var parent = area.get_parent()
	if parent.has_method("take_damage"):
		if area_damage_radius > 0:
			apply_area_damage(parent)
		else:
			apply_single_damage(parent)
		
		can_attack = false
		attack_timer = 0.0

func apply_single_damage(target_node: Node2D):
	if target_node.has_method("take_damage"):
		print("Enemy dealing damage to: ", target_node.name)
		target_node.take_damage(damage)

func apply_area_damage(center_target: Node2D):
	# Apply damage to center target
	apply_single_damage(center_target)
	
	# Find and damage nearby towers
	var tower_manager = get_node("../TowerManager")
	if tower_manager:
		for tower in tower_manager.towers:
			if tower != center_target and tower.global_position.distance_to(center_target.global_position) <= area_damage_radius:
				apply_single_damage(tower)
