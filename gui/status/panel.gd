extends TextureRect


var alert_icon: TextureRect


func _ready():
	if has_node('AlertIcon'):
		alert_icon = $AlertIcon
		alert_icon.visible = false

func set_value(value: float) -> void:
	%Bar.value = value
	if is_instance_valid(alert_icon):
		if value == 0:
			alert_icon.show()
		if value != 0:
			alert_icon.hide()
