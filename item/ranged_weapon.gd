extends 'durability_item.gd'

class_name RangedWeapon


var spread: int
var bullet_number := 0


func _ready():
	hframes = SPRITE_HFRAMES
	texture = resource.texture

func is_equipment() -> bool:
	return true
