class_name Enemy
extends CharacterBody2D

@export var speed: float = 100.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0  # Time between attacks
var attacking_force = 300
var player: CharacterBody2D
@onready var enemy_behaviour_ai: Node = $EnemyBehaviourAI
var black_board: BlackBoard 
var behaviour_tree_result: BehaviourTreeResult
@onready var health_component: HealthComponent = $HealthComponent
var can_attack: bool = true
var attack_timer: float = 0.0

func _ready():
	black_board = BlackBoard.new()
	behaviour_tree_result = BehaviourTreeResult.new()
	black_board.data["is_player_near_by"] = false
	# Check if health component exists
	if not health_component:
		push_error("Health component not found!")
		return
		
	# Connect to health component signals
	if not health_component.health_depleted.is_connected(_on_health_depleted):
		health_component.health_depleted.connect(_on_health_depleted)
	
	print("Enemy initialized with health: ", health_component.current_health)

func _physics_process(delta: float) -> void:
	enemy_behaviour_ai.tick(black_board, behaviour_tree_result)
	if player:
		move_towards_player(global_position, player, delta)

func _on_body_entered(body: Node2D):
	print("Character body enetered")
	if body.has_method("take_damage") and can_attack:
		body.take_damage(damage)
		can_attack = false
		attack_timer = 0.0

func take_damage(amount: float):
	if health_component:
		health_component.take_damage(amount)
		SoundManager.play_sound("enemy_hit")

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
	player = body
	black_board.data["is_in_follow_thorugh_range"] = true
	print("player in enemy zone")
	pass # Replace with function body.


func _on_attack_area_body_entered(body: Node2D) -> void:
	black_board.data["is_player_near_by"] = true
	print("player attack zone")
	pass # Replace with function body.


func _on_follow_through_area_body_exited(body: Node2D) -> void:
	player = null
	black_board.data["is_attacking"] = false
	black_board.data["is_in_follow_thorugh_range"] = false
	
	
	pass # Replace with function body.


func _on_attack_area_body_exited(body: Node2D) -> void:
	black_board.data["is_player_near_by"] = false
	
	pass # Replace with function body.
