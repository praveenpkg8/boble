class_name Enemy
extends CharacterBody2D

signal enemy_destroyed(enemy: Enemy)

@export var speed: float = 100.0
@export var damage: float = 3.0
@export var health: float = 100.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var is_fast_enemy: bool = true
@export var area_damage_radius: float = 0.0  # Set > 0 for area damage enemies
var attacking_force = 300
var current_target: Node2D = null
var attack_timer: float = 0.0
var is_destroyed: bool = false
var tower_manager: TowerManager
var base_health: float
var base_damage: float
var can_attack: bool = true
var knockback_strength: float = 100.0
var knockback_duration: float = 0.15
var current_knockback: Vector2 = Vector2.ZERO
@onready var animated_sprite = $AnimatedSprite2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	base_health = health
	base_damage = damage
	
	# Initialize with current values
	health = base_health
	damage = base_damage
	
	# Add self to enemies group
	add_to_group("enemies")
	print("Enemy added to enemies group")
	
	# Get the tower manager reference
	tower_manager = get_node("/root/GameWorld/TowerManager")
	if not tower_manager:
		push_error("TowerManager not found!")
	
	# Get combat manager reference
	var combat_manager = get_node("/root/GameWorld/CombatManager")
	if not combat_manager:
		push_error("CombatManager not found!")
	
	# Connect destroy signal to combat manager
	enemy_destroyed.connect(func(_enemy): combat_manager.enemy_killed())
	
	# Initialize enemy
	if is_fast_enemy:
		speed *= 1.5
		health *= 0.7
	else:
		speed *= 0.7
		health *= 1.5
		area_damage_radius = 100.0  # Slow enemies do area damage
	
	find_new_target()

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
		
	attack_timer = max(0, attack_timer - delta)
	if attack_timer <= 0:
		can_attack = true
	
	if !is_instance_valid(current_target):
		find_new_target()
		return
		
	if current_knockback != Vector2.ZERO:
		velocity = current_knockback
	else:
		if current_target:
			var direction = global_position.direction_to(current_target.global_position)
			velocity = direction * attacking_force
			
			# Only handle animations if AnimatedSprite2D exists
			if animated_sprite:
				# Determine animation direction based on movement
				var angle = direction.angle()
				# Convert angle to degrees and normalize it to 0-360 range
				var degrees = rad_to_deg(angle) + 180
				
				# Select animation based on 8-directional movement
				var animation_name = ""
				if degrees >= 337.5 or degrees < 22.5:
					animation_name = "left"
				elif degrees >= 22.5 and degrees < 67.5:
					animation_name = "left_up"
				elif degrees >= 67.5 and degrees < 112.5:
					animation_name = "up"
				elif degrees >= 112.5 and degrees < 157.5:
					animation_name = "right_up"
				elif degrees >= 157.5 and degrees < 202.5:
					animation_name = "right"
				elif degrees >= 202.5 and degrees < 247.5:
					animation_name = "right_down"
				elif degrees >= 247.5 and degrees < 292.5:
					animation_name = "down"
				elif degrees >= 292.5 and degrees < 337.5:
					animation_name = "left_down"
				
				# Play the corresponding animation if it's different
				if animated_sprite.animation != animation_name:
					animated_sprite.play(animation_name)
	
	move_and_slide()

func _on_body_entered(body: Node2D):
	print("Character body enetered")
	if body.has_method("take_damage") and can_attack:
		body.take_damage(damage)
		can_attack = false
		attack_timer = 0.0

func take_damage(amount: float, bullet_direction: Vector2 = Vector2.ZERO):
	print("Enemy taking damage: ", amount)
	health -= amount
	
	if bullet_direction != Vector2.ZERO:
		apply_knockback(bullet_direction)
	
	# Visual feedback
	modulate = Color(1, 0.5, 0.5, 1)  # Flash red
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	
	if health <= 0:
		print("Enemy destroyed by damage")
		destroy()

func _on_health_depleted():
	SoundManager.play_sound("enemy_death")
	print("Enemy destroyed!")
	enemy_destroyed.emit(self)  # Emit signal with self reference
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
	current_target = body
	print("player in enemy zone")
	pass # Replace with function body.

func _on_attack_area_body_entered(body: Node2D) -> void:
	print("player attack zone")
	pass # Replace with function body.

func _on_follow_through_area_body_exited(body: Node2D) -> void:
	current_target = null
	print("player out of enemy zone")
	pass # Replace with function body.

func _on_attack_area_body_exited(body: Node2D) -> void:
	print("player out of attack zone")
	pass # Replace with function body.

func set_target(new_target: Node2D):
	current_target = new_target

func find_new_target() -> Node2D:
	var player = get_node("../../Player")
	if !is_instance_valid(player):
		push_error("Player not found or invalid!")
		return null
		
	var towers = get_tree().get_nodes_in_group("towers")
	var valid_targets = towers.filter(func(t): return is_instance_valid(t))
	
	if valid_targets.is_empty():
		current_target = player
		return player
		
	var nearest_distance = INF
	var nearest_target = null
	
	for target in valid_targets:
		var distance = global_position.distance_to(target.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_target = target
	
	current_target = nearest_target if nearest_target else player
	return current_target

func attack():
	if !is_instance_valid(current_target):
		find_new_target()
		return
		
	if current_target.has_method("take_damage"):
		print("Enemy attacking tower: ", current_target.name)
		print("Damage amount: ", damage)
		current_target.take_damage(damage)
	attack_timer = attack_cooldown
	can_attack = false

func destroy():
	if !is_destroyed:
		is_destroyed = true
		SoundManager.play_sound("enemy_death")
		print("Enemy destroyed!")
		enemy_destroyed.emit(self)
		queue_free()

func _on_hitbox_area_entered(area: Area2D):
	if not can_attack:
		return
		
	var parent = area.get_parent()
	if parent is Tower and parent.has_method("take_damage"):
		if area_damage_radius > 0:
			apply_area_damage(parent)
		else:
			apply_single_damage(parent)
		
		can_attack = false
		attack_timer = attack_cooldown

func apply_single_damage(target_node: Node2D):
	if target_node is Tower and target_node.has_method("take_damage"):
		print("Enemy dealing damage to tower: ", target_node.name)
		print("Damage amount: ", damage)
		target_node.take_damage(damage)
		attack_timer = attack_cooldown
		can_attack = false

func apply_area_damage(center_target: Node2D):
	if not tower_manager:
		return
		
	var towers = tower_manager.towers
	for tower in towers:
		if tower != center_target and is_instance_valid(tower):
			var distance = global_position.distance_to(tower.global_position)
			if distance <= area_damage_radius:
				tower.take_damage(damage * (1 - distance/area_damage_radius))

func update_difficulty(multiplier: float) -> void:
	health = base_health * multiplier
	damage = base_damage * multiplier
	
	# Update visual feedback
	var polygon = $Polygon2D
	if polygon and multiplier > 1.0:
		var intensity = (multiplier - 1.0) * 2.0
		polygon.modulate = Color(1.0 + intensity, 1.0, 1.0, 1.0)

func apply_knockback(bullet_direction: Vector2):
	current_knockback = bullet_direction * knockback_strength
	
	# Create a tween for smooth knockback
	var tween = create_tween()
	tween.tween_property(self, "current_knockback", Vector2.ZERO, knockback_duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
