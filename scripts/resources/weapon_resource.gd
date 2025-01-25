class_name WeaponResource
extends Resource

enum WeaponType {
    MELEE,
    RANGED
}

@export var weapon_name: String = "Base Weapon"
@export var weapon_type: WeaponType = WeaponType.MELEE
@export var attack_speed: float = 1.0

# Melee specific properties
@export_group("Melee Properties")
@export var melee_damage: float = 10.0
@export var melee_range: float = 50.0

# Ranged specific properties
@export_group("Ranged Properties")
@export var projectile_speed: float = 300.0
@export var projectile_damage: float = 5.0
@export var max_range: float = 500.0

var bullet_scene = preload("res://scenes/bullet.tscn")

func perform_attack(weapon_node: Node2D):
    match weapon_type:
        WeaponType.MELEE:
            var space_state = weapon_node.get_world_2d().direct_space_state
            var query = PhysicsRayQueryParameters2D.create(
                weapon_node.global_position,
                weapon_node.global_position + Vector2.RIGHT.rotated(weapon_node.global_rotation) * melee_range,
                2  # Collision mask for enemies
            )
            var result = space_state.intersect_ray(query)
            
            if result and result.collider is Enemy:
                print("Hit enemy with melee attack!")
                result.collider.take_damage(melee_damage)
            
        WeaponType.RANGED:
            var bullet = bullet_scene.instantiate()
            weapon_node.get_tree().current_scene.add_child(bullet)
            bullet.init(
                weapon_node.global_position,
                Vector2.RIGHT.rotated(weapon_node.global_rotation),
                projectile_speed,
                projectile_damage,
                max_range
            ) 