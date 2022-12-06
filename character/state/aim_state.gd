extends State


func start() -> void:
	var param := 'parameters/Aim/%d/blend_position' % state_machine.state_data.get('weapon_state') as String
	state_owner.animation_tree.set(param, state_owner.direction_to_mouse())
	state_owner.playback.start('Aim')

func run() -> void:
	if state_owner.is_moving():
		state_machine.set_state('Run')
	elif Input.is_action_pressed('aim'):
		var param := 'parameters/Aim/%d/blend_position' % state_machine.state_data.get('weapon_state') as String
		state_owner.animation_tree.set(param, state_owner.direction_to_mouse())
	else:
		state_machine.set_state('Idle')
