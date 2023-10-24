extends Area2D

class_name InteractionArea


signal interact_inputted


func _ready():
	body_entered.connect(func(body) -> void:
		print('p')
	)
	body_exited.connect(func(body) -> void:
		InteractionManager
	)
