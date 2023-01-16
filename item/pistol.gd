extends 'ranged_weapon.gd'

class_name Pistol


const PISTOL_VFRAMES = 7
const PISTOL_INIT_FRAME = 24
const RES_TABLE = {
	25: preload('res://item/res/ranged_weapon/amphibia.tres'),
	26: preload('res://item/res/ranged_weapon/kolt_1911.tres'),
	27: preload('res://item/res/ranged_weapon/fnx-45.tres'),
	28: preload('res://item/res/ranged_weapon/glock.tres'),
	29: preload('res://item/res/ranged_weapon/mac-10.tres'),
	30: preload('res://item/res/ranged_weapon/magnum_.tres'),
	31: preload('res://item/res/ranged_weapon/pb.tres'),
	32: preload('res://item/res/ranged_weapon/pm.tres'),
	33: preload('res://item/res/ranged_weapon/rare_kolt_1911.tres'),
	34: preload('res://item/res/ranged_weapon/sawed_izh-43.tres'),
	35: preload('res://item/res/ranged_weapon/sawed_repeater.tres'),
	36: preload('res://item/res/ranged_weapon/sawed_mosin.tres'),
}

func _ready():
	super._ready()
	vframes = PISTOL_VFRAMES
	frame = PISTOL_INIT_FRAME

static func get_item_resource(id: int) -> RangedWeaponResource:
	assert_id_exists(id, RES_TABLE)
	return RES_TABLE.get(id)
