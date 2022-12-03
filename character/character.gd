extends CharacterBody2D


const SPEED = 130


@onready
var state_machine := $StateMachine
@onready
var animation_tree := $AnimationTree
@onready
var playback := animation_tree.get('parameters/playback') as AnimationNodeStateMachinePlayback
var current_state: State
var last_direction := Vector2.ZERO


func _ready() -> void:
	state_machine.setup(self)
	state_machine.set_state('Idle')

func _physics_process(delta) -> void:
	state_machine.run()
	var direction = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	if direction:
		last_direction = direction
		velocity = velocity.move_toward(direction * SPEED,SPEED / 15)
	else:
		velocity = velocity.move_toward(Vector2.ZERO,SPEED / 15)
	move_and_slide()

func play_animation(animation :String) -> void:
	playback.travel(animation)

func set_blend_position(param: String, value: Vector2) -> void:
	animation_tree.set(param,value)

func is_moving() -> bool:
	return velocity != Vector2.ZERO

func direction_to_mouse() -> Vector2:
	return position.direction_to(get_local_mouse_position())
