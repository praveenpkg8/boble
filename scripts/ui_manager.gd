class_name UIManager
extends CanvasLayer

@onready var wave_label = $WaveInfo/WaveLabel
@onready var enemy_count = $WaveInfo/EnemyCount
@onready var score_label = $ScoreInfo/ScoreLabel
@onready var multiplier_label = $ScoreInfo/MultiplierInfo/MultiplierLabel
@onready var skip_bonus_label = $ScoreInfo/MultiplierInfo/SkipBonus
@onready var resource_count = $ResourceInfo/ResourceCount
@onready var ability1_cooldown = $AbilityInfo/Ability1/Cooldown
@onready var ability2_cooldown = $AbilityInfo/Ability2/Cooldown
@onready var game_over_panel = $GameOverPanel
@onready var victory_panel = $VictoryPanel
@onready var wave_timer_label = $WaveInfo/WaveTimer

@onready var wave_manager = get_node_or_null("/root/GameWorld/WaveManager")
@onready var upgrade_manager = get_node_or_null("/root/GameWorld/UpgradeManager")

var combat_manager: CombatManager
var player: Node2D
var game_over: bool = false

func _ready():
	print("UI Manager ready - Setting up buttons")
	
	combat_manager = get_node("../CombatManager")
	player = get_node("../Player")
	
	if !player:
		push_error("Player not found!")
		return
	
	# Connect signals
	combat_manager.score_updated.connect(_on_score_updated)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_victory)
	wave_manager.enemy_count_updated.connect(_on_enemy_count_updated)
	
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
	
	# Connect upgrade signals
	var upgrade_ui = get_node_or_null("UpgradeUI")
	if upgrade_ui:
		if upgrade_manager:
			upgrade_manager.upgrade_available.connect(upgrade_ui.show_upgrades)
			upgrade_ui.upgrade_selected.connect(upgrade_manager._on_upgrade_selected)
			upgrade_ui.upgrade_skipped.connect(upgrade_manager._on_upgrade_skipped)
	else:
		push_error("UpgradeUI not found!")

func _process(delta: float) -> void:
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
		enemy_count.text = "Enemies: %d" % max(0, wave_manager.enemies_remaining)
	
	# Update wave timer if wave is active

func _on_score_updated(score: int, multiplier: float):
	score_label.text = "Score: %d" % score
	multiplier_label.text = "x%.2f" % multiplier
	
	# Update skip bonus if any
	var base_multiplier = 1.0
	var skip_bonus = multiplier - base_multiplier
	if skip_bonus > 0:
		skip_bonus_label.text = "(+%.2f)" % skip_bonus
		skip_bonus_label.show()
	else:
		skip_bonus_label.hide()

func _on_wave_started(wave_number: int, enemy_count: int):
	wave_label.text = "Wave %d/%d" % [wave_number, wave_manager.WAVE_COUNTS.size()]
	self.enemy_count.text = "Enemies: %d" % enemy_count
	wave_timer_label.text = "Wave: %d" % wave_number

func _on_wave_completed(wave_number: int):
	var upgrade_ui = get_node_or_null("UpgradeUI")
	if upgrade_ui and upgrade_manager:
		var options = upgrade_manager.generate_upgrade_options()
		upgrade_ui.show_upgrades(options)

func _on_victory():
	if not game_over:
		game_over = true
		victory_panel.show()

func _on_game_over():
	print("Game over triggered")
	if not game_over:
		game_over = true
		# Play sound before pausing
		SoundManager.play_sound("game_over")
		
		game_over_panel.show()
		var game_over_label = $GameOverPanel/VBoxContainer/Label
		game_over_label.text = "Game Over\nAll Towers Destroyed!"
		print("Game over panel shown")
		
		# Make sure the panel and its children are visible and process while paused
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		for child in game_over_panel.get_children():
			child.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Set pause after playing sound
		await get_tree().create_timer(5).timeout  # Small delay to ensure sound starts playing
		get_tree().paused = true
		

func _on_restart_pressed():
	print("Restart button pressed!")
	game_over = false
	
	if wave_manager:
		# Wait for wave manager to clean up before scene change
		wave_manager.cleanup()
		await wave_manager.wave_cleanup_completed
	
	if get_tree():
		get_tree().paused = false
		call_deferred("_do_restart")
	else:
		push_error("Scene tree not available!")

func _do_restart():
	print("Executing restart...")
	if get_tree():
		# Reset any global state here if needed
		get_tree().change_scene_to_file.call_deferred("res://scenes/game_world.tscn")
	else:
		push_error("Scene tree not available during restart!")

func _on_quit_pressed():
	print("Quit button pressed!")
	if wave_manager:
		# Clean up wave manager before quitting
		wave_manager.cleanup()
		await wave_manager.wave_cleanup_completed
	
	# Ensure we're unpaused before quitting
	if get_tree():
		get_tree().paused = false
		get_tree().quit()
	else:
		push_error("Scene tree not available!")
		# Force quit if tree is not available
		get_tree().quit(1)

func _on_enemy_count_updated(count: int):
	if enemy_count:  # Add null check
		enemy_count.text = "Enemies: %d" % max(0, count)  # Prevent negative counts

func _on_wave_timeout():
	# Force spawn all remaining enemies
	while wave_manager.enemies_to_spawn > 0:
		wave_manager.spawn_wave_enemies()
		wave_manager.enemies_to_spawn -= 1 
