extends Node

class_name StateMachine

var current_state: State

var state_data := {}

func set_state(state_name: String) -> void:
	assert(has_node(state_name), '状态机没有 %s 状态！' % state_name)
	var state = get_node(state_name)
	if current_state != state:
		state.start()
		current_state = state

func setup(state_owner) -> void:
	for state in get_children():
		state.state_owner = state_owner
		state.state_machine = self

func run() -> void:
	current_state.run()
