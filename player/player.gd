extends CharacterBody2D


const SPEED = 130

@onready
var state_machine := $StateMachine

@onready
var animationTree := $AnimationTree

@onready
var playback := animationTree.get("parameters/playback") as AnimationNodeStateMachinePlayback
var current_state: State
var last_direction := Vector2.ZERO

func _ready():
	state_machine.setup(self)
	set_state('Idle')

func _physics_process(delta):
	if current_state.has_method("run"):
		current_state.run()
	var direction = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	if direction:
		last_direction = direction
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO,SPEED)
	move_and_slide()

func set_state(state: String):
	current_state = state_machine.get_state(state)
	current_state.start()

func is_moving() -> bool:
	return velocity != Vector2.ZERO
