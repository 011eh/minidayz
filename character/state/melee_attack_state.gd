extends State


func start() -> void:
	state_owner.set_blend_position('parameters/MeleeAttack/blend_position', state_owner.last_direction)

func end() -> void:
	print('attack end')
	
