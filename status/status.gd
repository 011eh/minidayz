class_name Status


signal died


var max_health: float
var health: float: 
	set(value):
		health = clamp(value, 0, max_health)
		if health < 0:
			died.emit()

var max_speed: int
var speed: int:
	set(value):
		speed = clamp(value, 0, max_speed)


func _init(max_health: float, max_speed: int):
	self.max_health = max_health
	self.max_speed = max_speed
	health = max_health
	speed = max_speed


class PlayerStatus extends Status:
	
	
	var max_hunger: float
	var hunger: float:
		set(value):
			hunger = clamp(value, 0, max_hunger)
	
	var max_thirst: float
	var thirst: float:
		set(value):
			thirst = clamp(value, 0, max_thirst)
	
	var hunger_decrease_per_second: float
	var thirst_decrease_per_second: float
	
	
	func _init(max_health: float, max_speed: int, max_hunger: float, max_thirst) -> void:
		super._init(max_health, max_speed)
		self.max_hunger = max_hunger
		self.max_thirst = max_thirst
		hunger = max_hunger
		thirst = max_thirst 
