extends State


func start() -> void:
	owner.playback.start('Aim')

func run() -> void:
	owner.get_input_direction()
	if owner.is_moving():
		emit_signal('finished','Run')
		return
	if Input.is_action_pressed('aim'):
		var param := 'parameters/Aim/%d/blend_position' % owner.weapon_state as String
		owner.animation_tree.set(param, owner.direction_to_mouse())
	else:
		emit_signal('finished','Idle')
