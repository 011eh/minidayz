extends Node2D

var o:=[]

func _ready():
	pass

func _unhandled_input(event):
	if event.is_action_pressed('move_left'):
		for i in range(100):
			o.append(Label.new())
	if event.is_action_pressed('move_right'):
		for i in o:
			i.queue_free()
