class_name Bullet
extends Area2D

var speed: float = 300.0
var damage: float = 10.0
var direction: Vector2 = Vector2.RIGHT
var max_distance: float = 500.0
var distance_traveled: float = 0.0

func init(initial_position: Vector2, initial_direction: Vector2, bullet_speed: float, bullet_damage: float, travel_distance: float):
	position = initial_position
	direction = initial_direction
	speed = bullet_speed
	damage = bullet_damage
	max_distance = travel_distance

func _physics_process(delta: float):
	var movement = direction * speed * delta
	position += movement
	distance_traveled += movement.length()
	
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D):
	if body is Enemy:
		body.take_damage(damage, direction)
		queue_free() 
