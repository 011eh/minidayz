extends Control


func _ready():
	pass

func _gui_input(event):
	print(Rect2($Control/ColorRect.get_rect()).has_point(event.position))
