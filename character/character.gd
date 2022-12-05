extends CharacterBody2D

class_name Character

const SPEED = 130

@onready
var state_machine := $StateMachine as StateMachine
@onready
var animation_tree := $AnimationTree as AnimationTree
@onready
var playback := animation_tree.get('parameters/playback') as AnimationNodeStateMachinePlayback
var current_state: State
var last_direction := Vector2.ZERO
var direction: Vector2


func _ready() -> void:
	state_machine.setup(self)
	state_machine.set_state('Idle')

func _physics_process(delta) -> void:
	state_machine.run()
	if direction:
		state_machine.state_data.merge({'idle_direction' : direction}, true)
		last_direction = direction
		velocity = velocity.move_toward(direction * SPEED, SPEED / 10)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED / 10)
	move_and_slide()

func set_direction() -> void:
	direction = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')

func is_moving() -> bool:
	return velocity != Vector2.ZERO

func direction_to_mouse() -> Vector2:
	return position.direction_to(get_global_mouse_position())
