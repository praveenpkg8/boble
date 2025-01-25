class_name VFXSystem
extends Node2D

@export var shake_amount: float = 5.0
@export var shake_duration: float = 0.2

var target_node: Node2D  # The node to apply effects to (usually the player)
var initial_position: Vector2
var tween: Tween

func init(node: Node2D):
	target_node = node
	initial_position = target_node.position

func start_shake():
	print("start_shake")
	if tween:
		tween.kill()  # Stop any existing shake
	
	initial_position = target_node.position
	tween = create_tween()
	
	# Create multiple shake steps
	const SHAKE_STEPS = 10
	var step_duration = shake_duration / SHAKE_STEPS
	
	for i in SHAKE_STEPS:
		# Generate random offset
		var random_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		
		# Shake to random position
		tween.tween_property(
			target_node,
			"position",
			initial_position + random_offset,
			step_duration
		)
	
	# Final tween to return to original position
	tween.tween_property(
		target_node,
		"position",
		initial_position,
		step_duration
	) 