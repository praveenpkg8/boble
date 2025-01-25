class_name RangedWeaponResource
extends WeaponResource

@export var projectile_speed: float = 300.0
@export var projectile_damage: float = 5.0
@export var max_range: float = 500.0

func perform_attack(weapon_node: Node2D):
    # Ranged attack logic
    print("Performing ranged attack")
    # Implement projectile spawning logic 