extends Node

class_name CharacterStatus


signal died


@export
var speed: int
@export
var max_health := 100
var health: float: 
	set(value):
		health = clamp(value, 0, max_health)
		if health == 0:
			died.emit()

func _ready():
	health = max_health
