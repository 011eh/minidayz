extends CharacterBody2D

const SPEED = 130

@onready
var state_machine := $StateMachine

var current_state

func _ready():
	state_machine.setup(self)

func _physics_process(delta):
	var direction = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	if direction:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO,SPEED)
	move_and_slide()

func set_state(state: String):
	state_machine.get_state(state)
