extends State


func start() -> void:
	state_owner.animation_tree.set('parameters/Idle/2/blend_position', \
state_machine.state_data.get('idle_direction'))
	state_owner.playback.start('Idle')

func run() -> void:
	state_owner.set_direction()
	if state_owner.is_moving():
		state_machine.set_state('Run')
	
	if Input.is_action_pressed("attack"):
		var direction := state_owner.direction_to_mouse()
		state_machine.state_data.merge({'attack_direction': direction,
		'idle_direction': direction}, true)
		state_machine.set_state('MeleeAttack')
	elif Input.is_action_pressed('aim'):
		var direction := state_owner.direction_to_mouse()
		state_machine.state_data.merge({'aim_direction': direction,
		'idle_direction': direction}, true)
		state_machine.set_state('Aim')
