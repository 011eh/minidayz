extends Control

class_name Dialog

@onready
var dialog_rect := Rect2(%Background.get_rect())

func set_button_action(action: Callable) -> void:
	%Button.pressed.connect(action)


func _gui_input(event):
	if visible and event is InputEventMouseButton and not dialog_rect.has_point(event.position):
		print(event.position)
		print(dialog_rect)
		visible = false
