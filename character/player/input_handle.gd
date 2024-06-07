extends Node

class_name InputHandle

var timer := Timer.new()


func _ready():
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)

func _input(event):
	if event.is_action('interact'):
		if not timer.is_stopped():
			get_viewport().set_input_as_handled()
		else:
			timer.start()
