extends State


func start() -> void:
	if not owner.is_moving():
		owner.animation_tree.set('parameters/MeleeAttack/blend_position', owner.last_direction)
		owner.playback.start('MeleeAttack')

func run() -> void:
	owner.get_input_diretion()
	if owner.is_moving():
		emit_signal('finished', 'Run')

func end() -> void:
	if owner.is_moving():
		emit_signal('finished', 'Run')
	else:
		emit_signal('finished', 'Idle')
