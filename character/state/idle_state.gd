extends State


func start() -> void:
	state_owner.set_blend_position('parameters/Idle/2/blend_position', state_owner.last_direction)
	state_owner.playback.travel('Idle')

func run() -> void:
	if state_owner.is_moving():
		state_machine.set_state('Run')
	if Input.is_action_pressed("attack"):
		state_machine.set_state('meleeAttack')
		
