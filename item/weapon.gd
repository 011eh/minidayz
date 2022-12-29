extends 'durability_item.gd'

class_name Weapon

const WEAPON_HFRAMES = 4
const WEAPON_VFRAMES = 17
const WEAPON_INIT_FRAME = 39

const WEAPON_RES_TABLE :={
	0: preload('res://item/res/weapon/axe_red.tres'),
}


func _ready():
	hframes = WEAPON_HFRAMES
	vframes = WEAPON_VFRAMES
	frame = WEAPON_INIT_FRAME
	texture = resource.texture

static func create_item(id: int) -> Weapon:
	var weapon := Weapon.new()
	weapon.resource = WEAPON_RES_TABLE.get(id)
	return weapon
