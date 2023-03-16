extends TextureRect


@onready
var options_ui := %Options
@onready
var button := %Button


func set_active(ui_id: int, g_position: Vector2,item_name: StringName, options: Array[ItemActionTable.ItemAction]) -> void:
	get_tree().call_group('menu_options', 'free')
	%Label.text = item_name
	for option in options:
		var button := self.button.duplicate()
		button.pressed.connect(option.action)
		button.get_child(0).text = option.name
		button.visible = true
		button.add_to_group('menu_options')
		options_ui.add_child(button)
	visible = true
	global_position = g_position
	set_meta('ui_id', ui_id)
