extends 'ranged_weapon.gd'

class_name Pistol


const PISTOL_VFRAMES = 7
const PISTOL_INIT_FRAME = 24
const RES_TABLE = {
	190: preload('res://item/res/ranged_weapon/amphibia.tres'),
	191: preload('res://item/res/ranged_weapon/kolt_1911.tres'),
	192: preload('res://item/res/ranged_weapon/fnx-45.tres'),
	193: preload('res://item/res/ranged_weapon/glock.tres'),
	194: preload('res://item/res/ranged_weapon/mac-10.tres'),
	195: preload('res://item/res/ranged_weapon/magnum.tres'),
	196: preload('res://item/res/ranged_weapon/pb.tres'),
	197: preload('res://item/res/ranged_weapon/pm.tres'),
	198: preload('res://item/res/ranged_weapon/rare_kolt_1911.tres'),
	199: preload('res://item/res/ranged_weapon/sawed_izh-43.tres'),
	200: preload('res://item/res/ranged_weapon/sawed_repeater.tres'),
	201: preload('res://item/res/ranged_weapon/sawed_mosin.tres'),
}

func _ready():
	super._ready()
	vframes = PISTOL_VFRAMES
	frame = PISTOL_INIT_FRAME

static func get_item_resource(id: int) -> RangedWeaponResource:
	assert_id_exists(id, RES_TABLE)
	return RES_TABLE.get(id)
