extends State


func start() -> void:
	owner.playback.travel('Run')

func run() -> void:
	owner.set_direction()
	if state_machine.state_data.get('weapon_state') == owner.MELEE and \
	Input.is_action_pressed("attack"):
		emit_signal('finished','MeleeAttack')
	if owner.is_moving():
		var param := 'parameters/Run/WeaponState/%d/blend_position' % state_machine.state_data.get('weapon_state') as String
		owner.animation_tree.set(param, owner.velocity)
	else:
		emit_signal('finished','Idle')
