extends CharacterBody2D

@export var float_height: float = 2.0  # Desired height above ground
@export var spring_stiffness: float = 50.0  # Adjust stiffness (higher = faster correction)
@export var damping: float = 5.0  # Reduces bouncing
@export var move_speed: float = 300.0  # Movement speed
@export var rotation_speed: float = 10.0  # Speed at which player rotates to face direction
@export var mouse_movement_threshold: float = 10.0  # Minimum distance to move to mouse position

var weapon_system: WeaponSystem
var vfx_system: VFXSystem
var is_dead: bool = false
var viewport_rect: Rect2
var target_position: Vector2 = Vector2.ZERO
var is_moving_to_target: bool = false

@onready var raycast: RayCast2D = $RayCast2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D2

func _ready():
	print("Starting player initialization...")
	
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
	clamp_to_viewport()

func _input(event: InputEvent) -> void:
	# Handle right-click to cancel movement to target
	if event.is_action_pressed("right_click"):  # Make sure to define this input action
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
