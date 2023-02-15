extends CharacterBody2D

class_name Player


const SPEED := 130


@onready
var state_machine := $StateMachine as PlayerStateMachine
@onready
var animation_tree := $AnimationTree as AnimationTree
@onready
var playback := animation_tree.get('parameters/playback') as AnimationNodeStateMachinePlayback
var current_state: State
var last_direction := Vector2.ZERO
var direction :Vector2
var weapon_state := PlayerStateMachine.WeaponState.MELEE_WEAPON
var target_position: Vector2


func _ready() -> void:
	state_machine.set_state('Idle')
	$Inventory.equipment_changed.connect($Sprites.set_texture)

func _physics_process(delta) -> void:
	state_machine.run()
	if direction == Vector2.ZERO and target_position != Vector2.ZERO:
		direction = position.direction_to(target_position)
	else:
		target_position = Vector2.ZERO
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

func get_inventory() -> Array:
	return $Inventory.equipment_slots
