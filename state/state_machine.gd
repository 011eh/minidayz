extends Node

class_name StateMachine

func get_state(state_name: String):
	if has_node(state_name):
		return get_node(state_name)
	else:
		printerr("No state ", state_name, " in state machine !")


func setup(state_owner) -> void:
	for state in get_children():
		state.state_owner = state_owner
