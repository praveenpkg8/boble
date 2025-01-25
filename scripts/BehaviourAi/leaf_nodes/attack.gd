extends BehavourLeafNode

func tick(black_board: BlackBoard, result: BehaviourTreeResult):
	print("attacking")
	black_board.data["is_attacking"] = true
	result.set_succcess()
	
