extends CharacterBody2D

@export var float_height: float = 2.0 # Desired height above ground
@export var spring_stiffness: float = 50.0 # Adjust stiffness (higher = faster correction)
@export var damping: float = 5.0 # Reduces bouncing
@export var move_speed: float = 300.0 # Movement speed
@export var rotation_speed: float = 10.0 # Speed at which player rotates to face direction
@export var mouse_movement_threshold: float = 10.0 # Minimum distance to move to mouse position
@export var base_damage: float = 30.0
@export var special_ability_1_cooldown: float = 5.0
@export var special_ability_2_cooldown: float = 8.0
@export var particle_effect_scene: PackedScene
@export var effect_radius: float = 100.0

var weapon_system: WeaponSystem
var vfx_system: VFXSystem
var is_dead: bool = false
var viewport_rect: Rect2
var target_position: Vector2 = Vector2.ZERO
var is_moving_to_target: bool = false
var resources: int = 0
var max_resources: int = 3
var is_repairing: bool = false
var current_repair_tower: Tower = null
var ability_1_timer: float = 0.0
var ability_2_timer: float = 0.0
var combat_manager: CombatManager
var damage_boost_active: bool = false
var damage_boost_duration: float = 5.0 # Duration in seconds
var damage_boost_multiplier: float = 2.0 # Doubles damage
var damage_boost_timer: float = 0.0
var weapon_level: int = 1

# Add new variables for ability scaling
var ability_q_damage_multiplier: float = 1.0
var ability_q_radius_multiplier: float = 1.0
var ability_e_duration_multiplier: float = 1.0
var ability_e_power_multiplier: float = 1.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Add particle effects for abilities
@onready var ability_q_particles: GPUParticles2D = $AbilityQParticles
@onready var ability_e_particles: GPUParticles2D = $AbilityEParticles
@onready var resource_label = $ResourceLabel

const WORLD_BOUNDS = {
	"left": 0,
	"right": 1280,
	"top": 0,
	"bottom": 720
}

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
	await get_tree().process_frame # Wait for node to be added to tree
	print("weapon_system: ", weapon_system)
	
	if weapon_system:
		weapon_system.init(vfx_system)
		print("Weapon system initialized successfully")
	else:
		push_error("Weapon system is null after initialization!")

	init_viewport_boundaries()
	target_position = position # Initialize target position to current position
	combat_manager = get_node("../CombatManager")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Handle movement
	var movement_vector = Vector2.ZERO
	movement_vector.x = Input.get_axis("left", "right")
	movement_vector.y = Input.get_axis("up", "down")
	movement_vector = movement_vector.normalized()
	
	# Apply movement
	if movement_vector != Vector2.ZERO:
		velocity = movement_vector * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
	
	move_and_slide()
	
	# Clamp position within world bounds
	global_position.x = clamp(global_position.x, WORLD_BOUNDS.left + 20, WORLD_BOUNDS.right - 20)
	global_position.y = clamp(global_position.y, WORLD_BOUNDS.top + 20, WORLD_BOUNDS.bottom - 20)
	
	# Get mouse position in global coordinates
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Smoothly rotate to face mouse
	var target_angle = direction.angle()
	# rotation = lerp_angle(rotation, target_angle, 10.0 * delta)
	
	# Handle shooting with correct direction
	if Input.is_action_pressed("click") and weapon_system:
		# Calculate direction from player to mouse
		var shoot_direction = (mouse_pos - global_position).normalized()
		print("shoot directon ", shoot_direction)
		weapon_system.attack(shoot_direction)  # Pass the mouse-based direction

