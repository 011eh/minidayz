extends State

func start() -> void:
	state_owner.animation_tree.set('parameters/Aim/0/blend_position', \
state_owner.direction_to_mouse())
	state_owner.playback.start('Aim')

func run() -> void:
	if state_owner.is_moving():
		state_machine.set_state('Run')	
	elif Input.is_action_pressed('aim'):
		state_owner.animation_tree.set('parameters/Aim/0/blend_position', \
state_owner.direction_to_mouse())	
	else:
		state_machine.set_state('Idle')
