extends Area2D

class_name InteractionArea


signal interaction_inputted


func _ready():
	area_entered.connect(func(area):
		print('enter')
	)
	area_exited.connect(func(area):
		print('exit')
	)
	interaction_inputted.connect(func():
		print('interact')
		queue_free()
	)
