extends BehavourLeafNode


func tick(black_board: BlackBoard, result: BehaviourTreeResult):
	var is_player_near_by: bool = black_board.data.get("is_player_near_by")
	if is_player_near_by:
		print("sensing")
		
		result.set_succcess()
		return
	result.set_failure()
	
