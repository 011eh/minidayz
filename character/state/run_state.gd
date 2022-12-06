extends State


func start() -> void:
	state_owner.playback.travel('Run')

func run() -> void:
	state_owner.set_direction()
	if state_machine.state_data.get('weapon_state') == state_owner.MELEE and \
	Input.is_action_pressed("attack"):
		state_machine.set_state('MeleeAttack')
	if state_owner.is_moving():
		var param := 'parameters/Run/%d/blend_position' % state_machine.state_data.get('weapon_state') as String
		state_owner.animation_tree.set(param, state_owner.velocity)
	else:
		state_machine.set_state('Idle')
