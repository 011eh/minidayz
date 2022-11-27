extends Node

class_name StateMachine


func get_state(state_name: String) -> State:
	assert(has_node(state_name),'状态机没有 %s 状态！')
	return get_node(state_name)

func setup(state_owner) -> void:
	for state in get_children():
		state.state_owner = state_owner
