extends State


func start() -> void:
	var param := 'parameters/Idle/%d/blend_position' % state_machine.state_data.get('weapon_state') as String
	state_owner.animation_tree.set(param, state_machine.state_data.get('idle_direction'))
	state_owner.playback.start('Idle')

func run() -> void:
	state_owner.set_direction()
	if state_owner.is_moving():
		state_machine.set_state('Run')
	
	if state_machine.state_data.get('weapon_state') == state_owner.MELEE and \
	Input.is_action_pressed("attack"):
		var direction := state_owner.direction_to_mouse()
		state_machine.state_data.merge({'attack_direction': direction,
		'idle_direction': direction}, true)
		state_machine.set_state('MeleeAttack')
	elif state_machine.state_data.get('weapon_state') != state_owner.MELEE and Input.is_action_pressed('aim'):
		var direction := state_owner.direction_to_mouse()
		state_machine.state_data.merge({'aim_direction': direction,
		'idle_direction': direction}, true)
		state_machine.set_state('Aim')
