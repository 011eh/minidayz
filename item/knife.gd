extends 'durability_item.gd'

class_name Knife


const RES_TABLE := {
	11: preload('res://item/res/melee_weapon/army_knife.tres'),
	12: preload('res://item/res/melee_weapon/butcher_knife.tres'),
	13: preload('res://item/res/melee_weapon/hunter_knife.tres'),
}


func _ready():
	hframes = SPRITE_HFRAMES
	vframes = MELEE_WEAPON_VFRAMES
	frame = SPRITE_INIT_FRAME
	texture = resource.texture

static func create_item(id: int) -> Knife:
	assert_id_exists(id, RES_TABLE)
	var weapon := Knife.new()
	weapon.resource = RES_TABLE.get(id) as MeleeWeaponResource
	return weapon