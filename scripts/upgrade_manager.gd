class_name UpgradeManager
extends Node

signal upgrade_available(options: Array)
signal upgrade_selected(upgrade: Dictionary)
signal upgrade_skipped

const BASE_UPGRADE_COST = 200
const UPGRADE_OPTIONS = 3
const UPGRADE_TIMER = 3.0

var available_upgrades = [
	{
		"id": "q_damage",
		"name": "Q Ability: Devastating Impact",
		"description": "Increases Q ability damage by 20%",
		"cost_multiplier": 1.0,
		"effect": func(player): player.apply_upgrade("q_damage")
	},
	{
		"id": "q_radius",
		"name": "Q Ability: Expanding Force",
		"description": "Increases Q ability radius by 15%",
		"cost_multiplier": 1.2,
		"effect": func(player): player.apply_upgrade("q_radius")
	},
	{
		"id": "e_duration",
		"name": "E Ability: Extended Surge",
		"description": "Increases damage boost duration by 20%",
		"cost_multiplier": 1.1,
		"effect": func(player): player.apply_upgrade("e_duration")
	},
	{
		"id": "e_power",
		"name": "E Ability: Amplified Power",
		"description": "Increases damage boost multiplier by 15%",
		"cost_multiplier": 1.3,
		"effect": func(player): player.apply_upgrade("e_power")
	}
]

var current_wave: int = 1
var upgrade_timer: float = 0.0
var is_upgrade_available: bool = false
var total_skips: int = 0

@onready var wave_manager: WaveManager = $"../WaveManager"
@onready var player = $"../Player"

func _ready():
	if !player:
		push_error("Player not found!")
		return
		
	if wave_manager:
		wave_manager.wave_completed.connect(_on_wave_completed)
	else:
		push_error("WaveManager not found!")

	upgrade_skipped.connect(_on_upgrade_skipped)

func get_upgrade_cost(base_cost: float) -> int:
	return int(base_cost * (1.0 + (current_wave - 1) * 0.2))

func generate_upgrade_options() -> Array:
	var options = []
	var available = available_upgrades.duplicate()
	
	for i in UPGRADE_OPTIONS:
		if available.size() > 0:
			var index = randi() % available.size()
			var upgrade = available[index]
			upgrade["cost"] = get_upgrade_cost(BASE_UPGRADE_COST * upgrade["cost_multiplier"])
			options.append(upgrade)
			available.remove_at(index)
	
	return options

func _on_wave_completed(_wave_number: int):
	current_wave = _wave_number + 1
	is_upgrade_available = true
	upgrade_timer = UPGRADE_TIMER
	var options = generate_upgrade_options()

	print("ugraded-available-1")
	upgrade_available.emit(options)

func _on_upgrade_skipped():
	total_skips += 1
	if wave_manager:
		wave_manager.update_difficulty(total_skips)

func _on_upgrade_selected(upgrade: Dictionary):
	if player:
		upgrade.effect.call(player) 

func show_upgrades() -> void:
	current_wave = wave_manager.current_wave + 1
	is_upgrade_available = true
	upgrade_timer = UPGRADE_TIMER
	var options = generate_upgrade_options()
	print("ugraded-available-2")
	upgrade_available.emit(options) 
