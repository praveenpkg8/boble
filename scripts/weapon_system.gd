class_name WeaponSystem
extends Node2D

var weapon: Weapon
var vfx_system: VFXSystem
var weapon_scene = preload("res://scenes/weapon.tscn")

func _ready():
	print("WeaponSystem _ready called")
	# Instance weapon from scene
	weapon = weapon_scene.instantiate()
	add_child(weapon)
	
	# Load weapon resource from .tres file
	var weapon_resource = preload("res://resources/bow.tres")
	if not weapon_resource:
		push_error("Failed to load weapon resource!")
		return
		
	weapon.weapon_resource = weapon_resource
	weapon.init()
	
	if not weapon.attack_performed.is_connected(_on_weapon_attack_performed):
		weapon.attack_performed.connect(_on_weapon_attack_performed)
	
	print("Weapon system initialized with: ", weapon_resource.weapon_name)

func init(_vfx_system: VFXSystem):
	print("WeaponSystem init called with vfx_system: ", _vfx_system)
	vfx_system = _vfx_system

func attack():
	if weapon:
		print("Attacking with weapon")
		weapon.attack()
	else:
		push_error("No weapon available!")

func _on_weapon_attack_performed():
	print("weapon attack performed")
	if vfx_system:
		vfx_system.start_shake()
