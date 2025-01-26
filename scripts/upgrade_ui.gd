extends Control

signal upgrade_selected(upgrade: Dictionary)
signal upgrade_skipped

@onready var panel = $CenterContainer/Panel
@onready var timer_label = $CenterContainer/Panel/VBoxContainer/Timer
@onready var multiplier_info = $CenterContainer/Panel/VBoxContainer/MultiplierInfo
@onready var upgrade_container = $CenterContainer/Panel/VBoxContainer/UpgradeContainer
@onready var skip_button = $CenterContainer/Panel/VBoxContainer/SkipButton

var current_options: Array
var time_remaining: float
var combat_manager: CombatManager

func _ready():
	skip_button.pressed.connect(_on_skip_pressed)
	combat_manager = get_node("/root/GameWorld/CombatManager")
	hide()
	panel.scale = Vector2.ZERO

func _process(delta):
	if visible:
		time_remaining -= delta
		timer_label.text = "Time: %0.1f" % max(0, time_remaining)
		
		if time_remaining <= 0:
			_on_skip_pressed()

func show_upgrades(options: Array):
	current_options = options
	time_remaining = 3.0
	
	# Update multiplier info
	if combat_manager:
		multiplier_info.text = "Current Score Multiplier: x%.2f" % combat_manager.score_multiplier
	
	# Clear existing upgrade buttons
	for child in upgrade_container.get_children():
		child.queue_free()
	
	# Create new upgrade buttons with hover effects
	for upgrade in options:
		var button = create_upgrade_button(upgrade)
		upgrade_container.add_child(button)
	
	show()
	get_tree().paused = true
	
	# Animate panel appearance
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)

func create_upgrade_button(upgrade: Dictionary) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 60)
	
	var cost_color = Color.GREEN if combat_manager.current_score >= upgrade.cost else Color.RED
	
	button.text = "[center]%s\n[color=%s]Cost: %d[/color]\n%s[/center]" % [
		upgrade.name,
		cost_color.to_html(),
		upgrade.cost,
		upgrade.description
	]
	
	button.pressed.connect(func(): _on_upgrade_button_pressed(upgrade))
	return button

func _on_button_hover(button: Button, is_hover: bool):
	var tween = create_tween()
	if is_hover:
		tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	else:
		tween.tween_property(button, "modulate", Color.WHITE, 0.1)

func _on_upgrade_button_pressed(upgrade: Dictionary):
	if combat_manager.current_score >= upgrade.cost:
		upgrade_selected.emit(upgrade)
		hide()
		if get_tree():
			get_tree().paused = false

func _on_skip_pressed():
	upgrade_skipped.emit()
	hide()
	if get_tree():
		get_tree().paused = false
