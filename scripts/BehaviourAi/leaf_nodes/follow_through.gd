extends BehavourLeafNode

func tick(black_board: BlackBoard, result: BehaviourTreeResult):
	var player_in_follow_throught = black_board.data.get("is_in_follow_thorugh_range")
	if !player_in_follow_throught:
		result.set_failure()
		return
	result.set_succcess()
	print("follow_through")
	return
