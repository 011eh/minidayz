extends State


func start() -> void:
	var param := 'parameters/Idle/%d/blend_position' % owner.weapon_state as String
	owner.animation_tree.set(param, owner.last_direction)
	owner.playback.start('Idle')

func run() -> void:
	owner.get_input_diretion()
	if owner.is_moving():
		emit_signal('finished','Run')
	if owner.weapon_state == StateMachine.MELEE and Input.is_action_pressed("attack"):
		owner.direction_to_mouse()
		emit_signal('finished','MeleeAttack')
		return
	if owner.weapon_state != StateMachine.MELEE and Input.is_action_pressed('aim'):
		emit_signal('finished','Aim')
