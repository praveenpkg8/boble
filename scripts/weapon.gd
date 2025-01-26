@tool  # Add this if you want the class to be visible in the editor
class_name Weapon
extends Node2D

signal attack_performed  # New signal for attack events

@export var weapon_resource: WeaponResource

func _ready():
	if not weapon_resource:
		print("Warning: Weapon resource not assigned in _ready")

func init():
	if not weapon_resource:
		push_error("No weapon resource assigned during init!")
		return
	print("Weapon initialized with resource: ", weapon_resource.weapon_name)

func attack():
	attack_with_direction(Vector2.RIGHT)

func attack_with_direction(direction: Vector2):
	if not weapon_resource:
		push_error("Cannot attack - no weapon resource!")
		return
		
	match weapon_resource.weapon_type:
		WeaponResource.WeaponType.MELEE:
			SoundManager.play_sound("weapon_swing")
		WeaponResource.WeaponType.RANGED:
			SoundManager.play_sound("shoot")
	
	print("Performing attack with: ", weapon_resource.weapon_name)
	weapon_resource.perform_attack(self, direction)
	attack_performed.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
