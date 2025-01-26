extends Node2D

@onready var particles: GPUParticles2D = $CircleParticles

func trigger_effect(radius: float = 100.0):
	# Update the emission sphere radius
	var particle_material = particles.process_material as ParticleProcessMaterial
	particle_material.emission_sphere_radius = radius
	
	# Trigger the one-shot effect
	particles.restart()
	particles.emitting = true
	
	# Optional: automatically free the node after effect completes
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	queue_free() 
