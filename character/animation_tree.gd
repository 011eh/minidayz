extends AnimationTree


const  params_dict := {
	'Idle': 'parameters/Idle/%d/blend_position',
	'Run': 'parameters/Run/WeaponState/%d/blend_position',
	'MeleeAttack': 'parameters/MeleeAttack/%d/blend_position',
	'Aim': 'parameters/Aim/%d/blend_position'
}


func _process(delta) -> void:
	pass

func change_state_blend(state_name: String, weapon_state: int, blend_value: Vector2) -> void:
	set(params_dict.get(state_name) % weapon_state, blend_value)

