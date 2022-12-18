extends State


func start() -> void:
	var param := 'parameters/Aim/%d/blend_position' % state_machine.state_data.get('weapon_state') as String
	owner.animation_tree.set(param, owner.direction_to_mouse())
	owner.playback.start('Aim')

func run() -> void:
	if owner.is_moving():
		emit_signal('finished','Run')
	elif Input.is_action_pressed('aim'):
		var param := 'parameters/Aim/%d/blend_position' % state_machine.state_data.get('weapon_state') as String
		owner.animation_tree.set(param, owner.direction_to_mouse())
	else:
		emit_signal('finished','Idle')
