extends State


func start() -> void:
	var param := 'parameters/Idle/%d/blend_position' % state_machine.state_data.get('weapon_state') as String
	owner.animation_tree.set(param, state_machine.state_data.get('idle_direction'))
	owner.playback.start('Idle')

func run() -> void:
	owner.set_direction()
	if owner.is_moving():
		emit_signal('finished','Run')

	if state_machine.state_data.get('weapon_state') == owner.MELEE and \
	Input.is_action_pressed("attack"):
		var direction := owner.direction_to_mouse() as Vector2
		state_machine.state_data.merge({'attack_direction': direction,
		'idle_direction': direction}, true)
		emit_signal('finished','MeleeAttack')
	elif state_machine.state_data.get('weapon_state') != owner.MELEE and Input.is_action_pressed('aim'):
		var direction := owner.direction_to_mouse() as Vector2
		state_machine.state_data.merge({'aim_direction': direction,
		'idle_direction': direction}, true)
		emit_signal('finished','Aim')
