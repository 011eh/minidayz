extends CharacterBody2D

class_name Character


const SPEED := 130


@onready
var state_machine := $StateMachine as StateMachine
@onready
var animation_tree := $AnimationTree as AnimationTree
@onready
var playback := animation_tree.get('parameters/playback') as AnimationNodeStateMachinePlayback
var current_state: State
var last_direction := Vector2.ZERO
var direction: Vector2
var weapon_state: int


func _ready() -> void:
	state_machine.set_state('Idle')

func _physics_process(delta) -> void:
	state_machine.run()
	if direction:
		last_direction = direction
		velocity = velocity.move_toward(direction * SPEED, SPEED * 5 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * 4 * delta)
	move_and_slide()

func get_input_diretion() -> void:
	direction = Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')

func is_moving() -> bool:
	return velocity != Vector2.ZERO

func direction_to_mouse() -> Vector2:
	last_direction = position.direction_to(get_global_mouse_position())
	return last_direction
