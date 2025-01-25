extends BehavourLeafNode

func _get_childern():
	var children = get_children()
	return children


func tick(black_board: BlackBoard, result: BehaviourTreeResult):
	var children = _get_childern()
	for child in children:
		child.tick(black_board, result)

		if !result.is_succeeded():
			break
