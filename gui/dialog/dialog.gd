extends NinePatchRect

class_name Dialog


func set_button_action(action: Callable) -> void:
	%Button.pressed.connect(action)
