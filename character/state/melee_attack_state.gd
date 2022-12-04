extends State

@onready
var timer := $Timer

func _ready():
	timer.timeout.connect(Callable(self,'end'))

func start() -> void:
	timer.start()
	if not state_owner.is_moving():
		state_owner.animation_tree.set('parameters/MeleeAttack/blend_position', \
state_owner.last_direction)
		state_owner.playback.start('MeleeAttack')

func end() -> void:
	if state_owner.is_moving():
		state_machine.set_state('Run')
	else:
		state_machine.set_state('Idle')
