class_name GameResource
extends Area2D

signal collected(resource: GameResource)

@export var decay_time: float = 3.0
@export var decay_speed_multiplier: float = 1.2

var decay_timer: float = 0.0
var initial_scale: Vector2
var is_collected: bool = false

func _ready():
	initial_scale = scale
	
func _process(delta: float):
	if is_collected:
		return
		
	decay_timer += delta * decay_speed_multiplier
	
	# Visual feedback for decay
	var remaining_time = 1.0 - (decay_timer / decay_time)
	scale = initial_scale * remaining_time
	modulate.a = remaining_time
	
	if decay_timer >= decay_time:
		queue_free()

func _on_body_entered(body):
	if not is_collected and body.is_in_group("player"):
		is_collected = true
		collected.emit(self)
		queue_free() 
