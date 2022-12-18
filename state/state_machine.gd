extends Node


class_name StateMachine


signal state

var current_state: State
var state_data := {'weapon_state': 0}


func set_state(state_name: String) -> void:
	assert(has_node(state_name), '状态机没有 %s 状态！' % state_name)
	var state = get_node(state_name)
	if current_state != state:
		state.start()
		current_state = state

func setup(owner) -> void:
	for state in get_children():
		state.finished.connect(set_state)
		
		state.state_machine = self

func run() -> void:
	current_state.run()
