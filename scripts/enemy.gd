class_name Enemy
extends CharacterBody2D

@export var speed: float = 100.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0  # Time between attacks

@onready var health_component: HealthComponent = $HealthComponent
var can_attack: bool = true
var attack_timer: float = 0.0

func _ready():
	# Check if health component exists
	if not health_component:
		push_error("Health component not found!")
		return
		
	# Connect to health component signals
	if not health_component.health_depleted.is_connected(_on_health_depleted):
		health_component.health_depleted.connect(_on_health_depleted)
	
	print("Enemy initialized with health: ", health_component.current_health)

func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0

func _on_body_entered(body: Node2D):
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
