extends State


func start() -> void:
	state_owner.play_animation('Run')

func run() -> void:
	if state_owner.is_moving():
		state_owner.set_blend_position('parameters/Run/blend_position', state_owner.velocity)
	else:
		state_owner.set_state('Idle')
