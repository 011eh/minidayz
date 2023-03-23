extends DurabilityItem

class_name Knife


const RES_TABLE = {
	162: preload('res://item/res/melee_weapon/army_knife.tres'),
	163: preload('res://item/res/melee_weapon/butcher_knife.tres'),
	164: preload('res://item/res/melee_weapon/hunter_knife.tres'),
}


func _ready():
	hframes = SPRITE_HFRAMES
	vframes = MELEE_WEAPON_VFRAMES
	frame = SPRITE_INIT_FRAME
	texture = resource.texture

static func get_item_resource(id: int) -> MeleeWeaponResource:
	assert_id_exists(id, RES_TABLE)
	return RES_TABLE.get(id)
