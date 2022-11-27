extends State


func start() -> void:
	state_owner.set_blend_position('parameters/Idle/blend_position', state_owner.last_direction)
	state_owner.play_animation('Idle')

func run() -> void:
	if state_owner.is_moving():
		state_owner.set_state("Run")
