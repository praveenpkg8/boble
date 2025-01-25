extends BehavourLeafNode

func tick(black_board: BlackBoard, result: BehaviourTreeResult) -> void:
	var is_attacking = black_board.data.get("is_attacking")
	if is_attacking:
		result.set_failure()
		return
	result.set_succcess()
	print("patrol")
