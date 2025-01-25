class_name UIManager
extends CanvasLayer

@onready var wave_label = $WaveInfo/WaveLabel
@onready var enemy_count = $WaveInfo/EnemyCount
@onready var score_label = $ScoreInfo/ScoreLabel
@onready var multiplier_label = $ScoreInfo/MultiplierLabel
@onready var resource_count = $ResourceInfo/ResourceCount
@onready var ability1_cooldown = $AbilityInfo/Ability1/Cooldown
@onready var ability2_cooldown = $AbilityInfo/Ability2/Cooldown
@onready var game_over_panel = $GameOverPanel
@onready var victory_panel = $VictoryPanel
@onready var wave_timer_label = $WaveInfo/WaveTimer

var combat_manager: CombatManager
var wave_manager: WaveManager
var player: Node2D
var game_over: bool = false

func _ready():
	print("UI Manager ready - Setting up buttons")
	
	combat_manager = get_node("../CombatManager")
	wave_manager = get_node("../WaveManager")
	player = get_node("../Player")
	
	# Connect signals
	combat_manager.score_updated.connect(_on_score_updated)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_victory)
	
	# Hide panels
	game_over_panel.hide()
	victory_panel.hide()
	
	# Get buttons
	var restart_button = $GameOverPanel/VBoxContainer/RestartButton
	print("Setting up restart button")
	
	if restart_button:
		# Make sure button can process while paused
		restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Disconnect any existing connections first
		if restart_button.is_connected("pressed", _on_restart_pressed):
			print("Removing existing restart button connection")
			restart_button.disconnect("pressed", _on_restart_pressed)
		
		# Connect the signal
		restart_button.pressed.connect(_on_restart_pressed)
		print("Restart button connected")
	
	# Set UI to process while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	if game_over:
		return
		
	# Update ability cooldowns
	if is_instance_valid(player):
		ability1_cooldown.value = (player.special_ability_1_cooldown - player.ability_1_timer) / player.special_ability_1_cooldown * 100
		ability2_cooldown.value = (player.special_ability_2_cooldown - player.ability_2_timer) / player.special_ability_2_cooldown * 100
		resource_count.text = "Resources: %d/%d" % [player.resources, player.max_resources]
	else:
		# Player was destroyed - game over
		_on_game_over()
		return
	
	# Update enemy count if wave is active
	if is_instance_valid(wave_manager):
		enemy_count.text = "Enemies: %d" % wave_manager.enemies_remaining
	
	# Update wave timer if wave is active
	if is_instance_valid(wave_manager) and wave_manager.is_wave_active:
		var time_remaining = wave_manager.WAVE_TIME_LIMIT - wave_manager.wave_timer
		var minutes = floor(time_remaining / 60)
		var seconds = floor(fmod(time_remaining, 60))
		wave_timer_label.text = "Time: %02d:%02d" % [minutes, seconds]
	else:
		wave_timer_label.text = "Time: --:--"

func _on_score_updated(score: int, multiplier: float):
	score_label.text = "Score: %d" % score
	multiplier_label.text = "x%.2f" % multiplier

func _on_wave_started(wave_number: int, enemy_count: int):
	wave_label.text = "Wave %d/%d" % [wave_number, wave_manager.WAVE_COUNTS.size()]
	self.enemy_count.text = "Enemies: %d" % enemy_count

func _on_wave_completed(_wave_number: int):
	pass  # Could add wave completion animation here

func _on_victory():
	if not game_over:
		game_over = true
		victory_panel.show()

func _on_game_over():
	print("Game over triggered")
	if not game_over:
		game_over = true
		game_over_panel.show()
		print("Game over panel shown")
		
		# Make sure the panel and its children are visible and process while paused
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		for child in game_over_panel.get_children():
			child.process_mode = Node.PROCESS_MODE_ALWAYS
		
		get_tree().paused = true
		
		var game_over_label = $GameOverPanel/VBoxContainer/Label
		game_over_label.text = "Game Over\nAll Towers Destroyed!"

func _on_restart_pressed():
	print("Restart button pressed!")
	get_tree().paused = false
	# Use call_deferred to ensure scene switch happens safely
	call_deferred("_do_restart")

func _do_restart():
	print("Executing restart...")
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _on_quit_pressed():
	get_tree().quit() 
