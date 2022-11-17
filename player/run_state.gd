extends State


func start() -> void:
	state_owner.playback.travel('Run')

func run() -> void:
	if state_owner.is_moving():
		state_owner.animationTree.set('parameters/Run/blend_position', state_owner.velocity)
	else:
		state_owner.set_state('Idle')
