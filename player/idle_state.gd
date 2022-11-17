extends State


func start() -> void:
	state_owner.animationTree.set('parameters/Idle/blend_position', state_owner.last_direction)
	state_owner.playback.travel('Idle')

func run() -> void:
	if state_owner.is_moving():
		state_owner.set_state("Run")
