class_name CombatManager
extends Node

signal score_updated(score: int, multiplier: float)

const BASE_SCORE = 100
const MULTIPLIER_INCREMENT = 0.05
const MAX_MULTIPLIER = 1.35
const MULTIPLIER_RESET_TIME = 3.0
const SKIP_MULTIPLIER_INCREMENT = 0.1
const MAX_SKIP_MULTIPLIER = 0.5  # Maximum 50% bonus from skips

var current_score: int = 0
var score_multiplier: float = 1.0
var skip_multiplier: float = 0.0
var consecutive_skips: int = 0
var last_kill_time: float = 0.0
var weapon_level: int = 1
var max_weapon_level: int = 2

@onready var upgrade_manager: UpgradeManager = $"../UpgradeManager"

func _ready():
    if upgrade_manager:
        upgrade_manager.upgrade_skipped.connect(_on_upgrade_skipped)
        upgrade_manager.upgrade_selected.connect(_on_upgrade_selected)

func _process(delta: float):
    # Reset multiplier if too much time has passed since last kill
    if Time.get_ticks_msec() / 1000.0 - last_kill_time > MULTIPLIER_RESET_TIME:
        score_multiplier = 1.0 + skip_multiplier

func add_score(base_points: int):
    var points = base_points * score_multiplier
    current_score += points
    score_updated.emit(current_score, score_multiplier)

func enemy_killed():
    last_kill_time = Time.get_ticks_msec() / 1000.0
    score_multiplier = min(score_multiplier + MULTIPLIER_INCREMENT, MAX_MULTIPLIER + skip_multiplier)
    add_score(BASE_SCORE)

func upgrade_weapon() -> bool:
    if weapon_level < max_weapon_level:
        weapon_level += 1
        return true
    return false

func get_current_damage() -> float:
    return 10.0 * weapon_level  # Base damage * weapon level

func _on_upgrade_skipped():
    consecutive_skips += 1
    skip_multiplier = min(skip_multiplier + SKIP_MULTIPLIER_INCREMENT, MAX_SKIP_MULTIPLIER)
    score_multiplier = 1.0 + skip_multiplier

func _on_upgrade_selected(_upgrade: Dictionary):
    consecutive_skips = 0
    skip_multiplier = 0.0
    score_multiplier = 1.0 