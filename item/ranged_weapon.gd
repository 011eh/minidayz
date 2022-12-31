extends Weapon

class_name RangedWeapon


const RANGE_WEAPON_VFRAMES = 16
const RANGED_WEAPON_RES_TABLE := {
	0: preload('res://item/res/ranged_weapon/ak74_rifle.tres'),
}


var spread: int
var bullet_number := 0


func _ready():
	hframes = SPRITE_HFRAMES
	vframes = RANGE_WEAPON_VFRAMES
	frame = WEAPON_INIT_FRAME
	texture = resource.texture

static func create_item(id: int) -> Weapon:
	var weapon := RangedWeapon.new()
	weapon.resource = RANGED_WEAPON_RES_TABLE.get(id)
	return weapon
