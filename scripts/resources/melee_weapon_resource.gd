class_name MeleeWeaponResource
extends WeaponResource

@export var attack_range: float = 50.0
@export var damage: float = 10.0

func perform_attack(weapon_node: Node2D):
    # Melee attack logic
    var attack_area = weapon_node.get_node("AttackArea")
    # Implement melee attack logic
    print("Performing melee attack") 