extends 'durability_item.gd'

class_name Weapon

const WEAPON_VFRAMES = 17
const WEAPON_RES_TABLE :={
}


func _ready():
	hframes = SPRITE_HFRAMES
	vframes = WEAPON_VFRAMES
	frame = SPRITE_INIT_FRAME
	texture = resource.texture

static func create_item(id: int) -> Weapon:
	var weapon := Weapon.new()
	weapon.resource = WEAPON_RES_TABLE.get(id)
	return weapon
