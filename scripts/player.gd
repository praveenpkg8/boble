extends CharacterBody2D

@export var float_height: float = 2.0  # Desired height above ground
@export var spring_stiffness: float = 50.0  # Adjust stiffness (higher = faster correction)
@export var damping: float = 5.0  # Reduces bouncing
@export var move_speed: float = 300.0  # Movement speed
@export var rotation_speed: float = 10.0  # Speed at which player rotates to face direction
@export var mouse_movement_threshold: float = 10.0  # Minimum distance to move to mouse position
@export var base_damage: float = 10.0
@export var special_ability_1_cooldown: float = 5.0
@export var special_ability_2_cooldown: float = 8.0

var weapon_system: WeaponSystem
var vfx_system: VFXSystem
var is_dead: bool = false
var viewport_rect: Rect2
var target_position: Vector2 = Vector2.ZERO
var is_moving_to_target: bool = false
var resources: int = 1
var max_resources: int = 3
var is_repairing: bool = false
var current_repair_tower: Tower = null
var ability_1_timer: float = 0.0
var ability_2_timer: float = 0.0
var combat_manager: CombatManager

@onready var raycast: RayCast2D = $RayCast2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():	
	print("Starting player initialization...")
	add_to_group("player")
	
	# Initialize health component
	if not health_component:
		push_error("Health component not found!")
		# TODO: Push error not working need to fix it 
		
	init_health_component()
	
	# Initialize VFX system
	vfx_system = VFXSystem.new()
	add_child(vfx_system)
	vfx_system.init(self)
	print("VFX system initialized")

	# Initialize weapon system - make sure it's added to scene tree first
	print("Creating weapon system...")
	weapon_system = WeaponSystem.new()
	if not weapon_system:
		push_error("Failed to create weapon system!")
		return
		
	add_child(weapon_system)
	await get_tree().process_frame  # Wait for node to be added to tree
	print("weapon_system: ", weapon_system)
	
	if weapon_system:
		weapon_system.init(vfx_system)
		print("Weapon system initialized successfully")
	else:
		push_error("Weapon system is null after initialization!")

	init_viewport_boundaries()
	target_position = position  # Initialize target position to current position
	combat_manager = get_node("../CombatManager")

