extends Node2D


func _ready():
	if is_instance_valid(owner):
		await owner.ready
	print(name)
func _process(delta):
	pass