func _input(event: InputEvent) -> void:
	# Handle right-click to cancel movement to target
	if event.is_action_pressed("click"): # Make sure to define this input action
		is_moving_to_target = false
		velocity = Vector2.ZERO
	
	if event.is_action_pressed("your_button_action"):  # Replace with your input action
		create_particle_effect()

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
	if not is_dead: # Ensure death logic runs only once
		is_dead = true
		print("Player died!")
		# Add visual effects for death
		modulate = Color(1, 0.3, 0.3, 0.7) # Red tint and fade
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
		use_ability_1()
	if Input.is_action_just_pressed("ability_2") and ability_2_timer <= 0:
		use_ability_2()
	
	# Handle damage boost duration
	if damage_boost_active:
		damage_boost_timer -= delta
		if damage_boost_timer <= 0:
			damage_boost_active = false
			modulate = Color(1, 1, 1, 1) # Reset color
			print("Damage boost ended")

func try_repair_nearest_tower():
	var nearest_tower = find_nearest_damaged_tower()
	if nearest_tower and nearest_tower.start_repair(50.0): # Repair amount
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
	var nearest_distance = 100.0 # Maximum repair distance
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

func use_ability_1():
	if ability_1_timer <= 0.0:
		var damage = base_damage * ability_q_damage_multiplier
		var radius = 150.0 * ability_q_radius_multiplier
		
		# Update particle effects
		if ability_q_particles:
			ability_q_particles.scale = Vector2.ONE * ability_q_radius_multiplier
			ability_q_particles.amount = int(20 * ability_q_damage_multiplier)
			ability_q_particles.emitting = true
		
		# Apply ability effect
		var enemies = get_tree().get_nodes_in_group("enemies")
		var enemies_hit = 0
		SoundManager.play_sound("ability_used")
		for enemy in enemies:
			if is_instance_valid(enemy):
				var distance = global_position.distance_to(enemy.global_position)
				if distance <= radius:
					# Calculate damage falloff based on distance
					var damage_multiplier = 10 - (distance / radius)
					var final_damage = damage * damage_multiplier
					print("Final damage: ", final_damage)
					print("Attempting to damage enemy at distance: ", distance)
					enemy.take_damage(final_damage)
					enemies_hit += 1
		
		print("Q ability hit ", enemies_hit, " enemies")
		ability_1_timer = special_ability_1_cooldown

func use_ability_2():
	if ability_2_timer <= 0.0:
		damage_boost_active = true
		damage_boost_timer = 0.0
		damage_boost_duration = 5.0 * ability_e_duration_multiplier
		damage_boost_multiplier = 2.0 * ability_e_power_multiplier
		
		# Update particle effects
		if ability_e_particles:
			ability_e_particles.scale = Vector2.ONE * ability_e_power_multiplier
			ability_e_particles.amount = int(30 * ability_e_duration_multiplier)
			ability_e_particles.emitting = true
		
		ability_2_timer = special_ability_2_cooldown

func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"q_damage":
			ability_q_damage_multiplier *= 1.2
			update_ability_visuals()
		"q_radius":
			ability_q_radius_multiplier *= 1.15
			update_ability_visuals()
		"e_duration":
			ability_e_duration_multiplier *= 1.2
			update_ability_visuals()
		"e_power":
			ability_e_power_multiplier *= 1.15
			update_ability_visuals()

func update_ability_visuals() -> void:
	# Update Q ability particles
	if ability_q_particles:
		var q_intensity = (ability_q_damage_multiplier + ability_q_radius_multiplier) / 2.0
		ability_q_particles.modulate = Color(1.0, 0.5 + q_intensity * 0.5, 0.0, 1.0)
	
	# Update E ability particles
	if ability_e_particles:
		var e_intensity = (ability_e_duration_multiplier + ability_e_power_multiplier) / 2.0
		ability_e_particles.modulate = Color(0.0, 0.5 + e_intensity * 0.5, 1.0, 1.0)

func get_current_damage() -> float:
	var current_damage = base_damage * weapon_level
	return current_damage * (damage_boost_multiplier if damage_boost_active else 1.0)

func update_resource_label():
	if resource_label:
		resource_label.text = str(resources) + "/" + str(max_resources)

func create_particle_effect() -> void:
	if particle_effect_scene:
		var effect = particle_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position
		effect.trigger_effect(effect_radius)
