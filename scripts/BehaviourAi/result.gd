class_name BehaviourTreeResult
extends Node

enum Result {
	SUCCESS,
	FAILURE,
	RUNNING
}
var result: int = Result.FAILURE
var running_node: Node

func set_succcess() -> void: 
	result = Result.SUCCESS
	running_node = null

func set_failure() -> void:
	result = Result.FAILURE
	
func set_running(n: Node) -> void:
	result = Result.RUNNING
	running_node = n
	
func is_succeeded() -> bool:
	return result == Result.SUCCESS


func is_failed() -> bool:
	return result == Result.FAILURE


func is_running() -> bool:
	return result == Result.RUNNING
