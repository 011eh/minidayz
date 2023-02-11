extends DurabilityItem

class_name RangedWeapon


var spread: int
var bullet: NumberItem


func _ready():
	hframes = SPRITE_HFRAMES
	texture = resource.texture

func is_equipment() -> bool:
	return true

func get_bullet_number() -> int:
	return bullet.number if is_instance_valid(bullet) else 0
