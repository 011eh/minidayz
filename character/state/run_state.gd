extends State

func start() -> void:
	state_owner.playback.start('Run')

func run() -> void:
	state_owner.get_direction()
	if Input.is_action_pressed("attack"):
		state_machine.set_state('MeleeAttack')
	if state_owner.is_moving():
		state_owner.animation_tree.set('parameters/Run/2/blend_position', \
state_owner.velocity)
	else:
		state_machine.set_state('Idle')
