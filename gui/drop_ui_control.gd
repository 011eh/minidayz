extends Control


@export_enum('Equip', 'Drop')
var control_type: String

func _get_drag_data(at_position):
	print('d')

func _can_drop_data(at_position, data):
	return true

func _drop_data(at_position, data):
	if control_type == 'Equip':
		print('e')
	else:
		print('d')
