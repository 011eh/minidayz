extends Node

class_name StateMachine

var current_state: State

func set_state(state_name: String) -> void:
	assert(has_node(state_name),'状态机没有 %s 状态！' % state_name)
	current_state = get_node(state_name)
	current_state.start()

func setup(state_owner) -> void:
	for state in get_children():
		state.state_owner = state_owner
		state.state_machine = self

func run() -> void:
	if current_state.has_method('run'):
		current_state.run()