func _physics_process(delta: float) -> void:
	if is_dead:
		return  # Don't process movement if dead
	
	if Input.is_action_just_pressed("ui_accept") and weapon_system:
		print("Attack is being triggered")
		weapon_system.attack()
	
	# Handle mouse input
	if Input.is_action_just_pressed("click"):  # Make sure to define this input action
		target_position = get_viewport().get_mouse_position()
		target_position = target_position.clamp(viewport_rect.position, viewport_rect.end)
		is_moving_to_target = true
	
	# Calculate movement
	var movement_vector = Vector2.ZERO
	
	# Keyboard input
	var keyboard_input = Vector2.ZERO
	keyboard_input.x = Input.get_axis("ui_left", "ui_right")
	keyboard_input.y = Input.get_axis("ui_up", "ui_down")
	keyboard_input = keyboard_input.normalized()
	
	# If keyboard is being used, override mouse target
	if keyboard_input != Vector2.ZERO:
		is_moving_to_target = false
		movement_vector = keyboard_input
	# Otherwise, check if we're moving to a mouse target
	elif is_moving_to_target:
		var direction_to_target = position.direction_to(target_position)
		var distance_to_target = position.distance_to(target_position)
		
		# Only move if we're far enough from the target
		if distance_to_target > mouse_movement_threshold:
			movement_vector = direction_to_target
		else:
			is_moving_to_target = false
	
	# Apply movement
	if movement_vector != Vector2.ZERO:
		velocity = movement_vector * move_speed
		# Smoothly rotate to face movement direction
		rotation = lerp_angle(rotation, movement_vector.angle(), rotation_speed * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
	
	# Move and check boundaries
	move_and_slide()
	# clamp_to_viewport()

func _input(event: InputEvent) -> void:
	# Handle right-click to cancel movement to target
	if event.is_action_pressed("click"):  # Make sure to define this input action
		is_moving_to_target = false
		velocity = Vector2.ZERO

func clamp_to_viewport():
	position.x = clamp(position.x, viewport_rect.position.x, viewport_rect.end.x)
	position.y = clamp(position.y, viewport_rect.position.y, viewport_rect.end.y)

func init_health_component():
	if not health_component:
		print("Health component not found!")
		return
	
	health_component.health_depleted.connect(_on_health_depleted)
	health_component.health_changed.connect(_on_health_changed)
	print("Health component initialized")

func take_damage(amount: float):
	if health_component and not is_dead:
		health_component.take_damage(amount)
		SoundManager.play_sound("player_hit")

	if health_component.current_health <= 0:
		print("Player died!")
		queue_free()

func _on_health_depleted():
	if not is_dead:  # Ensure death logic runs only once
		is_dead = true
		print("Player died!")
		SoundManager.play_sound("player_death", -5.0)  # Slightly lower volume for death sound
		# Add visual effects for death
		modulate = Color(1, 0.3, 0.3, 0.7)  # Red tint and fade
		# Optionally disable collision
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		# You might want to trigger a game over screen or restart after a delay
		get_tree().create_timer(2.0).timeout.connect(_on_death_timer_finished)

func _on_death_timer_finished():
	# Handle what happens after death (restart level, show game over, etc.)
	print("Death sequence finished")
	# Example: Restart the current scene
	get_tree().reload_current_scene()

func _on_health_changed(current: float, maximum: float):
	print("Player health: ", current, "/", maximum)

func init_viewport_boundaries():
	viewport_rect = Rect2(Vector2.ZERO, get_viewport_rect().size)

func _process(delta: float):
	if Input.is_action_just_pressed("repair") and resources > 0:
		try_repair_nearest_tower()
	
	if is_repairing and (Input.is_action_just_pressed("move_left") or 
		Input.is_action_just_pressed("move_right") or 
		Input.is_action_just_pressed("move_up") or 
		Input.is_action_just_pressed("move_down")):
		interrupt_repair()
	
	# Update ability cooldowns
	if ability_1_timer > 0:
		ability_1_timer -= delta
	if ability_2_timer > 0:
		ability_2_timer -= delta
	
	# Check for ability inputs
	if Input.is_action_just_pressed("ability_1") and ability_1_timer <= 0:
		use_special_ability_1()
	if Input.is_action_just_pressed("ability_2") and ability_2_timer <= 0:
		use_special_ability_2()

func try_repair_nearest_tower():
	var nearest_tower = find_nearest_damaged_tower()
	if nearest_tower and nearest_tower.start_repair(50.0):  # Repair amount
		resources -= 1
		is_repairing = true
		current_repair_tower = nearest_tower
		current_repair_tower.repair_completed.connect(_on_repair_completed)

func interrupt_repair():
	if current_repair_tower:
		current_repair_tower.interrupt_repair()
		is_repairing = false
		current_repair_tower = null

func find_nearest_damaged_tower() -> Tower:
	var towers = get_tree().get_nodes_in_group("towers")
	var nearest_distance = 100.0  # Maximum repair distance
	var nearest_tower = null
	
	for tower in towers:
		if tower.current_health < tower.max_health:
			var distance = global_position.distance_to(tower.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_tower = tower
	
	return nearest_tower

func _on_repair_completed():
	is_repairing = false
	current_repair_tower = null

func collect_resource(resource: GameResource):
	if resources < max_resources:
		resources += 1

func use_special_ability_1():
	print("Special Ability 1 (Q) activated")
	# Area damage to nearby enemies
	var radius = 150.0
	var base_damage = 50.0  # Set a base damage value
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var enemies_hit = 0
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= radius:
				# Calculate damage falloff based on distance
				var damage_multiplier = 1.0 - (distance / radius)
				var final_damage = base_damage * damage_multiplier
				enemy.take_damage(final_damage)
				enemies_hit += 1
				print("Enemy hit with Q ability - Damage: ", final_damage)
	
	print("Q ability hit ", enemies_hit, " enemies")
	
	# Start cooldown
	ability_1_timer = special_ability_1_cooldown
	
	# Visual feedback
	spawn_ability_1_effect(radius)

func use_special_ability_2():
	# Temporary damage boost
	var boost_duration = 5.0
	var damage_multiplier = 2.0
	
	combat_manager.weapon_level *= damage_multiplier
	ability_2_timer = special_ability_2_cooldown
	
	# Create timer for reverting damage
	var timer = get_tree().create_timer(boost_duration)
	timer.timeout.connect(func(): combat_manager.weapon_level = int(combat_manager.weapon_level / damage_multiplier))
	
	spawn_ability_2_effect()

func spawn_ability_1_effect(radius: float):
	var effect = Node2D.new()
	add_child(effect)
	
	# Create the visual circle
	effect.draw.connect(func():
		var center = Vector2.ZERO
		var points = PackedVector2Array()
		var num_points = 32
		for i in range(num_points + 1):
			var angle = i * 2 * PI / num_points
			points.push_back(center + Vector2(cos(angle), sin(angle)) * radius)
		effect.draw_colored_polygon(points, Color(1, 0, 0, 0.3))
	)
	
	# Create timer as child of effect
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	effect.add_child(timer)
	timer.timeout.connect(func(): effect.queue_free())
	timer.start()

func spawn_ability_2_effect():
	var effect = Node2D.new()
	add_child(effect)
	
	# Create the visual circle
	effect.draw.connect(func():
		var center = Vector2.ZERO
		var points = PackedVector2Array()
		var num_points = 16
		for i in range(num_points + 1):
			var angle = i * 2 * PI / num_points
			points.push_back(center + Vector2(cos(angle), sin(angle)) * 20)
		effect.draw_colored_polygon(points, Color(0, 1, 0, 0.5))
	)
	
	# Create timer as child of effect
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	effect.add_child(timer)
	timer.timeout.connect(func(): effect.queue_free())
	timer.start()
