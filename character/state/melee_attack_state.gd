extends State

@onready
var timer := $Timer

func _ready():
	timer.timeout.connect(Callable(self,'end'))

func start() -> void:
	if not timer.is_stopped():
		return
	timer.start()
	if not state_owner.is_moving():
		state_owner.animation_tree.set('parameters/MeleeAttack/blend_position', \
state_machine.state_data.get('attack_direction'))
		state_owner.playback.start('MeleeAttack')

func run() -> void:
	if state_owner.is_moving():
		state_machine.set_state('Run')

func end() -> void:
	if state_owner.is_moving():
		state_machine.set_state('Run')
	else:
		state_machine.set_state('Idle')
