class_name CombatManager
extends Node

signal score_updated(score: int, multiplier: float)

const BASE_SCORE = 100
const MULTIPLIER_INCREMENT = 0.05
const MAX_MULTIPLIER = 1.35
const MULTIPLIER_RESET_TIME = 3.0

var current_score: int = 0
var score_multiplier: float = 1.0
var last_kill_time: float = 0.0
var weapon_level: int = 1
var max_weapon_level: int = 2

func _process(delta: float):
    # Reset multiplier if too much time has passed since last kill
    if Time.get_ticks_msec() / 1000.0 - last_kill_time > MULTIPLIER_RESET_TIME:
        score_multiplier = 1.0

func add_score(base_points: int):
    var points = base_points * score_multiplier
    current_score += points
    score_updated.emit(current_score, score_multiplier)

func enemy_killed():
    last_kill_time = Time.get_ticks_msec() / 1000.0
    score_multiplier = min(score_multiplier + MULTIPLIER_INCREMENT, MAX_MULTIPLIER)
    add_score(BASE_SCORE)

func upgrade_weapon() -> bool:
    if weapon_level < max_weapon_level:
        weapon_level += 1
        return true
    return false

func get_current_damage() -> float:
    return 10.0 * weapon_level  # Base damage * weapon level 