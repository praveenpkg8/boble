extends Node2D

func _on_button_2_pressed() -> void:
	get_tree().quit()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")
	pass # Replace with function body.
