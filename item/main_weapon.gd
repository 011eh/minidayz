extends 'ranged_weapon.gd'

class_name MainWeapon


const MAIN_WEAPON_VFRAMES = 16
const RES_TABLE = {
	165: preload('res://item/res/ranged_weapon/improvised_bow.tres'),
	166: preload('res://item/res/ranged_weapon/crossbow.tres'),
	167: preload('res://item/res/ranged_weapon/ak-74.tres'),
	168: preload('res://item/res/ranged_weapon/akm.tres'),
	169: preload('res://item/res/ranged_weapon/aks74u.tres'),
	170: preload('res://item/res/ranged_weapon/aug.tres'),
	171: preload('res://item/res/ranged_weapon/bizon.tres'),
	172: preload('res://item/res/ranged_weapon/izh-43.tres'),
	173: preload('res://item/res/ranged_weapon/fn_cal.tres'),
	174: preload('res://item/res/ranged_weapon/groza.tres'),
	175: preload('res://item/res/ranged_weapon/l85.tres'),
	176: preload('res://item/res/ranged_weapon/m4_carbine.tres'),
	177: preload('res://item/res/ranged_weapon/madsen.tres'),
	178: preload('res://item/res/ranged_weapon/mosin.tres'),
	179: preload('res://item/res/ranged_weapon/mp5k.tres'),
	180: preload('res://item/res/ranged_weapon/remington_870.tres'),
	181: preload('res://item/res/ranged_weapon/repeater.tres'),
	182: preload('res://item/res/ranged_weapon/rpk.tres'),
	183: preload('res://item/res/ranged_weapon/saiga-12.tres'),
	184: preload('res://item/res/ranged_weapon/sks.tres'),
	185: preload('res://item/res/ranged_weapon/sporter_22.tres'),
	186: preload('res://item/res/ranged_weapon/sv-98.tres'),
	187: preload('res://item/res/ranged_weapon/svd.tres'),
	188: preload('res://item/res/ranged_weapon/ump-45.tres'),
	189: preload('res://item/res/ranged_weapon/vss.tres'),
}


func _ready():
	super._ready()
	vframes = MAIN_WEAPON_VFRAMES
	frame = SPRITE_INIT_FRAME

static func get_item_resource(id: int) -> RangedWeaponResource:
	assert_id_exists(id, RES_TABLE)
	return RES_TABLE.get(id)
