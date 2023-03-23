extends Control

class_name Dialog


func _ready():
	%Button.pressed.connect(button_action)

func button_action() -> void:
	pass

func _gui_input(event):
	if visible and event is InputEventMouseButton and not %Background.get_rect().has_point(event.position):
		visible = false
