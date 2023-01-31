extends Node

class_name PlayerStateMachine


const states := ['Idle', 'Run', 'MeleeAttack', 'Aim']


enum WeaponState {
	MAIN_WEAPON, PISTOL, MELEE_WEAPON
}


@onready
var weapon_switch_timer := $WeaponSwitchTimer
@onready
var attack_timer := $AttackTimer
var current_state: State
var inventory: Array[Item]


func _ready() -> void:
	setup()
	attack_timer.timeout.connect($MeleeAttack.end)

func setup() -> void:
	inventory = owner.get_inventory()
	
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
	if is_instance_valid(inventory[PlayerInventory.MAIN_WEAPON])\
		and Input.is_action_just_pressed('with_rifle'):
		switch_weapon(WeaponState.MAIN_WEAPON)
	elif is_instance_valid(inventory[PlayerInventory.PISTOL])\
		and Input.is_action_just_pressed('with_pistol'):
		switch_weapon(WeaponState.PISTOL)
	elif Input.is_action_just_pressed('with_melee'):
		switch_weapon(WeaponState.MELEE_WEAPON)

func switch_weapon(weapon: int) -> void:
	if weapon_switch_timer.is_stopped():
		weapon_switch_timer.start()
		owner.weapon_state = weapon
		owner.animation_tree.set('parameters/Idle/blend_position', weapon)
		owner.animation_tree.set('parameters/Run/WeaponState/blend_position', weapon)
		owner.animation_tree.set('parameters/Idle/%d/blend_position' % weapon, owner.last_direction)
		if weapon != WeaponState.MELEE_WEAPON:
			owner.animation_tree.set('parameters/Aim/blend_position', weapon)
		if owner.is_moving():
			owner.animation_tree.set('parameters/Run/Seek/seek_position', owner.playback.get_current_play_position())
