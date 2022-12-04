extends State


func start() -> void:
	state_owner.animation_tree.set('parameters/Idle/2/blend_position', \
state_owner.last_direction)
	state_owner.playback.start('Idle')

func run() -> void:
	state_owner.get_direction()
	if state_owner.is_moving():
		state_machine.set_state('Run')
	if Input.is_action_pressed("attack"):
		state_machine.set_state('MeleeAttack')
