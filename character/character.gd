extends CharacterBody2D


class_name Character

const SPEED := 130
const RIFLE := 0
const PISTOL := 1
const MELEE := 2


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
	switch_weapon(RIFLE)

func _physics_process(delta) -> void:
	state_machine.run()
	if direction:
		state_machine.state_data.merge({'idle_direction' : direction}, true)
		last_direction = direction
		velocity = velocity.move_toward(direction * SPEED, SPEED / 10)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED / 10)
	move_and_slide()
	
	if Input.is_action_just_pressed('with_rifle'):
		switch_weapon(RIFLE)
	elif Input.is_action_just_pressed('with_pistol'):
		switch_weapon(PISTOL)
	elif Input.is_action_just_pressed('with_melee'):
		switch_weapon(MELEE)

func set_direction() -> void:
	direction = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')

func is_moving() -> bool:
	return velocity != Vector2.ZERO

func direction_to_mouse() -> Vector2:
	return position.direction_to(get_global_mouse_position())

func switch_weapon(weapon: int) -> void:
	state_machine.state_data.merge({'weapon_state': weapon}, true)
	animation_tree.set('parameters/Idle/blend_position', weapon)
	animation_tree.set('parameters/Run/blend_position', weapon)
	var param := 'parameters/Idle/%d/blend_position' % state_machine.state_data.get('weapon_state') as String
	animation_tree.set(param, state_machine.state_data.get('idle_direction'))
	if weapon != MELEE:
		animation_tree.set('parameters/Aim/blend_position', weapon)
