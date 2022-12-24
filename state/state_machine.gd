extends Node

class_name StateMachine


const RIFLE := 0
const PISTOL := 1
const MELEE := 2
const states := ['Idle', 'Run', 'MeleeAttack', 'Aim']


@onready
var weapon_switch_timer := $WeaponSwitchTimer
@onready
var attack_timer := $AttackTimer
var current_state: State


func _ready() -> void:
	setup()
	attack_timer.timeout.connect($MeleeAttack.end)

func setup() -> void:
	for state_name in states:
		var state := get_node(state_name) as State
		state.finished.connect(set_state)

func set_state(state_name: String) -> void:
	assert(has_node(state_name), '状态机没有 %s 状态！' % state_name)
	
	if state_name == 'MeleeAttack':
		if attack_timer.is_stopped():
			attack_timer.start()
		else:
			return
	var state = get_node(state_name)
	if current_state != state:
		state.start()
		current_state = state

func run() -> void:
	current_state.run()
	if Input.is_action_just_pressed('with_rifle'):
		switch_weapon(RIFLE)
	elif Input.is_action_just_pressed('with_pistol'):
		switch_weapon(PISTOL)
	elif Input.is_action_just_pressed('with_melee'):
		switch_weapon(MELEE)

func switch_weapon(weapon: int) -> void:
	if weapon_switch_timer.is_stopped():
		weapon_switch_timer.start()
		owner.weapon_state = weapon
		owner.animation_tree.set('parameters/Idle/blend_position', weapon)
		owner.animation_tree.set('parameters/Run/WeaponState/blend_position', weapon)
		var param := 'parameters/Idle/%d/blend_position' % weapon as String
		owner.animation_tree.set(param, owner.last_direction)
		if weapon != MELEE:
			owner.animation_tree.set('parameters/Aim/blend_position', weapon)

		if owner.is_moving():
			var pos = owner.playback.get_current_play_position() as float
			owner.animation_tree.set('parameters/Run/Seek/seek_position', pos)
